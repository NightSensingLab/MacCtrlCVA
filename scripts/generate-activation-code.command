#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SWIFT_SCRIPT="$ROOT_DIR/scripts/generate-activation-code.swift"
MODULE_CACHE="$ROOT_DIR/build/ModuleCache"

cd "$ROOT_DIR"

clear >/dev/null 2>&1 || true
echo "MacCtrlCVA Activation Code Generator"
echo
echo "Enter 1 or 2 machine codes."
echo "Leave the second machine code empty if this activation is for one Mac only."
echo

printf "Machine code 1: "
IFS= read -r MACHINE_CODE_1
if [[ -z "${MACHINE_CODE_1// }" ]]; then
  echo
  echo "error: Machine code 1 is required."
  echo
  printf "Press Enter to close..."
  IFS= read -r _
  exit 1
fi

printf "Machine code 2 (optional): "
IFS= read -r MACHINE_CODE_2

printf "Note (optional, e.g. buyer nickname or order ID): "
IFS= read -r LABEL

ARGS=("--output" "kv")
if [[ -n "${LABEL// }" ]]; then
  ARGS+=("--label" "$LABEL")
fi
ARGS+=("$MACHINE_CODE_1")
if [[ -n "${MACHINE_CODE_2// }" ]]; then
  ARGS+=("$MACHINE_CODE_2")
fi

echo
echo "Generating activation code..."
echo

OUTPUT="$(swift -module-cache-path "$MODULE_CACHE" "$SWIFT_SCRIPT" "${ARGS[@]}")"

ACTIVATION_CODE="$(printf "%s\n" "$OUTPUT" | awk -F= '/^ACTIVATION_CODE=/{sub(/^ACTIVATION_CODE=/,""); print}')"
RECORD_ID="$(printf "%s\n" "$OUTPUT" | awk -F= '/^RECORD_ID=/{sub(/^RECORD_ID=/,""); print}')"
RECORDS_PATH="$(printf "%s\n" "$OUTPUT" | awk -F= '/^RECORDS_PATH=/{sub(/^RECORDS_PATH=/,""); print}')"

COPIED_TO_CLIPBOARD="no"
if command -v pbcopy >/dev/null 2>&1; then
  if printf "%s" "$ACTIVATION_CODE" | pbcopy 2>/dev/null; then
    COPIED_TO_CLIPBOARD="yes"
  fi
fi

echo "Activation code generated successfully."
echo
echo "Machine codes:"
echo "1. $MACHINE_CODE_1"
if [[ -n "${MACHINE_CODE_2// }" ]]; then
  echo "2. $MACHINE_CODE_2"
fi
echo
if [[ -n "${LABEL// }" ]]; then
  echo "Note:"
  echo "$LABEL"
  echo
fi
echo "Record ID:"
echo "$RECORD_ID"
echo
echo "Records file:"
echo "$RECORDS_PATH"
echo
echo "Activation code:"
echo "$ACTIVATION_CODE"
echo
if [[ "$COPIED_TO_CLIPBOARD" == "yes" ]]; then
  echo "The activation code has been copied to the clipboard."
else
  echo "Clipboard copy was skipped. Copy the activation code manually from this window."
fi
echo
printf "Press Enter to close..."
IFS= read -r _
