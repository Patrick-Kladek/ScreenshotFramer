# Makefile for the autorevision project

# `a2x / asciidoc` is required to generate the Man page.
# `markdown` is required for the `docs` target, though it is not
# strictly necessary for packaging since unless you are planning on
# serving the docs on a web site they are more readable not as html.
# `shipper` and `gpg` are required for the `release` target, which
# should only be used if you are shipping tarballs (you probably are
# not).

# Get the version number
VERS := $(shell ./autorevision.sh -s VCS_TAG -o ./autorevision.cache | sed -e 's:v/::')
# Date for documentation
DOCDATE := $(shell ./autorevision.sh -s VCS_DATE -o ./autorevision.cache -f | sed -e 's:T.*::')

# Find a md5 program
MD5 := $(shell if command -v "md5" > /dev/null 2>&1; then echo "md5 -q"; elif command -v "md5sum" > /dev/null 2>&1; then echo "md5sum"; fi)

.SUFFIXES: .md .html

.md.html:
	markdown $< > $@

# `prefix`, `mandir` & `DESTDIR` can and should be set on the command line to control installation locations
prefix ?= /usr/local
mandir ?= /share/man
target = $(DESTDIR)$(prefix)

DOCS = \
	NEWS \
	autorevision.asciidoc \
	README.md \
	CONTRIBUTING.md \
	COPYING.md

SOURCES = \
	$(DOCS) \
	autorevision.sh \
	Makefile \
	control

EXTRA_DIST = \
	logo.svg.in \
	contribs \
	AUTHORS.txt \
	autorevision.cache

all : cmd man logo.svg

# The script
cmd: autorevision

# Insert the version number
autorevision: autorevision.sh
	sed -e 's:&&ARVERSION&&:$(VERS):g' autorevision.sh > autorevision
	chmod +x autorevision

# The Man Page
man: autorevision.1.gz

autorevision.1.gz: autorevision.1
	gzip --no-name < autorevision.1 > autorevision.1.gz

autorevision.1: autorevision.asciidoc
	a2x --attribute="revdate=$(DOCDATE)" --attribute="revnumber=$(VERS)" -f manpage autorevision.asciidoc

# HTML representation of the man page
autorevision.html: autorevision.asciidoc
	asciidoc --attribute="revdate=$(DOCDATE)" --attribute="footer-style=revdate" --attribute="revnumber=$(VERS)" --doctype=manpage --backend=xhtml11 autorevision.asciidoc

# Authors
auth: AUTHORS.txt

AUTHORS.txt: .mailmap autorevision.cache
	git log --format='%aN <%aE>' | sort -f | uniq -c | sort -rn | sed 's:^ *[0-9]* *::' > AUTHORS.txt

autorevision.sed: autorevision.cache
	./autorevision.sh -f -t sed -o $< > $@

logo.svg: logo.svg.in autorevision.sed
	sed -f autorevision.sed $< > $@

# The tarball signed and sealed
dist: tarball autorevision-$(VERS).tgz.md5 autorevision-$(VERS).tgz.sig

# The tarball
tarball: autorevision-$(VERS).tgz

# Make an md5 checksum
autorevision-$(VERS).tgz.md5: tarball
	$(MD5) autorevision-$(VERS).tgz > autorevision-$(VERS).tgz.md5

# Make a detached gpg sig
autorevision-$(VERS).tgz.sig: tarball
	gpg --armour --detach-sign --output "autorevision-$(VERS).tgz.sig" "autorevision-$(VERS).tgz"

# The actual tarball
autorevision-$(VERS).tgz: $(SOURCES) all auth
	mkdir autorevision-$(VERS)
	cp -pR $(SOURCES) $(EXTRA_DIST) autorevision-$(VERS)/
	@COPYFILE_DISABLE=1 GZIP=-n9 tar -czf autorevision-$(VERS).tgz --exclude=".DS_Store" autorevision-$(VERS)
	rm -fr autorevision-$(VERS)

install: all
	install -d "$(target)/bin"
	install -m 755 autorevision "$(target)/bin/autorevision"
	install -d "$(target)$(mandir)/man1"
	install -m 644 autorevision.1.gz "$(target)$(mandir)/man1/autorevision.1.gz"

uninstall:
	rm -f "$(target)/bin/autorevision" "$(target)$(mandir)/man1/autorevision.1.gz"

clean:
	rm -f autorevision autorevision.html autorevision.1 autorevision.1.gz
	rm -f autorevision.sed logo.svg
	rm -f *.tgz *.md5 *.sig
	rm -f docbook-xsl.css
	rm -f CONTRIBUTING.html COPYING.html README.html
	rm -f *~ index.html

# Not safe to run in a tarball
devclean: clean
	rm -f autorevision.cache
	rm -f AUTHORS AUTHORS.txt
	rm -f *.orig ./*/*.orig

# HTML versions of doc files suitable for use on a website
docs: \
	autorevision.html \
	README.html \
	CONTRIBUTING.html \
	COPYING.html

# Tag with `git tag -s v/<number>` before running this.
release: docs dist
	git tag -v "v/$(VERS)"
#	shipper version=$(VERS) | sh -e -x
