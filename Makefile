
# External utilities needed by this Makefile:
pandoc = pandoc#

doc_src = $(wildcard doc/*.md)#		# Markdown source files
man_pages = $(doc_src:.md=.1)#		# Corresponding `man pages`

.PHONY : doc clean

all: doc

doc: $(man_pages)

clean:
	rm -rf $(man_pages)

# Generic recipe to generate man pages from Markdown:
%.1 : %.md
	$(pandoc) -s -t man -V header="$(basename $(notdir $<))" -V section=1 "$<" -o "$@"

