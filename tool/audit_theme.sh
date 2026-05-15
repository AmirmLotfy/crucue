#!/usr/bin/env bash
# Local theme consistency gate: fails if disallowed patterns appear outside
# the canonical theme definition file.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

THEME_FILE="lib/core/theme.dart"
violations=0

scan() {
  local pattern="$1"
  local message="$2"
  local hits
  hits=$(grep -R --include='*.dart' -n -E "$pattern" lib 2>/dev/null | grep -v "^${THEME_FILE}:" || true)
  if [[ -n "${hits}" ]]; then
    echo "FAIL: ${message}"
    echo "${hits}"
    violations=1
  fi
}

scan 'CrucueTokens\.(textPrimaryLight|textMutedLight|borderLight|surfaceLight)\b' \
  'Use Theme.of(context).colorScheme / hintColor / onSurfaceVariant instead of light-only CrucueTokens in widgets.'

scan 'CrucueTokens\.plan(WhatHappening|WhatToDo|WhatToAvoid|Message|Tasks|Reflect)\b' \
  'Use BuildContext extension context.decor (CrucueDecorColors) for plan section surfaces.'

scan 'CrucueTokens\.(warningSubtle|successSubtle|errorSubtle|infoSubtle)\b' \
  'Use context.decor.* for subtle semantic banner/card fills (theme-aware).'

if [[ "${violations}" -ne 0 ]]; then
  exit 1
fi

echo "OK: theme token audit passed (see docs/theme_system.md)."
