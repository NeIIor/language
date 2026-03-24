#!/usr/bin/env bash
# Build asm, assemble, run VM; compare first integer line on stdout to EXPECTED.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROC_ROOT="${PROC_VM_ROOT:-$ROOT/../proc-and-ass}"
STACK_DIR="${STACK_DIR:-$ROOT/vendor/stack}"
SRC="${LANG_SRC:-$ROOT/examples/print42.lang}"
EXPECTED="${EXPECTED:-42}"

chmod +x "$ROOT/scripts/setup_stack.sh" 2>/dev/null || true
"$ROOT/scripts/setup_stack.sh"

WORKDIR="$(mktemp -d /tmp/lang-test-vm-XXXXXX)"
trap 'rm -rf "$WORKDIR"' EXIT

if [[ ! -d "$PROC_ROOT" ]]; then
  echo "FAIL: proc-and-ass not found at $PROC_ROOT" >&2
  exit 2
fi

if [[ ! -f "$STACK_DIR/stack.cpp" ]]; then
  echo "FAIL: NeIIor stack not found under $STACK_DIR (run scripts/setup_stack.sh)" >&2
  exit 2
fi

make -C "$ROOT" -s
make -C "$PROC_ROOT" comp run STACK_DIR="$STACK_DIR" -s

"$ROOT/frontend"  "$SRC" "$WORKDIR/tree.bin" >/dev/null
"$ROOT/optimizer" "$WORKDIR/tree.bin" "$WORKDIR/tree.opt" >/dev/null
"$ROOT/backend"   "$WORKDIR/tree.opt" "$WORKDIR/out.asm" >/dev/null

sed 's|//.*||g' "$WORKDIR/out.asm" | sed '/^[[:space:]]*$/d' > "$PROC_ROOT/cmd.txt"
(
  cd "$PROC_ROOT"
  ./compile >/dev/null 2>&1
  ./res.exe 2>/dev/null | tr -d '\r'
) > "$WORKDIR/vm.out"

OUT="$(cat "$WORKDIR/vm.out")"
FIRST="$(printf '%s\n' "$OUT" | grep -E '^-?[0-9]+$' | head -1)"
if [[ "$FIRST" == "$EXPECTED" ]]; then
  echo "OK: VM printed $FIRST (expected $EXPECTED)  [$SRC]"
  exit 0
fi

echo "FAIL: expected first integer line '$EXPECTED', got:" >&2
printf '%s\n' "$OUT" >&2
echo "--- asm ---" >&2
cat "$WORKDIR/out.asm" >&2
exit 1
