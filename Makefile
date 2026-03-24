CXX      := g++
CXXFLAGS := -std=c++11 -Wall -O2 -Iinclude
LDFLAGS  :=

.PHONY: all clean test-vm test-vm-demo test-vm-all

all: frontend backend optimizer

test-vm:
	@chmod +x scripts/setup_stack.sh scripts/test-vm-print.sh
	@./scripts/test-vm-print.sh

test-vm-demo:
	@chmod +x scripts/setup_stack.sh scripts/test-vm-print.sh
	@LANG_SRC=examples/demo_expr.lang EXPECTED=43 ./scripts/test-vm-print.sh

test-vm-all: test-vm test-vm-demo

frontend: apps/main_f.cpp src/parsing.cpp src/tree.cpp src/tree_recording.cpp \
	src/derivative.cpp src/text.cpp
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^

backend: apps/main_b.cpp src/backend.cpp src/tree_reading.cpp src/tree.cpp src/text.cpp
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^

optimizer: apps/main_o.cpp src/optimizer.cpp src/tree_reading.cpp src/tree.cpp \
	src/tree_recording.cpp src/derivative.cpp src/text.cpp
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^

clean:
	rm -f frontend backend optimizer
