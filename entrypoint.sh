#!/bin/sh
set -eu

echo "🔍 Starting yamllint..."

paths="${INPUT_PATHS:-}"
config="$(printenv 'INPUT_CONFIG-PATH' || echo '')"
fail_on_error="$(printenv 'INPUT_FAIL-ON-ERROR' || echo 'true')"

fail_on_error="$(echo "$fail_on_error" | tr '[:upper:]' '[:lower:]')"
if [ "$fail_on_error" != "true" ]; then
  fail_on_error=false
else
  fail_on_error=true
fi

if [ -z "$paths" ]; then
  echo "::error::No paths provided to yamllint"
  exit 1
fi

echo "Linting paths:"
echo "$paths"
echo "Using config: ${config:-default}"
echo "Fail on error: $fail_on_error"

if [ -n "$config" ] && [ ! -f "$config" ]; then
  echo "::error::Config file '$config' not found"
  exit 1
fi

set +e
if [ -n "$config" ]; then
  yamllint -f parsable -c "$config" $paths > yamllint-output.txt 2>&1
else
  yamllint -f parsable $paths > yamllint-output.txt 2>&1
fi
exit_code=$?
set -e

echo "exit_code=$exit_code" >> "$GITHUB_OUTPUT"

errors=0
warnings=0

if [ -f yamllint-output.txt ]; then
  errors=$(grep -c "error" yamllint-output.txt || true)
  warnings=$(grep -c "warning" yamllint-output.txt || true)
fi

if [ "$errors" -eq 0 ] && [ "$warnings" -eq 0 ]; then
  icon=":white_check_mark:"
else
  icon=":warning:"
fi

{
  echo "## :mag: Yamllint Report: ${icon}"
  echo ""
  echo "| Metric | Value |"
  echo "|--------|-------|"
  echo "| Errors | ${errors} |"
  echo "| Warnings | ${warnings} |"
  echo ""
} >> "$GITHUB_STEP_SUMMARY"

if [ -s yamllint-output.txt ]; then
  {
    echo "<details><summary>Full yamllint output</summary>"
    echo ""
    echo '```text'
    cat yamllint-output.txt
    echo '```'
    echo "</details>"
  } >> "$GITHUB_STEP_SUMMARY"
fi

if [ "$exit_code" -ne 0 ]; then
  if [ "$fail_on_error" = "true" ]; then
    echo "::warning::Yamllint found issues"
    exit 1
  else
    echo "⚠️ Yamllint found issues, but fail-on-error is false. Skipping failure."
    exit 0
  fi
fi

echo "✅ yamllint completed successfully"
