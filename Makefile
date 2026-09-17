# Makefile for hot-plate

app_name     := hot-plate
exe_name     := hop

bin_dir      := bin
src_dir      := src
lib_dir      := lib

test_dir     := test
hooks_dir    := .githooks

bin_file     := $(bin_dir)/$(exe_name)
src_file     := $(src_dir)/core.sh

lib_scripts  := $(wildcard $(lib_dir)/*.sh)
app_scripts  := $(bin_file) $(src_file) $(lib_scripts)

bats_scripts := $(wildcard $(test_dir)/*.bats)
test_scripts := $(bats_scripts) $(test_dir)/test_helper.bash

git_hooks    := $(wildcard $(hooks_dir)/*)
dev_scripts  := $(git_hooks) $(wildcard .github/scripts/*.sh)

SHELL_FILES  ?= $(app_scripts) $(test_scripts) $(dev_scripts)

SHFMT        ?= shfmt
SHELLCHECK   ?= shellcheck
BATS          = $(test_dir)/bats/bin/bats

.PHONY: help
help:
	@cat <<-EOF
	Usage: make [TARGET]
	Targets:
	  setup        Set up local development environment.
	  fmt          Format scripts with shfmt.
	  fmt-check    Check formatting without modifying files.
	  lint         Lint scripts with ShellCheck.
	  test         Run entire Bats test suite.
	  check        Check formatting, lint and run test suite.
	  quick-check  Check formatting and lint.
	EOF

.PHONY: setup
setup:
	@printf "Updating test dependencies...\n"
	@git submodule update --init --recursive
	@printf "Configuring Git hooks...\n"
	@chmod +x $(git_hooks)
	@git config core.hooksPath $(hooks_dir)

.PHONY: fmt
fmt:
	@printf "Formatting scripts with shfmt...\n"
	@$(SHFMT) -w $(SHELL_FILES)

.PHONY: fmt-check
fmt-check:
	@printf "Checking formatting with shfmt...\n"
	@$(SHFMT) -d $(SHELL_FILES)

.PHONY: lint
lint:
	@printf "Linting scripts with ShellCheck...\n"
	@$(SHELLCHECK) \
		--shell    bash    \
		--severity error   \
		--format   gcc     \
		--external-sources \
		$(SHELL_FILES)

.PHONY: test
test:
	@printf "Running Bats test suite...\n"
	@$(CURDIR)/$(BATS) $(bats_scripts)

.PHONY: check
check: fmt-check lint test

.PHONY: quick-check
quick-check: fmt-check lint
