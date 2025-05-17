# Usage:
#
#   make doc          # Generates man pages and docs in other formats.
#   make test         # Runs tests tool, including running the doc examples.
#   make check-spell  # Checks spelling
#   make test-all     # make test + make check-spell
#   make all          # Builds/tests everything.
#   make clean        # Deletes everything generated.
#
#  Output:
#   Everything this Makefile generates ends up inside $(DEST_DIR) (i.e. `build/`).
#
# External Dependencies:
#   `pandoc` is used to format the documentation.
#

# External utilities needed by this Makefile:
PANDOC_EXE = pandoc#
CMDPROVE_EXE = bin/cmdprove#
MDEXTRACT_EXE = bin/mdextract#
CODESPELL_EXE = codespell#

# Source directories and file lists
SRC_TEST_DIR = test#
SRC_DOC_DIR = doc#
DOC_SOURCES = $(wildcard $(SRC_DOC_DIR)/*.md)#
README = README.md

# Output directories:
DEST_DIR = build#
DEST_MAN_DIR = $(DEST_DIR)/doc/man#
DEST_TXT_DIR = $(DEST_DIR)/doc/txt#
DEST_DOC_EXAMPLES_DIR = $(DEST_DIR)/test/doc-examples#

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
# RULES

.PHONY : all clean doc test

all: doc test

test: test-examples run-tests

test-all: test check-spell

doc: $(MAN_TARGETS) $(TXT_TARGETS)

clean:
	rm -rf $(DEST_DIR)


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
