#!/usr/bin/env bash
# CloudFormation テンプレート内の Python Lambda ランタイムを、
# config/python-runtime.env にピン留めしたバージョンへ置換する。
#
# 目的: templates/ を upstream と同一に保ったまま (git では変更しない)、
#       CI/CD 実行時にだけ我々の指定バージョンへ差し替える。
#       → upstream 追従時の merge conflict を避けられる。
#
# 使い方:
#   scripts/apply-python-runtime.sh [template-path]
#   (template-path 省略時は templates/SociIndexBuilder.yml)
#
# 注意: Go ランタイム (provided.al2023) は対象外。
#       "Runtime: python3.x" の行だけを置換する。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ROOT}/config/python-runtime.env"
TEMPLATE="${1:-${ROOT}/templates/SociIndexBuilder.yml}"

if [ ! -f "${ENV_FILE}" ]; then
  echo "::error::バージョンファイルが見つかりません: ${ENV_FILE}" >&2
  exit 1
fi
if [ ! -f "${TEMPLATE}" ]; then
  echo "::error::テンプレートが見つかりません: ${TEMPLATE}" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "${ENV_FILE}"
: "${PYTHON_RUNTIME:?PYTHON_RUNTIME が ${ENV_FILE} に設定されていません}"

if ! printf '%s' "${PYTHON_RUNTIME}" | grep -Eq '^python3\.[0-9]+$'; then
  echo "::error::PYTHON_RUNTIME の形式が不正です: '${PYTHON_RUNTIME}' (例: python3.13)" >&2
  exit 1
fi

# "Runtime: python3.10" のような行だけを置換 (provided.al2023 は無視)
sed -i.bak -E "s/^([[:space:]]*Runtime:[[:space:]]*)python3\.[0-9]+/\1${PYTHON_RUNTIME}/" "${TEMPLATE}"
rm -f "${TEMPLATE}.bak"

echo "Applied ${PYTHON_RUNTIME} to ${TEMPLATE}"
grep -nE '^[[:space:]]*Runtime:[[:space:]]*python' "${TEMPLATE}" || true
