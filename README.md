# Language compiler pipeline

**README document version: 2**

Educational C++ project: source code → binary tree → (optional) optimized tree → stack-VM-oriented assembler text. Integrates with **[NeIIor/stack](https://github.com/NeIIor/stack)** (data stack for the VM) and **[NeIIor/proc-and-ass](https://github.com/NeIIor/proc-and-ass)** (assembler + VM).

Upstream language frontend/backend: [NeIIor/language](https://github.com/NeIIor/language). A full checkout normally includes `parsing.cpp`, `backend.cpp`, `text` helpers, etc. **This repository commit may ship as a documentation/tooling overlay** (README v2, scripts, examples, submodule, Makefile for the reorganized layout): merge it into your tree that already contains the compiler sources, or combine with your branch that has `include/`, `src/`, `apps/`, and patches (`text.cpp`, UTF-8 lexer, `record_tree`, `main`→`hlt`, `priprint`→`out`, …).

**Push / merge (for maintainers):** after `git submodule update --init`, authenticate to GitHub and run e.g. `git push origin main` or open a PR from a branch. This environment cannot store your credentials.

---

## Table of contents (English)

1. [Overview](#overview)
2. [Repository layout](#repository-layout)
3. [Pipeline](#pipeline)
4. [Build](#build)
5. [Usage](#usage)
6. [Dependencies](#dependencies)
7. [Examples](#examples)
8. [Stack library (NeIIor/stack)](#stack-library-neiilorstack)
9. [Run on the VM (proc-and-ass)](#run-on-the-vm-proc-and-ass)
10. [Automated tests](#automated-tests)
11. [Git submodules](#git-submodules)
12. [Changelog (README v2)](#changelog-readme-v2)
13. [Notes and limitations](#notes-and-limitations)

---

## Overview

| Program | Role |
|--------|------|
| `frontend` | Source → tree file |
| `optimizer` | Tree → optimized tree |
| `backend` | Tree → assembler-like listing for the course VM |

Sources must be **UTF-8** (Cyrillic keywords).

---

## Repository layout

```
include/          Headers
src/              Implementation (*.cpp), including text.cpp
apps/             main_f.cpp, main_b.cpp, main_o.cpp
examples/         Sample programs (*.lang)
scripts/          run-vm.sh, setup_stack.sh, test-vm-print.sh
vendor/stack/     Git submodule: NeIIor/stack (after init or setup_stack.sh)
Makefile          frontend, backend, optimizer; test-vm* targets
```

---

## Pipeline

1. **Frontend** — parse, build AST, derivative pass, write tree file.
2. **Optimizer** — simplify tree.
3. **Backend** — emit listing consumed by **proc-and-ass** (`compile` → bytecode → `res.exe`).

---

## Build

```bash
make          # ./frontend ./backend ./optimizer
make clean
```

Requires **g++** and **C++11+**.

---

## Usage

```bash
./frontend  <source.lang>  <tree.out>
./optimizer <tree.in>       <tree.opt>
./backend   <tree.in>       <code.asm>
```

`frontend` sets a Russian locale in `main`.

---

## Dependencies

- C++ standard library, C library.
- For the VM toolchain: **NeIIor/stack** (see below) and a patched **proc-and-ass** tree (`STACK_DIR`, `rex`, large `SIZE_RAM`, `hlt` for `main`, etc.).

---

## Examples

| File | Idea |
|------|------|
| `examples/hello.lang` | Minimal `main`: assign and return |
| `examples/print42.lang` | `priprint(42);` — single constant |
| `examples/demo_expr.lang` | Locals `a`, `b`, then `priprint(a * b + a + b);` → **43** (10×3+10+3) |

Manual pipeline:

```bash
./frontend  examples/demo_expr.lang /tmp/t.tree
./optimizer /tmp/t.tree /tmp/t.opt
./backend   /tmp/t.opt /tmp/t.asm
```

---

## Stack library (NeIIor/stack)

The virtual machine from **proc-and-ass** is linked against the **course stack** from **[NeIIor/stack](https://github.com/NeIIor/stack)** — not a custom stub.

**Option A — submodule (recommended for Git):**

```bash
git submodule update --init --recursive
```

**Option B — one-shot clone (same result under `vendor/stack/`):**

```bash
chmod +x scripts/setup_stack.sh
./scripts/setup_stack.sh
```

This removes any placeholder under `vendor/stack/` and runs `git clone --depth 1 https://github.com/NeIIor/stack.git vendor/stack`.

Override clone URL: `STACK_REPO_URL=... ./scripts/setup_stack.sh`.  
Override directory: `STACK_CLONE_DIR=... ./scripts/setup_stack.sh`.

---

## Run on the VM (proc-and-ass)

Place **[NeIIor/proc-and-ass](https://github.com/NeIIor/proc-and-ass)** next to this repo (`../proc-and-ass`) or set **`PROC_VM_ROOT`**. The `Makefile` there must accept **`STACK_DIR`** pointing at `vendor/stack` (NeIIor stack).

```bash
chmod +x scripts/run-vm.sh
./scripts/run-vm.sh
# optional:
# LANG_SRC=examples/demo_expr.lang PROC_VM_ROOT=/path/to/proc-and-ass ./scripts/run-vm.sh
```

---

## Automated tests

After **`setup_stack.sh`** and a reachable **proc-and-ass** tree:

```bash
make test-vm        # print42.lang → expect 42 on stdout
make test-vm-demo   # demo_expr.lang → expect 43
make test-vm-all    # both
```

Equivalent:

```bash
./scripts/test-vm-print.sh
LANG_SRC=examples/demo_expr.lang EXPECTED=43 ./scripts/test-vm-print.sh
```

Environment variables: **`LANG_SRC`**, **`EXPECTED`**, **`PROC_VM_ROOT`**, **`STACK_DIR`**.

---

## Git submodules

`.gitmodules` registers **vendor/stack** → [NeIIor/stack](https://github.com/NeIIor/stack). After `git submodule update --init`, `vendor/stack` tracks that repository.

You can add **proc-and-ass** the same way if you want it inside this tree; then set **`PROC_VM_ROOT`** accordingly and keep the same VM patches as in your course checkout.

---

## Changelog (README v2)

- Document version **2**: expanded TOC (EN), NeIIor/stack integration, `setup_stack.sh`, examples `print42` / `demo_expr`, `make test-vm-demo` / `test-vm-all`, submodule note, clearer VM section.
- **README v1** (legacy): single short example and basic VM paragraph (replaced by sections above).

---

## Notes and limitations

- **`src/text.cpp`** was added here; it was missing upstream.
- **Lexer `isletter`** was fixed for UTF-8 Cyrillic.
- **`record_tree`** does not `fclose` the output file (caller closes it).
- **`priprint`** lowers to **`out`** only (VM pops one value per `out`).
- **`main`** return uses **`hlt`**, not **`ret`** (no `call` into `main`).
- **`//` comments** in sources are stripped in the frontend read path.
- Full **jump** mnemonics in the backend may still differ from stock **proc-and-ass** names for complex control flow; the **demo** examples avoid that.

---

---

# Компилятор — README, версия документа 2

---

## Содержание (русский)

1. [Обзор](#обзор)
2. [Структура репозитория](#структура-репозитория)
3. [Конвейер](#конвейер)
4. [Сборка](#сборка)
5. [Запуск утилит](#запуск-утилит)
6. [Зависимости](#зависимости-1)
7. [Примеры](#примеры)
8. [Библиотека стека NeIIor/stack](#библиотека-стека-neiilorstack)
9. [Виртуальная машина proc-and-ass](#виртуальная-машина-proc-and-ass)
10. [Автотесты](#автотесты)
11. [Git submodules](#git-submodules-1)
12. [История изменений (README v2)](#история-изменений-readme-v2)
13. [Замечания](#замечания)

---

## Обзор

Три программы: **frontend** → **optimizer** → **backend**. Исходники в **UTF-8**, ключевые слова на кириллице.

Отдельные коммиты в этом дереве могут быть **только документацией и скриптами** (без полного исходника компилятора): их нужно **влить** в ваш репозиторий с `parsing.cpp`, `backend.cpp`, `text.cpp` и остальным. Публикация на GitHub: **`git push`** с вашей машины (токен/SSH).

---

## Структура репозитория

См. английский раздел [Repository layout](#repository-layout). Каталог **`vendor/stack/`** — это **[NeIIor/stack](https://github.com/NeIIor/stack)** (после `git submodule update --init` или `./scripts/setup_stack.sh`).

---

## Конвейер

См. [Pipeline](#pipeline).

---

## Сборка

```bash
make
make clean
```

---

## Запуск утилит

См. [Usage](#usage).

---

## Зависимости

См. [Dependencies](#dependencies).

---

## Примеры

- **`examples/hello.lang`** — минимальная программа.
- **`examples/print42.lang`** — вывод константы **42**.
- **`examples/demo_expr.lang`** — переменные **a**, **b**, выражение **a×b + a + b** → на стеке ВМ должно получиться **43**.

---

## Библиотека стека NeIIor/stack

Для сборки **`res.exe`** в **proc-and-ass** используется **официальный стек** [NeIIor/stack](https://github.com/NeIIor/stack), подключаемый через **`STACK_DIR`** (у нас по умолчанию **`vendor/stack`**).

Инициализация:

```bash
./scripts/setup_stack.sh
# или: git submodule update --init --recursive
```

---

## Виртуальная машина proc-and-ass

Репозиторий **[NeIIor/proc-and-ass](https://github.com/NeIIor/proc-and-ass)** — ассемблер и ВМ. Путь задаётся **`PROC_VM_ROOT`** (по умолчанию **`../proc-and-ass`**). Нужны **патчи** под этот бэкенд (`rex`, `SIZE_RAM`, `hlt` для `main` и т.д.) — как в учебном дереве.

---

## Автотесты

```bash
make test-vm
make test-vm-demo
make test-vm-all
```

Переменные: **`LANG_SRC`**, **`EXPECTED`**, **`PROC_VM_ROOT`**, **`STACK_DIR`**.

---

## Git submodules

В **`.gitmodules`** указан submodule **`vendor/stack`** → [NeIIor/stack](https://github.com/NeIIor/stack). Команда: **`git submodule update --init --recursive`**.

---

## История изменений (README v2)

- Версия документа **2**: двуязычные оглавления, NeIIor/stack, скрипты, примеры, цели **`test-vm-demo`** / **`test-vm-all`**, разделы про ВМ и тесты.

---

## Замечания

См. [Notes and limitations](#notes-and-limitations).
