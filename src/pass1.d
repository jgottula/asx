/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module pass1;

import std.c.stdlib;
import std.stdio;
import std.string;
import pass0;


/* pass1: directives, macros, symbols, label addresses */


private enum State {
	START,
	DIR_DEF,
}

public class AsmContext {
	this() {
		
	}
	
private:
}

State state;
AsmContext ctx;


private void error(in TokenLocation l, in string msg) {
	stderr.writefln("[pass1|error|%d:%d] %s", l.line, l.col, msg);
	exit(1);
}

private void warn(in TokenLocation l, in string msg) {
	stderr.writefln("[pass1|warn|%d:%d] %s", l.line, l.col, msg);
}

AsmContext doPass1(in Line[] lines) {
	ctx = new AsmContext();
	
lineLoop:
	foreach (line; lines) {
		state = State.START;
		
	tokenLoop:
		foreach (ulong i, token; line.tokens) {
			/* errors should read like: "expected ___ after ___"
			 * or "unexpected token after|before ___" */
			final switch (state) {
			case State.START:
				if (token.type == TokenType.DIRECTIVE) {
					switch (token.tagStr) {
					case ".def":
						state = State.DIR_DEF;
						break;
					default:
						error(token.origin,
							"unknown directive '%s'".format(token.tagStr));
						break;
					}
				} else {
					error(token.origin,
						"FATAL: unhandled token: %s".format(token));
				}
				break;
			case State.DIR_DEF:
				warn(token.origin, "UNIMPLEMENTED: .def");
				break;
			}
		}
	}
	
	return ctx;
}
