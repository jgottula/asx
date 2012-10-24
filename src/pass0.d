/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module pass0;

import std.ascii;
import std.c.stdlib;
import std.regex;
import std.stdio;
import std.string;
import escape;
import input;
import newline;


/* pass0: strip comments, lex */


public enum TokenType {
	IDENTIFIER,
	DIRECTIVE,
	LABEL,
	LITERAL_STR,
	LITERAL_INT,
	COMMA,
	BRACKET_L,
	BRACKET_R,
	PAREN_L,
	PAREN_R,
	ADD,
	SUBTRACT,
	MULTIPLY,
	DIVIDE,
	MODULO,
}

public struct TokenLocation {
	string file;
	ulong line, col;
}

public struct Token {
	this(TokenType type, TokenLocation origin) {
		this.type = type;
		this.origin = origin;
	}
	
	TokenType type;
	TokenLocation origin;
	union {
		string tagStr;
	}
}

public struct Line {
	Token[] tokens;
}

private enum State {
	DEFAULT,
	COMMENT_BLOCK,
	COMMENT_NEST,
	COMMENT_LINE,
	IDENTIFIER,
	DIRECTIVE,
	LITERAL_STR,
	LITERAL_INT,
}

private class Context {
	this(in string filename, in string src) {
		this.filename = filename;
		this.src = src;
		
		this.lines = new Line[1];
		
		this.state = State.DEFAULT;
		
		this.line = 1;
		this.col = 1;
		
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
	
	/+bool white(ulong count = 1) {
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
	}+/
	
	bool match(in string regex) {
		return !(src.match(regex).empty());
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
	/+void put(in string buf) {
		assert(buf.length != 0);
		dst ~= buf;
	}
	void put(in char c) {
		dst ~= c;
	}+/
	
	void push(ulong count = 1) {
		assert(count != 0);
		assert(count <= src.length);
		
		buffer ~= src[0..count];
		advance(count);
	}
	
	/+void echo(ulong count = 1) {
		assert(count != 0);
		assert(count <= src.length);
		
		put(src[0..count]);
		advance(count);
	}+/
	
	void advance(ulong count = 1) {
		assert(count != 0);
		assert(count <= src.length);
		
		for (ulong i = 0; i < count; ++i) {
			if (src[i] == '\n') {
				++line;
				col = 1;
				
				++lines.length;
			} else {
				++col;
			}
		}
		
		src = src[count..$];
	}
	
	/+void insert(in string ins) {
		src = ins ~ src;
	}
	
	string finished() {
		return cast(string)dst;
	}+/
	
	TokenLocation getLocation() {
		return TokenLocation(filename, line, col);
	}
	
	void saveLocation() {
		loc = TokenLocation(filename, line, col);
	}
	
	void addToken(in Token t) {
		lines[line - 1].tokens ~= t;
	}
	
	Line[] getLines() {
		return lines;
	}
	
	State state;
	
	string filename;
	ulong line;
	ulong col;
	
	ulong commentLevel;
	
	char[] buffer;
	TokenLocation loc;
	
private:
	string src;
	Line[] lines;
}

Context ctx;


private void error(in string msg) {
	stderr.writefln("[pass0|error|%d:%d] %s", ctx.line, ctx.col, msg);
	exit(1);
}
/+private void errorChar(in string msg) {
	char c = ctx.get();
	
	if (isEscape(c)) {
		error(msg.format(unescapize(c)));
	} else if (c.isPrintable()) {
		error(msg.format(c));
	} else {
		error(msg.format("???"));
	}
}+/

private void warn(in string msg) {
	stderr.writefln("[pass0|warn|%d:%d] %s", ctx.line, ctx.col, msg);
}
/+private void warnChar(in string msg) {
	char c = ctx.get();
	
	if (isEscape(c)) {
		warn(msg.format(unescapize(c)));
	} else if (c.isPrintable()) {
		warn(msg.format(c));
	} else {
		warn(msg.format("???"));
	}
}+/

/+private void include() {
	/* TODO: provide a mechanism whereby the include file's line/col information
	 * can be preserved */
	
	string incSource = readSource(cast(string)ctx.buffer);
	fixNewlines(incSource);
	
	ctx.insert(incSource);
}+/

Line[] doPass0(in string path, string src) {
	ctx = new Context(path, src);
	
	while (!ctx.eof()) {
		final switch (ctx.state) {
		case State.DEFAULT:
			if (ctx.check(' ') || ctx.check('\t')) {
				ctx.advance();
			} else if (ctx.check("/*")) {
				ctx.state = State.COMMENT_BLOCK;
				ctx.advance(2);
			} else if (ctx.check("/+")) {
				ctx.state = State.COMMENT_NEST;
				ctx.commentLevel = 1;
				ctx.advance(2);
			} else if (ctx.check("//")) {
				ctx.state = State.COMMENT_LINE;
				ctx.advance(2);
			} else if (ctx.match(r"^\w")) {
				ctx.state = State.IDENTIFIER;
				ctx.saveLocation();
				goto case State.IDENTIFIER;
			} else if (ctx.match(r"^\.\w")) {
				ctx.state = State.DIRECTIVE;
				ctx.saveLocation();
				ctx.push();
			} else if (ctx.check('"')) {
				ctx.state = State.LITERAL_STR;
				ctx.saveLocation();
				ctx.advance();
			} else if (ctx.check(',')) {
				ctx.addToken(Token(TokenType.COMMA, ctx.getLocation()));
				ctx.advance();
			} else if (ctx.check('[')) {
				ctx.addToken(Token(TokenType.BRACKET_L, ctx.getLocation()));
				ctx.advance();
			} else if (ctx.check(']')) {
				ctx.addToken(Token(TokenType.BRACKET_R, ctx.getLocation()));
				ctx.advance();
			} else if (ctx.check('(')) {
				ctx.addToken(Token(TokenType.PAREN_L, ctx.getLocation()));
				ctx.advance();
			} else if (ctx.check(')')) {
				ctx.addToken(Token(TokenType.PAREN_R, ctx.getLocation()));
				ctx.advance();
			} else if (ctx.check('+')) {
				ctx.addToken(Token(TokenType.ADD, ctx.getLocation()));
				ctx.advance();
			} else if (ctx.check('-')) {
				ctx.addToken(Token(TokenType.SUBTRACT, ctx.getLocation()));
				ctx.advance();
			} else if (ctx.check('*')) {
				ctx.addToken(Token(TokenType.MULTIPLY, ctx.getLocation()));
				ctx.advance();
			} else if (ctx.check('/')) {
				ctx.addToken(Token(TokenType.DIVIDE, ctx.getLocation()));
				ctx.advance();
			} else if (ctx.check('%')) {
				ctx.addToken(Token(TokenType.MODULO, ctx.getLocation()));
				ctx.advance();
			} else if (ctx.check('\n')) {
				ctx.advance();
			} else {
				error("FATAL: unhandled char: '%s'".format(ctx.get()));
			}
			break;
		case State.COMMENT_BLOCK:
			if (ctx.check("*/")) {
				ctx.state = State.DEFAULT;
				ctx.advance(2);
			} else {
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
				ctx.advance();
			}
			break;
		case State.COMMENT_LINE:
			if (ctx.check('\n')) {
				ctx.state = State.DEFAULT;
			}
			ctx.advance;
			break;
		case State.IDENTIFIER:
			if (ctx.match(r"^\w")) {
				ctx.push();
			} else if (ctx.check(':')) {
				auto token = Token(TokenType.LABEL, ctx.loc);
				token.tagStr = ctx.buffer.idup;
				
				ctx.addToken(token);
				ctx.buffer.length = 0;
				
				ctx.state = State.DEFAULT;
				ctx.advance();
			} else {
				auto token = Token(TokenType.IDENTIFIER, ctx.loc);
				token.tagStr = ctx.buffer.idup;
				
				ctx.addToken(token);
				ctx.buffer.length = 0;
				
				ctx.state = State.DEFAULT;
				goto case State.DEFAULT;
			}
			break;
		case State.DIRECTIVE:
			if (ctx.match(r"^\w")) {
				ctx.push();
			} else {
				auto token = Token(TokenType.DIRECTIVE, ctx.loc);
				token.tagStr = ctx.buffer.idup;
				
				ctx.addToken(token);
				ctx.buffer.length = 0;
				
				ctx.state = State.DEFAULT;
				goto case State.DEFAULT;
			}
			break;
		case State.LITERAL_STR:
			if (ctx.check('\\')) {
				if (isEscapeStr(ctx.get(2))) {
					ctx.buffer ~= escapize(ctx.get(2));
					ctx.advance(2);
				} else {
					error("invalid escape sequence");
				}
			} else if (ctx.check('"')) {
				auto token = Token(TokenType.LITERAL_STR, ctx.loc);
				token.tagStr = ctx.buffer.idup;
				
				ctx.addToken(token);
				ctx.buffer.length = 0;
				
				ctx.state = State.DEFAULT;
				ctx.advance();
			} else {
				ctx.push();
			}
			break;
		case State.LITERAL_INT:
			/* ... */
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
	case State.LITERAL_STR:
		error("unterminated string literal at EOF");
		break;
		/* the source file is guaranteed to end with a newline, so the following
		 * cases should never happen */
	case State.IDENTIFIER:
		assert(0);
	case State.DIRECTIVE:
		assert(0);
	case State.LITERAL_INT:
		assert(0);
	}
	
	return ctx.getLines();
}
