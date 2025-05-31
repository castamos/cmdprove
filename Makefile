# Copyright (C) 2025 Moisés Castañeda
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Licensed under GPL-3.0-or-later. See LICENSE file.
#
# Usage:
#
#   make all          # Builds everything necessary for installation (default target).
#   make test         # Runs all tests, including running the doc examples.
#   make install      # Installs the program and documentation under `INSTALL_PREFIX`
#   make clean        # Deletes everything generated.
#
#   # Fine grained targets:
#   make exes         # Generates (copies) executables and libraries to the build dir
#   make doc          # Generates man pages and docs in other formats.
#   test-examples     # Runs the code in the examples
#   run-tests         # Runs integration tests
#   check-spell       # Checks the spelling of all source files in the project
#
# Output:
#
#   Everything this Makefile generates ends up inside `$(BUILD_DIR)` (i.e. `build/`).
#
# External Dependencies:
#
#   `pandoc`    to format the documentation.
#   `rsync`     to install all the files
#   `codespell` to check spelling
#
# Variables accepted in the command line:
#
#   INSTALL_PREFIX  - Directory prefix for the installation
#   PANDOC_EXE      - Path for the `pandoc` program
#   ...             - Similarly for the other external dependencies
#
#   Can be set like `make {target} {var}={value}...`
#   For example:
#
#     make install INSTALL_PREFIX=/opt/myprog RSYNC_EXE=/usr/remote/bin/rsync
#

ifdef MAKE_VERSION
  $(info GNU Make version $(MAKE_VERSION))
else
  $(error This Makefile requires GNU Make (gmake).)
endif

# For consistency, ensure all shell commands are executed by `bash`
SHELL := $(shell which bash)

# Include project-specific configuration:
CONFIG_FILE ?= config.mk
include $(CONFIG_FILE)

# Check required variables are set in the config file:
ifeq ($(strip $(PROJ_NAME)),) 
  $(error Missing variable: PROJ_NAME in '$(CONFIG_FILE)')
endif

#
# Configurable variables (can be set in the command line)

# Installation directory
INSTALL_PREFIX ?= $(HOME)/.local

# External utilities needed by this Makefile
PANDOC_EXE    ?= pandoc#
CODESPELL_EXE ?= codespell#
RSYNC_EXE     ?= rsync#

#
# Source directories and file lists

SRC_TEST_DIR = test#
SRC_DOC_DIR = doc#
DOC_SOURCES = $(wildcard $(SRC_DOC_DIR)/*.md)#
README = README.md

# Output directories:
BUILD_DIR = build#
DEST_DIR = $(BUILD_DIR)/release
DEST_BIN = $(DEST_DIR)/bin
DEST_LIB = $(DEST_DIR)/lib/$(PROJ_NAME)
DEST_MAN_DIR = $(DEST_DIR)/share/man/man1#
DEST_TXT_DIR = $(DEST_DIR)/share/doc/$(PROJ_NAME)/txt#
DEST_DOC_EXAMPLES_DIR = $(BUILD_DIR)/doc-examples#
DEST_UNINSTALL = $(DEST_DIR)/share/$(PROJ_NAME)

# Internal utilities/executables
CMDPROVE_EXE  = $(DEST_BIN)/$(PROJ_NAME)#
MDEXTRACT_EXE = $(DEST_BIN)/mdextract#
INSTALL_MANIFEST = $(DEST_UNINSTALL)/install.manifest

# Generated documentation in different formats, rendered from corresponding Markdown files:
MAN_TARGETS = $(patsubst $(SRC_DOC_DIR)/%.md,$(DEST_MAN_DIR)/%.1,$(DOC_SOURCES))#
TXT_TARGETS = $(patsubst $(SRC_DOC_DIR)/%.md,$(DEST_TXT_DIR)/%.txt,$(DOC_SOURCES))

# Commands for checking/fixing spelling
FIX_SPELL_CMD = $(CHECK_SPELL_CMD) --interactive 3
CHECK_SPELL_CMD = $(CODESPELL_EXE) --check-filenames --builtin clear,rare,usage

# This one checks individual words (e.g. 'wordA' and 'wordB' in '--wordA-wordB' or
# 'wordB_wordA', for example). However, to make it practical we would need an option
# `--ignore-regex-file`, and that doesn't exist.
#
#CHECK_SPELL_CMD = $(CODESPELL_EXE) --check-filenames --builtin clear,rare,usage \
#  -r '[a-zA-Z]+' --ignore-regex '(?i)\b()subs-ti-tution\b'  


#
# FUNCTIONS

# Checks string $1 is a member of the comma-separated list in variable named $2.
#
check_path_in_var = \
	echo "$${$(2)}" | tr ':' '\n' | grep -q "^$(1)$$" \
	  || echo "WARN: Make sure $(1) is in your $(2) env var."

#
# RULES

.PHONY : all exes doc test clean

all: exes doc install-manifest

doc: $(MAN_TARGETS) $(TXT_TARGETS)

test: test-examples run-tests check-spell

install: $(CMDPROVE_EXE)
	rsync -av --no-perms --ignore-times "$(DEST_DIR)/" "$(INSTALL_PREFIX)/"
	@$(call check_path_in_var,$(INSTALL_PREFIX)/bin,PATH)
	@$(call check_path_in_var,$(INSTALL_PREFIX)/share/man,MANPATH)


# Our executables are shell scripts, just copy them
exes: | $(DEST_BIN)/ $(DEST_LIB)/ $(DEST_UNINSTALL)/
	cp -aR bin/* "$(DEST_BIN)/"
	cp -aR lib/* "$(DEST_LIB)/"
	cp -a uninstall "$(DEST_UNINSTALL)"

clean:
	rm -rf $(BUILD_DIR)

install-manifest: | $(DEST_UNINSTALL)/
	touch $(INSTALL_MANIFEST)
	find "$(DEST_DIR)" \
		-type f -printf '%P\n' -o \
		-type d \( -name "$(PROJ_NAME)" -o -path "*/$(PROJ_NAME)/*" \) -printf '%P/\n' \
		| sort -r > "$(INSTALL_MANIFEST)"


# Target: test-examples
#
#   Extracts all test examples from Markdown docs in $(SRC_DOC_DIR) as well as from the
#   $(README) file, and runs them through `cmdprove`.
#
test-examples : $(README) $(DOC_SOURCES) | $(DEST_DOC_EXAMPLES_DIR)/
	$(MDEXTRACT_EXE) -o $(DEST_DOC_EXAMPLES_DIR) $^
	$(CMDPROVE_EXE) $(DEST_DOC_EXAMPLES_DIR)/sample-test*.sh


# Target: run-tests
#
#    Run the project's tests
#
run-tests :
	$(CMDPROVE_EXE) $(SRC_TEST_DIR)/test_*.sh


# Target: check-spell
#
#   Check spelling for all the files in the project (using misspelling patterns).
#   This is non-interactive, just provides a report.
#
check-spell:
	$(CHECK_SPELL_CMD)


# Target: fix-spell
#
#   Run the spell checker in interactive mode to help fixing spelling.
#
fix-spell:
	$(FIX_SPELL_CMD)


# Implicit rule: %.md => %.1
#
#   Generates a Man Page in $(DEST_MAN_DIR) from each Markdown file in $(SRC_DOC_DIR).
#
.SECONDARY : $(DEST_MAN_DIR)/ # (Prevent deletion: prerequisite created from implicit rule.)
$(DEST_MAN_DIR)/%.1 : $(SRC_DOC_DIR)/%.md | $(DEST_MAN_DIR)/
	$(PANDOC_EXE) -s -t man -V header="$(basename $(notdir $<))" -V section=1 "$<" -o "$@"


# Implicit rule: %.md => %.1
#
#   Generates a plain text file in $(DEST_TXT_DIR) from each Markdown file in
#   $(SRC_DOC_DIR).
#
.SECONDARY : $(DEST_TXT_DIR)/
$(DEST_TXT_DIR)/%.txt : $(SRC_DOC_DIR)/%.md | $(DEST_TXT_DIR)/
	$(PANDOC_EXE) -s -t plain "$<" -o "$@"


# Implicit rule: %/ => {dir}
#
#   Creates directories corresponding to prerequisite whose names end in '/'.
#
%/ :
	mkdir -p $@
