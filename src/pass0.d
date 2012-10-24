/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module pass0;

import std.ascii;
import std.c.stdlib;
import std.stdio;
import std.string;
import escape;
import input;
import newline;


/* pass0: src -> src (comments, includes, defs, ifs, macros) */


private enum State {
	DEFAULT,
	COMMENT_BLOCK,
	COMMENT_NEST,
	COMMENT_LINE,
	DIR_INCLUDE,
	DIR_INCLUDE_STR,
	DIR_INCLUDE_DONE,
}

private class Context {
	this(in string src) {
		this.src = src;
		this.dst = new char[0];
		
		this.state = State.DEFAULT;
		
		this.line = 1;
		this.col = 1;
		
		this.buffer = new char[0];
		
		this.commentLevel = 0;
	}
	
	ulong avail() {
		return src.length;
	}
	
	bool check(in string s, bool caseSensitive = true) {
		assert(s.length != 0);
		if (s.length > src.length) {
			return false;
		}
		
		if (caseSensitive) {
			return (s == src[0..(s.length)]);
		} else {
			return (s.toLower() == src[0..(s.length)].toLower());
		}
	}
	bool check(in char c, bool caseSensitive = true) {
		if (src.length < 1) {
			return false;
		}
		
		if (caseSensitive) {
			return (c == src[0]);
		} else {
			return (c.toLower() == src[0].toLower());
		}
	}
	
	bool white(ulong count = 1) {
		assert(count != 0);
		if (count > src.length) {
			return false;
		}
		
		while (count-- != 0) {
			if (src[count] != ' ' && src[count] != '\t') {
				return false;
			}
		}
		
		return true;
	}
	
	bool eof() {
		return (src.length == 0);
	}
	
	char get() {
		assert(src.length >= 1);
		return src[0];
	}
	string get(in ulong count) {
		assert(count <= src.length);
		return src[0..count];
	}
	
	/* TODO: upon append, annotate with the src line/col (and filename) so that
	 * later steps may have proper line/col */
	void put(in string buf) {
		assert(buf.length != 0);
		dst ~= buf;
	}
	void put(in char c) {
		dst ~= c;
	}
	
	void push(ulong count = 1) {
		assert(count != 0);
		assert(count <= src.length);
		
		buffer ~= src[0..count];
		advance(count);
	}
	
	void echo(ulong count = 1) {
		assert(count != 0);
		assert(count <= src.length);
		
		put(src[0..count]);
		advance(count);
	}
	
	void advance(ulong count = 1) {
		assert(count != 0);
		assert(count <= src.length);
		
		++col; // todo: line
		
		src = src[count..$];
	}
	
	void insert(in string ins) {
		src = ins ~ src;
	}
	
	string finished() {
		return cast(string)dst;
	}
	
	State state;
	
	ulong line;
	ulong col;
	
	char[] buffer;
	
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
private void errorChar(in string msg) {
	char c = ctx.get();
	
	if (isEscape(c)) {
		error(msg.format(escapize(c)));
	} else if (c.isPrintable()) {
		error(msg.format(c));
	} else {
		error(msg.format("???"));
	}
}

private void warn(in string msg) {
	stderr.writefln("[pass0|warn|%d:%d] %s", ctx.line, ctx.col, msg);
}
private void warnChar(in string msg) {
	char c = ctx.get();
	
	if (isEscape(c)) {
		warn(msg.format(escapize(c)));
	} else if (c.isPrintable()) {
		warn(msg.format(c));
	} else {
		warn(msg.format("???"));
	}
}


private void include() {
	/* TODO: provide a mechanism whereby the include file's line/col information
	 * can be preserved */
	
	string incSource = readSource(cast(string)ctx.buffer);
	fixNewlines(incSource);
	
	ctx.insert(incSource);
}

void doPass0(ref string src) {
	ctx = new Context(src);
	
	while (ctx.avail() > 0) {
		final switch (ctx.state) {
		case State.DEFAULT:
			if (ctx.check("/*")) {
				ctx.state = State.COMMENT_BLOCK;
				ctx.advance(2);
			} else if (ctx.check("/+")) {
				ctx.state = State.COMMENT_NEST;
				ctx.commentLevel = 1;
				ctx.advance(2);
			} else if (ctx.check("//")) {
				ctx.state = State.COMMENT_LINE;
				ctx.advance(2);
			} else if (ctx.check(".include")) {
				ctx.state = State.DIR_INCLUDE;
				ctx.advance(8);
			} else {
				ctx.echo();
			}
			break;
		case State.COMMENT_BLOCK:
			if (ctx.check("*/")) {
				ctx.state = State.DEFAULT;
				ctx.advance(2);
			} else {
				if (ctx.check('\n')) {
					ctx.echo();
				}
				ctx.advance();
			}
			break;
		case State.COMMENT_NEST:
			if (ctx.check("/+")) {
				++ctx.commentLevel;
				ctx.advance(2);
			} else if (ctx.check("+/")) {
				if (--ctx.commentLevel == 0) {
					ctx.state = State.DEFAULT;
				}
				ctx.advance(2);
			} else {
				if (ctx.check('\n')) {
					ctx.echo();
				}
				ctx.advance();
			}
			break;
		case State.COMMENT_LINE:
			if (ctx.check('\n')) {
				ctx.state = State.DEFAULT;
				ctx.echo();
			} else {
				ctx.advance();
			}
			break;
		case State.DIR_INCLUDE:
			if (ctx.white()) {
				ctx.advance();
			} else if (ctx.check('"')) {
				ctx.state = State.DIR_INCLUDE_STR;
				ctx.buffer.length = 0;
				ctx.advance();
			} else {
				errorChar("unexpected character in .include directive: '%s'");
			}
			break;
		case State.DIR_INCLUDE_STR:
			if (ctx.check('"')) {
				ctx.state = State.DIR_INCLUDE_DONE;
				ctx.advance();
			} else if (ctx.check('\n')) {
				errorChar("unexpected newline in .include directive");
			} else {
				ctx.push();
			}
			break;
		case State.DIR_INCLUDE_DONE:
			if (ctx.white()) {
				ctx.echo();
			} else if (ctx.check('\n')) {
				ctx.state = State.DEFAULT;
				ctx.advance();
				include();
			} else {
				errorChar("unexpected character after directive: '%s'");
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
	case State.DIR_INCLUDE:
	case State.DIR_INCLUDE_STR:
	case State.DIR_INCLUDE_DONE:
		error("unfinished .include directive at EOF");
		break;
	}
	
	src = ctx.finished();
}
