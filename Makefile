# term-project — CS 370
# Targets here are real and run today. Several are no-ops until there is source
# to build. If a target stops doing what its name says, fix it or rename it —
# CLAUDE.md treats a lying target as a bug.

CC       := gcc
CSTD     := -std=c17
WARN     := -Wall -Wextra -Werror
CFLAGS   := $(CSTD) $(WARN) -O2 -g
SANFLAGS := -fsanitize=address,undefined -fno-omit-frame-pointer -g -O1
LDFLAGS  :=

SRCDIR   := src
TESTDIR  := tests
BUILDDIR := build
BIN      := $(BUILDDIR)/term-project

SRCS := $(wildcard $(SRCDIR)/*.c)
OBJS := $(patsubst $(SRCDIR)/%.c,$(BUILDDIR)/%.o,$(SRCS))

.PHONY: all test asan memcheck soakcheck deploy clean help

## all: build the systems core
all:
	@if [ -z "$(SRCS)" ]; then \
	    echo "make: no sources in $(SRCDIR)/ yet (project is at M0) - nothing to build."; \
	  else \
	    $(MAKE) --no-print-directory $(BIN); \
	  fi

$(BIN): $(OBJS) | $(BUILDDIR)
	$(CC) $(CFLAGS) $(OBJS) -o $@ $(LDFLAGS)

$(BUILDDIR)/%.o: $(SRCDIR)/%.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILDDIR):
	@mkdir -p $(BUILDDIR)

## test: run the test suite
test:
	@if [ -z "$(wildcard $(TESTDIR)/*.c)" ]; then \
	    echo "make test: no tests in $(TESTDIR)/ yet (project is at M0)."; \
	  else \
	    echo "TODO: wire up the test runner when the first test lands."; exit 1; \
	  fi

## asan: build and run under AddressSanitizer + UBSan
asan:
	@if [ -z "$(SRCS)" ]; then \
	    echo "make asan: no sources yet (project is at M0)."; \
	  else \
	    mkdir -p $(BUILDDIR)/asan; \
	    $(CC) $(CSTD) $(WARN) $(SANFLAGS) $(SRCS) -o $(BUILDDIR)/asan/term-project; \
	    echo "built $(BUILDDIR)/asan/term-project - run it to collect findings."; \
	  fi

## memcheck: run under valgrind (Linux/Pi; not available on macOS ARM)
memcheck:
	@if ! command -v valgrind >/dev/null 2>&1; then \
	    echo "make memcheck: valgrind not installed here (expected on macOS - run this on the Pi)."; \
	  elif [ ! -x $(BIN) ]; then \
	    echo "make memcheck: build first ($(BIN) not present)."; \
	  else \
	    valgrind --leak-check=full --show-leak-kinds=all --error-exitcode=1 $(BIN); \
	  fi

## soakcheck: 1-hour miniature of the graded 48h soak
soakcheck:
	@echo "make soakcheck: not implemented yet - needs the supervisor and heartbeat logging."
	@echo "Per spec 3.4 this must exercise: startup, hourly heartbeat (liveness/RSS/event counts),"
	@echo "an injected fault with detect-degrade-recover, and an orderly shutdown."

## deploy: rsync the tree to the Pi. usage: make deploy PI=pi@hostname
deploy:
	@if [ -z "$(PI)" ]; then \
	    echo "usage: make deploy PI=pi@hostname"; exit 1; \
	  else \
	    rsync -av --exclude '.git' --exclude 'build' --exclude 'transcripts' ./ $(PI):~/term-project/; \
	  fi

## clean: remove build artifacts
clean:
	@rm -rf $(BUILDDIR)

## help: list targets
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## /  /'
