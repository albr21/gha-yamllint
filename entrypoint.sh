#!/bin/sh
set -eu

echo "🔍 Starting yamllint..."

# Inputs GitHub Actions
paths="${INPUT_PATHS:-}"
config="${INPUT_CONFIG_PATH:-}"
fail_on_error="${INPUT_FAIL_ON_ERROR:-true}"

if [ -z "$paths" ]; then
  echo "::error::No paths provided to yamllint"
  exit 1
fi

echo "Linting paths:"
echo "$paths"

# Build command safely as array (POSIX-safe workaround)
set -- yamllint -f parsable

if [ -n "$config" ]; then
  set -- "$@" -c "$config"
fi

# Expand paths (support multiple space-separated inputs)
for p in $paths; do
  set -- "$@" "$p"
done

echo "Running: $*"

"$@" 2>&1 | tee yamllint-output.txt
exit_code=${PIPESTATUS[0]}

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
