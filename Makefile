# asx
# (c) 2012 Justin Gottula
# The source code of this project is distributed under the terms of the
# simplified BSD license. See the LICENSE file for details.

# project makefile

MAKEFLAGS+=-j16

DC:=gdc
DFLAGS:=-Wall -O0 -g -funittest -fdoc
LIBS:=-lelf

# evaluated when used
SOURCES=$(shell find src -type f -iname '*.d')
IMPORTS=$(shell find src -type f -iname '*.di')
OBJECTS=$(patsubst %.d,%.o,$(SOURCES))
EXE=bin/asx
CLEAN=$(wildcard $(EXE)) $(wildcard src/*.o) $(wildcard dir/*.html)


.PHONY: all clean

# default rule
all: $(EXE)

$(EXE): $(OBJECTS) Makefile
	$(DC) $(DFLAGS) $(LIBS) -o $@ $(OBJECTS)

src/%.o: src/%.d $(IMPORTS) Makefile
	$(DC) $(DFLAGS) -I src -fdoc-dir=doc -o $@ -c $<

clean:
	rm -f $(CLEAN)
