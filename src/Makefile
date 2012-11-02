# asx
# (c) 2012 Justin Gottula
# The source code of this project is distributed under the terms of the
# simplified BSD license. See the LICENSE file for details.

# project makefile

DC:=ldc2
DFLAGS:=-w -wi -O0 -g -d-debug -disable-inlining -output-o -unittest
LIBS:=-L=-lelf

# evaluated when used
SOURCES=$(shell find -type f -iname '*.d')
IMPORTS:=$(shell find -type f -iname '*.di')
OBJECTS=$(patsubst %.d,%.o,$(SOURCES))
EXE=asx
DOCDIR=../doc
CLEAN=$(wildcard $(EXE)) $(wildcard *.o) $(wildcard $(DOCDIR)/*.html)


.PHONY: all clean

# default rule
all: $(EXE)

$(EXE): $(OBJECTS) Makefile
	$(DC) $(DFLAGS) $(LIBS) -of=$@ $(OBJECTS)

%.o: %.d $(IMPORTS) Makefile
	$(DC) $(DFLAGS) -Dd=$(DOCDIR) -of=$@ -c $<

clean:
	rm -f $(CLEAN)
