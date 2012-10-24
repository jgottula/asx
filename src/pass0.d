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
}

private class Context {
	this(string src) {
		this.src = src;
		this.dst = new char[0];
		
		this.state = State.DEFAULT;
		
		this.line = 1;
		this.col = 1;
	}
	
	ulong avail() {
		return src.length;
	}
	
	string get(ulong count) {
		assert(count <= src.length);
		return src[0..count];
	}
	
	void put(char[] buf) {
		dst ~= buf;
	}
	void put(string buf) {
		dst ~= buf;
	}
	
	void advance(ulong count = 1) {
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
	
private:
	string src;
	char[] dst;
}


private void error(Context ctx, string msg) {
	stderr.writefln("[pass0|error|%d:%d] %s", ctx.line, ctx.col, msg);
	exit(1);
}

private void warn(Context ctx, string msg) {
	stderr.writefln("[pass0|warn|%d:%d] %s", ctx.line, ctx.col, msg);
}

void doPass0(ref string src) {
	auto ctx = new Context(src);
	
	while (ctx.avail() > 0) {
		final switch (ctx.state) {
		case State.DEFAULT:
			if (ctx.avail() >= 2 && ctx.get(2) == "/*") {
				ctx.state = State.COMMENT_BLOCK;
				ctx.put("  ");
				ctx.advance(2);
				break;
			} else {
				ctx.put(ctx.get(1));
				ctx.advance();
				break;
			}
		case State.COMMENT_BLOCK:
			if (ctx.avail() >= 2 && ctx.get(2) == "*/") {
				ctx.state = State.DEFAULT;
				ctx.put("  ");
				ctx.advance(2);
				break;
			} else {
				ctx.put(" ");
				ctx.advance();
				break;
			}
		}
	}
	
	/* check for bad EOF states */
	final switch (ctx.state) {
	case State.DEFAULT:
		/* okay */
		break;
	case State.COMMENT_BLOCK:
		error(ctx, "unterminated comment block at EOF");
		break;
	}
	
	src = ctx.finished();
}
