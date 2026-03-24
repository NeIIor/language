#!/usr/bin/env bash
# Compile language → asm → strip comments → assemble → run stack VM.
# Requires a built proc-and-ass tree (see README). Patched proc expects STACK_DIR.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LANG_SRC="${LANG_SRC:-$ROOT/examples/hello.lang}"
PROC_ROOT="${PROC_VM_ROOT:-$ROOT/../proc-and-ass}"
STACK_DIR="${STACK_DIR:-$ROOT/vendor/stack}"
WORKDIR="${WORKDIR:-$(mktemp -d /tmp/lang-vm-XXXXXX)}"

if [[ ! -d "$PROC_ROOT" ]]; then
  echo "proc-and-ass not found: $PROC_ROOT" >&2
  echo "Clone it: git clone https://github.com/NeIIor/proc-and-ass.git" >&2
  echo "Or set PROC_VM_ROOT to the directory that contains compile and res.exe" >&2
  exit 1
fi

chmod +x "$ROOT/scripts/setup_stack.sh" 2>/dev/null || true
"$ROOT/scripts/setup_stack.sh"

if [[ ! -f "$STACK_DIR/stack.cpp" ]]; then
  echo "Stack library missing: $STACK_DIR (NeIIor/stack — run scripts/setup_stack.sh)" >&2
  exit 1
fi

make -C "$ROOT" -s
make -C "$PROC_ROOT" comp run STACK_DIR="$STACK_DIR" -s

"$ROOT/frontend"  "$LANG_SRC" "$WORKDIR/tree.bin"
"$ROOT/optimizer" "$WORKDIR/tree.bin" "$WORKDIR/tree.opt"
"$ROOT/backend"   "$WORKDIR/tree.opt" "$WORKDIR/out.asm"

# Assembler tokenizes with fscanf("%s"); drop // comments and blank lines.
sed 's|//.*||g' "$WORKDIR/out.asm" | sed '/^[[:space:]]*$/d' > "$PROC_ROOT/cmd.txt"

(
  cd "$PROC_ROOT"
  ./compile >/dev/null 2>&1
  ./res.exe
)

rm -rf "$WORKDIR"
