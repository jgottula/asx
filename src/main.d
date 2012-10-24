/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module main;

import std.c.stdlib;
import std.stdio;
import input;
import newline;
import pass0;


void main(string[] args) {
	stderr.write("asx: x86 assembler\n(c) 2012 justin gottula\n\n");
	
	if (args.length != 2) {
		stderr.write("[main|error] expected one argument: source file\n");
		exit(1);
	}
	
	string source = readSource(args[1]);
	
	fixNewlines(source);
	doPass0(source);
	
	writeln(source);
	
	/+string source, ppSource;
	readSource(args[1], source);
	preprocessSource(source, ppSource);
	
	writeln(ppSource);+/
}
