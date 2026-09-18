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
help:
	@cat <<-EOF
	Usage: make [TARGET]
	Targets:
	  check-tools  Verify system dependencies.
	  setup        Set up local development environment.
	  fmt          Format scripts with shfmt.
	  fmt-check    Check formatting without modifying files.
	  lint         Lint scripts with ShellCheck.
	  test         Run entire Bats test suite.
	  check        Check formatting, lint and run test suite.
	  quick-check  Check formatting and lint.
	EOF

# --- Setup -------------------------------------------------------------------

.PHONY: check-tools
check-tools:
	@command -v $(SHFMT) >/dev/null || { \
			printf "error: %s not found.\n" "$(SHFMT)" >&2 ; \
			exit 1 ; \
		}
	@command -v $(SHELLCHECK) >/dev/null || { \
			printf "error: %s not found.\n" "$(SHELLCHECK)" >&2 ; \
			exit 1 ; \
		}

.PHONY: setup
setup: check-tools
	@printf "Updating test dependencies...\n"
	@git submodule update --init --recursive
	@printf "Configuring Git hooks...\n"
	@chmod +x $(git_hooks)
	@git config core.hooksPath $(hooks_dir)

# --- Formatting --------------------------------------------------------------

.PHONY: fmt
fmt:
	@printf "Formatting scripts with shfmt...\n"
	@$(SHFMT) --write $(shell_files)

.PHONY: fmt-check
fmt-check:
	@printf "Checking formatting with shfmt...\n"
	@$(SHFMT) --diff $(shell_files)

# --- Validation --------------------------------------------------------------

.PHONY: lint
lint:
	@printf "Linting scripts with ShellCheck...\n"
	@$(SHELLCHECK) $(SHELLCHECK_FLAGS) $(shell_files)

.PHONY: test
test:
	@printf "Running Bats test suite...\n"
	@$(CURDIR)/$(BATS) --allow-empty-suite $(bats_scripts)

# --- Checks ------------------------------------------------------------------

.PHONY: check
check: fmt-check lint test

.PHONY: quick-check
quick-check: fmt-check lint
