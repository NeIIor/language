#!/usr/bin/env bash
# Use NeIIor/stack (https://github.com/NeIIor/stack) for proc-and-ass — same as the course VM.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${STACK_CLONE_DIR:-$ROOT/vendor/stack}"
REPO="${STACK_REPO_URL:-https://github.com/NeIIor/stack.git}"

if [[ -f "$TARGET/stack.cpp" && -f "$TARGET/stack.h" ]] && grep -q CANARY1 "$TARGET/stack.h" 2>/dev/null; then
  echo "Stack OK: $TARGET"
  exit 0
fi

if [[ -d "$ROOT/.git" ]] && [[ -f "$ROOT/.gitmodules" ]]; then
  if (cd "$ROOT" && git submodule update --init --depth 1 vendor/stack 2>/dev/null); then
    if [[ -f "$TARGET/stack.cpp" ]] && grep -q CANARY1 "$TARGET/stack.h" 2>/dev/null; then
      echo "Stack initialized via submodule: $TARGET"
      exit 0
    fi
  fi
fi

echo "Cloning $REPO -> $TARGET"
rm -rf "$TARGET"
git clone --depth 1 "$REPO" "$TARGET"
echo "Stack cloned: $TARGET"
