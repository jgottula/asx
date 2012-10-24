/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module preprocess;

import std.c.stdlib;
import std.stdio;


enum PPState {
	DEFAULT,
	COMMENT_BLOCK, COMMENT_NEST, COMMENT_LINE,
	HASH, PPEND,
	INCLUDE, INCLUDE_STR,
	STRING,
	CHAR,
}

PPState state;


void preprocessSource(in string original, out string processed) {
	string src = original;
	char[] buffer, outBuf;
	ulong level = 0;
	
	while (src.length != 0) {
		if (state == PPState.DEFAULT) {
			if (src[0] == '/' && src.length >= 2) {
				if (src[1] == '*') {
					src = src[2..$];
					state = PPState.COMMENT_BLOCK;
					continue;
				} else if (src[1] == '+') {
					src = src[2..$];
					level = 1;
					state = PPState.COMMENT_NEST;
					continue;
				} else if (src[1] == '/') {
					src = src[2..$];
					state = PPState.COMMENT_LINE;
					continue;
				}
			} else if (src[0] == '#') {
				src = src[1..$];
				state = PPState.HASH;
				continue;
			} else if (src[0] == '"') {
				state = PPState.STRING;
			} else if (src[0] == '\'') {
				state = PPState.CHAR;
			}
		} else if (state == PPState.COMMENT_BLOCK) {
			if (src[0] == '*' && src.length >= 2 && src[1] == '/') {
				src = src[2..$];
				state = PPState.DEFAULT;
				continue;
			} else {
				src = src[1..$];
				continue;
			}
		} else if (state == PPState.COMMENT_NEST) {
			if (src[0] == '+' && src.length >= 2 && src[1] == '/') {
				if (--level == 0) {
					state = PPState.DEFAULT;
				}
				src = src[2..$];
				continue;
			} else if (src[0] == '/' && src.length >= 2 && src[1] == '+') {
				++level;
				src = src[2..$];
				continue;
			} else {
				src = src[1..$];
				continue;
			}
		} else if (state == PPState.COMMENT_LINE) {
			if (src[0] == '\n' || src[0] == '\r') {
				state = PPState.DEFAULT;
			} else {
				src = src[1..$];
				continue;
			}
		} else if (state == PPState.HASH) {
			if (src.length >= 8 && src[0..8] == "include ") {
				src = src[8..$];
				state = PPState.INCLUDE;
				continue;
			} else {
				stderr.write("[preproc|error] bad preprocessor directive\n");
			}
		} else if (state == PPState.INCLUDE) {
			if (src[0] == ' ' || src[0] == '\t') {
				src = src[1..$];
				continue;
			} else if (src[0] == '"') {
				src = src[1..$];
				state = PPState.INCLUDE_STR;
				continue;
			} else {
				stderr.write("[preproc|error] unexpected character in " ~
					"#include directive\n");
				exit(1);
			}
		} else if (state == PPState.INCLUDE_STR) {
			if (src[0] == '"') {
				/* TODO: include file with name contained in buffer */
				buffer.length = 0;
				src = src[1..$];
				state = PPState.PPEND;
				continue;
			} else {
				buffer ~= src[0];
				src = src[1..$];
				continue;
			}
		} else if (state == PPState.PPEND) {
			if (src[0] == ' ' || src[0] == '\t') {
				src = src[1..$];
				continue;
			} else if (src[0] == '\n' || src[0] == '\r') {
				state = PPState.DEFAULT;
			} else {
				stderr.write("[preproc|error] unexpected character after " ~
					"preprocessor directive\n");
				exit(1);
			}
		} else if (state == PPState.STRING) {
			if (src[0] == '\\') {
				if (src.length >= 2) {
					src = src[1..$];
				} else {
					stderr.write("[preproc|error] " ~
						"incomplete escape sequence\n");
				}
			} else if (src[0] == '"') {
				state = PPState.DEFAULT;
			}
		} else if (state == PPState.CHAR) {
			if (src[0] == '\\') {
				if (src.length >= 2) {
					src = src[1..$];
				} else {
					stderr.write("[preproc|error] " ~
						"incomplete escape sequence\n");
				}
			} else if (src[0] == '\'') {
				state = PPState.DEFAULT;
			}
		} else {
			assert(0);
		}
		
		outBuf ~= src[0];
		src = src[1..$];
	}
	
	if (state == PPState.COMMENT_BLOCK) {
		stderr.write("[preproc|error] unterminated comment block at EOF\n");
		exit(1);
	}
	
	processed = cast(string)outBuf;
}
