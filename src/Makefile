# asx
# (c) 2012 Justin Gottula
# The source code of this project is distributed under the terms of the
# simplified BSD license. See the LICENSE file for details.

# project makefile

DC:=ldc2
DFLAGS:=-w -wi -O0 -g -d-debug -disable-inlining -output-o -unittest
IMPORTS:=
LIBS:=

# evaluated when used
SOURCES=$(wildcard *.d)
EXE=asx
DOCDIR=../doc
CLEAN=$(wildcard $(EXE)) $(wildcard $(DOCDIR)/*.html)


.PHONY: all clean

# default rule
all: $(EXE)

$(EXE): $(OBJECTS) Makefile
	$(DC) $(DFLAGS) $(LIBS) -Dd=$(DOCDIR) -of=$@ $(SOURCES)

clean:
	rm -f $(CLEAN)
