# Copyright (C) 2025 Moisés Castañeda
# SPDX-License-Identifier: GPL-3.0-or-later
# Licensed under GPL-3.0-or-later. See LICENSE file.
#
#   This is the main Makefile for building this project.
#   For detailed usage see `BUILD.md`
#

# Ensure we are running under GNU Make
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

# Check that required variables are set in the config file:
ifeq ($(strip $(PROJ_NAME)),) 
  $(error Missing variable: PROJ_NAME in '$(CONFIG_FILE)')
endif

#
# Configurable variables (can be set in the command line)

# Installation directory
INSTALL_PREFIX ?= $(HOME)/.local

# External utilities needed by this Makefile.
# Expected to be in the PATH, can be overwritten to point anywhere.
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


# Target: all
#
#   Default target for building everything that is needed for installation.
#
all: exes doc install-manifest


# Target: test
#
#   Runs all available tests.
#
test: test-examples run-tests


# Target: install
#
#   Installs all the project's files under `$INSTALL_PREFIX`.
#
install: $(CMDPROVE_EXE)
	rsync -av --no-perms --ignore-times "$(DEST_DIR)/" "$(INSTALL_PREFIX)/"
	@$(call check_path_in_var,$(INSTALL_PREFIX)/bin,PATH)
	@$(call check_path_in_var,$(INSTALL_PREFIX)/share/man,MANPATH)


# Target: clean
#
#   Deletes everything that was generated. Since all generated files are under
#   `$BUILD_DIR`, just wipe out the whole dir.
#
clean:
	rm -rf $(BUILD_DIR)


# Target: exes
#
#   Generates executables. Our executables are shell scripts, so just copy them to the
#   right output directory.
#
exes: | $(DEST_BIN)/ $(DEST_LIB)/ $(DEST_UNINSTALL)/
	cp -aR bin/* "$(DEST_BIN)/"
	cp -aR lib/* "$(DEST_LIB)/"
	cp -a uninstall "$(DEST_UNINSTALL)"


# Target: doc
#
#   Generate documentation as man pages and plain-text, from Markdown sources. This is
#   needed for `all`, since help subcommands for the project's programs use the
#   plain-text generated documentation.
#
doc: $(MAN_TARGETS) $(TXT_TARGETS)


# Target: install-manifest
#
#   Generates a file `$INSTALL_MANIFEST` intended for performing clean uninstallations.
#   This file lists, one per line, each file and directory that will be installed /
#   uninstalled.  The list is provided in depth-first order, so that deleting each file /
#   dir in the listed order results in subsequent empty dirs (at least for a pristine
#   installation).
#
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
#   Runs the project's unit/integration tests.
#
run-tests :
	$(CMDPROVE_EXE) $(SRC_TEST_DIR)/test_*.sh


# Target: check-spell
#
#   Checks spelling for all the files in the project (using misspelling patterns).
#   This is non-interactive, just provides a report.
#
check-spell:
	$(CHECK_SPELL_CMD)


# Target: fix-spell
#
#   Runs the spell checker in interactive mode to help fixing spelling.
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
