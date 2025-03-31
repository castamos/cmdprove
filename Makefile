
# External utilities needed by this Makefile:
PANDOC_EXE = pandoc#

# Source directories and file lists
SRC_DOC_DIR = doc#
DOC_SOURCES = $(wildcard $(SRC_DOC_DIR)/*.md)#

# Output directories:
DEST_DIR = build#
DEST_MAN_DIR = $(DEST_DIR)/doc/man#
DEST_TXT_DIR = $(DEST_DIR)/doc/txt#


# Generated documentation in different formats, rendered from corresponding Markdown files:
MAN_TARGETS = $(patsubst $(SRC_DOC_DIR)/%.md,$(DEST_MAN_DIR)/%.1,$(DOC_SOURCES))#
TXT_TARGETS = $(patsubst $(SRC_DOC_DIR)/%.md,$(DEST_TXT_DIR)/%.txt,$(DOC_SOURCES))

#
# RULES

.PHONY : doc clean

all: doc

doc: $(MAN_TARGETS) $(TXT_TARGETS)

clean:
	rm -rf $(DEST_DIR)

# Generic recipe to generate man pages from Markdown:
$(DEST_MAN_DIR)/%.1 : $(SRC_DOC_DIR)/%.md $(DEST_MAN_DIR)/
	$(PANDOC_EXE) -s -t man -V header="$(basename $(notdir $<))" -V section=1 "$<" -o "$@"

# Generic recipe to generate doc in plain-text format from Markdown:
$(DEST_TXT_DIR)/%.txt : $(SRC_DOC_DIR)/%.txt $(DEST_TXT_DIR)/
	$(PANDOC_EXE) -s -t plain "$<" -o "$@"

# Rule for creating output directories:
%/ :
	mkdir -p $@

