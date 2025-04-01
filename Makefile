# Usage:
#
# 	make doc 	 # To generate man pages and doc in other formats.
# 	make test  # To run tests for the `cmdprove` tool, including running the doc examples.
# 	make all   # To do it all.
# 	make clean # To delete everything generated.
#
#	Output:
# 	Everything this Makefile generates ends up inside $(DEST_DIR) (i.e. `build/`).
#
# External Dependencies:
# 	`pandoc` is used to format the documentation.
#

# External utilities needed by this Makefile:
PANDOC_EXE = pandoc#
CMDPROVE_EXE = bin/cmdprove
MDEXTRACT_EXE = bin/mdextract

# Source directories and file lists
SRC_DOC_DIR = doc#
DOC_SOURCES = $(wildcard $(SRC_DOC_DIR)/*.md)#

# Output directories:
DEST_DIR = build#
DEST_MAN_DIR = $(DEST_DIR)/doc/man#
DEST_TXT_DIR = $(DEST_DIR)/doc/txt#
DEST_DOC_EXAMPLES_DIR = $(DEST_DIR)/test/doc-examples#

# Generated documentation in different formats, rendered from corresponding Markdown files:
MAN_TARGETS = $(patsubst $(SRC_DOC_DIR)/%.md,$(DEST_MAN_DIR)/%.1,$(DOC_SOURCES))#
TXT_TARGETS = $(patsubst $(SRC_DOC_DIR)/%.md,$(DEST_TXT_DIR)/%.txt,$(DOC_SOURCES))

#
# RULES

.PHONY : all clean doc test

all: doc test

test: test_examples

doc: $(MAN_TARGETS) $(TXT_TARGETS)

clean:
	rm -rf $(DEST_DIR)


# Target: test_examples
#
# 	Extracts all test examples from Markdown docs in $(SRC_DOC_DIR) and runs them
# 	through `cmdprove`.
#
test_examples : $(DOC_SOURCES) | $(DEST_DOC_EXAMPLES_DIR)/
	$(MDEXTRACT_EXE) -o $(DEST_DOC_EXAMPLES_DIR) $^
	$(CMDPROVE_EXE) $(DEST_DOC_EXAMPLES_DIR)/sample-test*.sh


# Implicit rule: %.md => %.1
#
# 	Generates a Man Page in $(DEST_MAN_DIR) from each Markdown file in $(SRC_DOC_DIR).
#
.SECONDARY : $(DEST_MAN_DIR)/ # (Prevent deletion: prerequisite created from implicit rule.)
$(DEST_MAN_DIR)/%.1 : $(SRC_DOC_DIR)/%.md | $(DEST_MAN_DIR)/
	$(PANDOC_EXE) -s -t man -V header="$(basename $(notdir $<))" -V section=1 "$<" -o "$@"


# Implicit rule: %.md => %.1
#
# 	Generates a plain text file in $(DEST_TXT_DIR) from each Markdown file in
# 	$(SRC_DOC_DIR).
#
.SECONDARY : $(DEST_TXT_DIR)/
$(DEST_TXT_DIR)/%.txt : $(SRC_DOC_DIR)/%.md | $(DEST_TXT_DIR)/
	$(PANDOC_EXE) -s -t plain "$<" -o "$@"


# Implicit rule: %/ => {dir}
#
# 	Creates directories corresponding to prerequisite whose names end in '/'.
#
%/ :
	mkdir -p $@
