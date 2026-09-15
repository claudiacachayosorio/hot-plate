# Makefile for hot-plate

app_name     := hot-plate
exe_name     := hop

bin_dir      := bin
src_dir      := src
lib_dir      := lib
test_dir     := test

bin_file     := $(bin_dir)/$(exe_name)
src_file     := $(src_dir)/core.sh

bats_scripts := $(wildcard $(test_dir)/*.bats)
test_scripts := $(bats_scripts) $(test_dir)/test_helper.bash

lib_scripts  := $(wildcard $(lib_dir)/*.sh)
app_scripts  := $(bin_file) $(src_file) $(lib_scripts)

ci_scripts   := $(wildcard .github/scripts/*.sh)
bash_scripts := $(app_scripts) $(test_scripts) $(ci_scripts)

SHELLCHECK   ?= shellcheck
BATS          = $(test_dir)/bats/bin/bats

.PHONY: help lint test check

help:
	@cat <<-EOF
	Usage: make [TARGET]
	Targets:
	  lint     Run ShellCheck on all scripts.
	  test     Run entire Bats test suite.
	  check    Execute lint and test targets.
	EOF

lint:
	@printf "Linting scripts with ShellCheck...\n"
	@$(SHELLCHECK) --severity=error --format=gcc $(bash_scripts)

test:
	@printf "Verifying test dependencies...\n"
	@git submodule update --init --recursive
	@chmod +x $(BATS)
	@printf "Dependencies up to date. Running test suite...\n"
	@$(CURDIR)/$(BATS) $(bats_scripts)

check:
	$(MAKE) lint
	$(MAKE) test
