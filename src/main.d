/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module main;

import std.c.stdlib;
import std.conv;
import std.stdio;
import input;
import newline;
import pass0;
import pass1;


void main(in string[] args) {
	stderr.write("asx: x86 assembler\n(c) 2012 justin gottula\n\n");
	
	if (args.length != 2) {
		stderr.write("[main|error] expected one argument: source file\n");
		exit(1);
	}
	
	string path = args[1];
	string source = readSource(path);
	fixNewlines(source);
	
	Line[] lines = doPass0(path, source);
	
	foreach (line; lines) {
		foreach (token; line.tokens) {
			string tag;
			
			switch (token.type) {
			case TokenType.LITERAL_INT:
				tag = token.tagInt.to!string();
				break;
			case TokenType.REGISTER:
				tag = token.tagReg.to!string();
				break;
			default:
				tag = token.tagStr;
			}
			
			writefln("%s [%s] @ %s %d:%d", token.type, tag, token.origin.file,
				token.origin.line, token.origin.col);
		}
	}
	
	AsmContext ctx = doPass1(lines);
	
	/+string source, ppSource;
	readSource(args[1], source);
	preprocessSource(source, ppSource);
	
	writeln(ppSource);+/
}
