/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module main;

import std.c.stdlib;
import std.conv;
import std.stdio;
import expression;
import input;
import newline;
import pass0;
import pass1;
import token;


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
	
	foreach (ulong i, line; lines) {
		writefln("line %d:", i + 1);
		
		foreach (token; line.tokens) {
			string tag;
			
			switch (token.type) {
			case TokenType.INTEGER:
				tag = (token.tagInt.sign == Sign.NEGATIVE ? "-" : "") ~
					token.tagInt.value.to!string();
				break;
			default:
				tag = token.tagStr;
			}
			
			writefln("%3d:%-3d %s [%s] @ %s", token.origin.line,
				token.origin.col, token.type, tag, token.origin.file);
		}
		
		writeln();
	}
	
	doPass1(lines);
}
