/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module pass0;

import std.c.stdlib;
import std.stdio;


/* pass0: src -> src (comments, includes, defs, ifs, macros) */


private enum State {
	DEFAULT,
	COMMENT_BLOCK,
	COMMENT_NEST,
	COMMENT_LINE,
}

private class Context {
	this(in string src) {
		this.src = src;
		this.dst = new char[0];
		
		this.state = State.DEFAULT;
		
		this.line = 1;
		this.col = 1;
		
		this.commentLevel = 0;
	}
	
	ulong avail() {
		return src.length;
	}
	
	char get() {
		assert(src.length >= 1);
		return src[0];
	}
	string get(in ulong count) {
		assert(count <= src.length);
		return src[0..count];
	}
	
	void put(in string buf) {
		dst ~= buf;
	}
	void put(in char c) {
		dst ~= c;
	}
	
	void echo(in ulong count = 1) {
		assert(count <= src.length);
		
		put(src[0..count]);
		advance(count);
	}
	
	void advance(in ulong count = 1) {
		assert(count <= src.length);
		
		++col; // todo: line
		
		src = src[count..$];
	}
	
	string finished() {
		return cast(string)dst;
	}
	
	State state;
	
	ulong line;
	ulong col;
	
	ulong commentLevel;
	
private:
	
	string src;
	char[] dst;
}

Context ctx;


private void error(in string msg) {
	stderr.writefln("[pass0|error|%d:%d] %s", ctx.line, ctx.col, msg);
	exit(1);
}

private void warn(in string msg) {
	stderr.writefln("[pass0|warn|%d:%d] %s", ctx.line, ctx.col, msg);
}

private void putCommentChar() {
	if (ctx.get() == '\n') {
		ctx.echo();
	}
	ctx.advance();
}

void doPass0(ref string src) {
	ctx = new Context(src);
	
	while (ctx.avail() > 0) {
		final switch (ctx.state) {
		case State.DEFAULT:
			if (ctx.avail() >= 2 && ctx.get(2) == "/*") {
				ctx.state = State.COMMENT_BLOCK;
				ctx.advance(2);
			} else if (ctx.avail() >= 2 && ctx.get(2) == "/+") {
				ctx.state = State.COMMENT_NEST;
				ctx.commentLevel = 1;
				ctx.advance(2);
			} else if (ctx.avail() >= 2 && ctx.get(2) == "//") {
				ctx.state = State.COMMENT_LINE;
				ctx.advance(2);
			} else {
				ctx.echo();
			}
			break;
		case State.COMMENT_BLOCK:
			if (ctx.avail() >= 2 && ctx.get(2) == "*/") {
				ctx.state = State.DEFAULT;
				ctx.advance(2);
			} else {
				putCommentChar();
			}
			break;
		case State.COMMENT_NEST:
			if (ctx.avail() >= 2 && ctx.get(2) == "/+") {
				++ctx.commentLevel;
				ctx.advance(2);
			} else if (ctx.avail() >= 2 && ctx.get(2) == "+/") {
				if (--ctx.commentLevel == 0) {
					ctx.state = State.DEFAULT;
				}
				ctx.advance(2);
			} else {
				putCommentChar();
			}
			break;
		case State.COMMENT_LINE:
			if (ctx.get() == '\n') {
				ctx.state = State.DEFAULT;
				ctx.echo();
			} else {
				ctx.advance();
			}
			break;
		}
	}
	
	/* check for bad EOF states */
	final switch (ctx.state) {
	case State.DEFAULT:
	case State.COMMENT_LINE:
		/* okay */
		break;
	case State.COMMENT_BLOCK:
		error("unterminated block comment at EOF");
		break;
	case State.COMMENT_NEST:
		error("unterminated nest comment at EOF");
		break;
	}
	
	src = ctx.finished();
}
