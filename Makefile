SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

app_name     := hot-plate
exe_name     := hop

# --- Paths -------------------------------------------------------------------

bin_dir      := bin
src_dir      := src
test_dir     := test
hooks_dir    := .git-hooks

bin_file     := $(bin_dir)/$(exe_name)
src_file     := $(src_dir)/core.sh

app_scripts  := $(bin_file) $(src_file)
bats_scripts := $(wildcard $(test_dir)/*.bats)
test_scripts := $(bats_scripts) $(test_dir)/test_helper.bash

git_hooks    := $(wildcard $(hooks_dir)/*)
dev_scripts  := $(git_hooks) $(wildcard .github/scripts/*.sh)

shell_files  ?= $(app_scripts) $(test_scripts) $(dev_scripts)

# --- Tools -------------------------------------------------------------------

SHFMT        ?= shfmt
SHELLCHECK   ?= shellcheck
BATS         ?= $(test_dir)/bats/bin/bats

SHELLCHECK_FLAGS ?=  \
	--shell    bash  \
	--severity error \
	--format   gcc   \
	--external-sources

# -----------------------------------------------------------------------------
# Targets
# -----------------------------------------------------------------------------

.PHONY: help
help: ## Print this help guide.
	@awk '
		BEGIN {
			FS = ":.*##"
			print "Usage: make [TARGET]"
			print ""
			print "Targets:"
		}
		/^[a-zA-Z0-9_-]+:.*##/ {
			printf "  %-12s %s\n", $$1, $$2
		}
	' $(MAKEFILE_LIST)

# --- Setup -------------------------------------------------------------------

.PHONY: check-tools
check-tools: ## Verify system dependencies.
	@command -v $(SHFMT) >/dev/null || {
		printf "error: %s not found.\n" "$(SHFMT)" >&2
		exit 1
	}
	@command -v $(SHELLCHECK) >/dev/null || {
		printf "error: %s not found.\n" "$(SHELLCHECK)" >&2
		exit 1
	}

.PHONY: setup
setup: check-tools ## Set up local environment.
	@printf "Updating test dependencies...\n"
	@git submodule update --init --recursive
	@printf "Configuring Git hooks...\n"
	@chmod +x $(git_hooks)
	@git config core.hooksPath $(hooks_dir)

# --- Formatting --------------------------------------------------------------

.PHONY: fmt
fmt: ## Format scripts with shfmt.
	@printf "Formatting scripts with shfmt...\n"
	@$(SHFMT) --write $(shell_files)

.PHONY: fmt-check
fmt-check: ## Check formatting without modifying files.
	@printf "Checking formatting with shfmt...\n"
	@$(SHFMT) --diff $(shell_files)

# --- Validation --------------------------------------------------------------

.PHONY: lint
lint: ## Lint scripts with ShellCheck.
	@printf "Linting scripts with ShellCheck...\n"
	@$(SHELLCHECK) $(SHELLCHECK_FLAGS) $(shell_files)

.PHONY: test
test: ## Run entire Bats test suite.
	@printf "Running Bats test suite...\n"
	@$(CURDIR)/$(BATS) --allow-empty-suite $(bats_scripts)

# --- Checks ------------------------------------------------------------------

.PHONY: check
check: fmt-check lint test ## Check formatting and run linter & test suite.

.PHONY: quick-check
quick-check: fmt-check lint ## Check formatting and run linter.
