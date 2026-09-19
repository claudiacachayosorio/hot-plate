# =============================================================================
# Configuration
# =============================================================================

SHELL        := bash
.ONESHELL:
.SHELLFLAGS  := -eu -o pipefail -c

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
BATS         ?= $(CURDIR)/$(test_dir)/bats/bin/bats

SHELLCHECK_FLAGS ?=  \
	--shell    bash  \
	--severity error \
	--format   gcc   \
	--external-sources

# =============================================================================
# Targets
# =============================================================================

.PHONY: help ## Print this help guide.
help:
	@awk '
		BEGIN {
			FS = "##"
			print "Usage: make [TARGET]"
			print ""
			print "Targets:"
		}
		/^\.PHONY: [a-zA-Z0-9_-]+ ##/ {
			sub(/.PHONY: /, "", $$1)
			printf "  %-12s %s\n", $$1, $$2
		}
	' $(MAKEFILE_LIST)

# --- Setup -------------------------------------------------------------------

.PHONY: check-tools ## Verify system dependencies.
check-tools:
	@command -v $(SHFMT) >/dev/null || {
		printf "error: %s not found.\n" "$(SHFMT)" >&2
		exit 1
	}
	@command -v $(SHELLCHECK) >/dev/null || {
		printf "error: %s not found.\n" "$(SHELLCHECK)" >&2
		exit 1
	}

.PHONY: setup ## Set up local environment.
setup: check-tools
	@printf "Updating test dependencies...\n"
	@git submodule update --init --recursive
	@printf "Configuring Git hooks...\n"
	@chmod +x $(git_hooks)
	@git config core.hooksPath $(hooks_dir)

# --- Formatting --------------------------------------------------------------

.PHONY: fmt ## Format scripts with shfmt.
fmt:
	@printf "Formatting scripts with shfmt...\n"
	@$(SHFMT) --write $(shell_files)

.PHONY: fmt-check ## Check formatting without modifying files.
fmt-check:
	@printf "Checking formatting with shfmt...\n"
	@$(SHFMT) --diff $(shell_files)

# --- Validation --------------------------------------------------------------

.PHONY: lint ## Lint scripts with ShellCheck.
lint:
	@printf "Linting scripts with ShellCheck...\n"
	@$(SHELLCHECK) $(SHELLCHECK_FLAGS) $(shell_files)

.PHONY: test ## Run entire Bats test suite.
test:
	@printf "Running Bats test suite...\n"
	@$(BATS) --allow-empty-suite $(bats_scripts)

# --- Checks ------------------------------------------------------------------

.PHONY: check ## Check formatting and run linter & test suite.
check: check-tools fmt-check lint test

.PHONY: quick-check ## Check formatting and run linter.
quick-check: fmt-check lint
