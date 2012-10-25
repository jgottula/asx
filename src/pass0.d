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
import expression;
import input;
import newline;
import pass1;
import register;


/* pass0: strip comments, lex */


public enum TokenType {
	IDENTIFIER,
	DIRECTIVE,
	LABEL,
	REGISTER,
	INTEGER,
	STRING,
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
	EXPRESSION,
}

public struct TokenLocation {
	string file;
	ulong line, col;
}

public struct Token {
	this(TokenType type) {
		this.type = type;
		this.origin = TokenLocation();
	}
	this(TokenType type, TokenLocation origin) {
		this.type = type;
		this.origin = origin;
	}
	
	TokenType type;
	TokenLocation origin;
	union {
		string tagStr;
		Register tagReg;
		Integer tagInt;
		Expression *tagExpr;
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
	
	void push(ulong count = 1) {
		assert(count != 0);
		assert(count <= src.length);
		
		buffer ~= src[0..count];
		advance(count);
	}
	
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
	
	TokenLocation getLocation() {
		return TokenLocation(filename, line, col);
	}
	
	void saveLocation() {
		loc = TokenLocation(filename, line, col);
	}
	
	void addToken(Token t) {
		lines[line-1].tokens ~= t;
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

private void warn(in string msg) {
	stderr.writefln("[pass0|warn|%d:%d] %s", ctx.line, ctx.col, msg);
}

Line[] doPass0(in string path, string src) {
	ctx = new Context(path, src);
	
	while (!ctx.eof()) {
		/* specially handle line continuation character here */
		
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
			} else if (ctx.match(r"^[A-Za-z_]")) {
				ctx.state = State.IDENTIFIER;
				ctx.saveLocation();
				goto case State.IDENTIFIER;
			} else if (ctx.match(r"^\.[A-Za-z_]")) {
				ctx.state = State.DIRECTIVE;
				ctx.saveLocation();
				ctx.push();
			} else if (ctx.match(r"^[0-9]")) {
				ctx.state = State.LITERAL_INT;
				ctx.saveLocation();
				goto case State.LITERAL_INT;
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
			if (ctx.match(r"^[A-Za-z0-9_]")) {
				ctx.push();
			} else if (ctx.check(':')) {
				auto token = Token(TokenType.LABEL, ctx.loc);
				token.tagStr = ctx.buffer.idup;
				
				ctx.addToken(token);
				ctx.buffer.length = 0;
				
				ctx.state = State.DEFAULT;
				ctx.advance();
			} else if ((cast(string)ctx.buffer in regNames) != null) {
				warn("TODO: put reg recognition elsewhere");
				
				auto token = Token(TokenType.REGISTER, ctx.loc);
				token.tagReg = regNames[cast(string)ctx.buffer];
				
				ctx.addToken(token);
				ctx.buffer.length = 0;
				
				ctx.state = State.DEFAULT;
				goto case State.DEFAULT;
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
			if (ctx.match(r"^[A-Za-z0-9_]")) {
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
				auto token = Token(TokenType.STRING, ctx.loc);
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
			if (ctx.match(r"^[0-9]")) {
				ctx.push();
			} else {
				ulong x = 0;
				
				for (ulong i = 0; i < ctx.buffer.length; ++i) {
					x *= 10;
					x += ctx.buffer[i] - '0';
				}
				
				auto token = Token(TokenType.INTEGER, ctx.loc);
				token.tagInt = Integer(Sign.POSITIVE, x);
				
				ctx.addToken(token);
				ctx.buffer.length = 0;
				
				ctx.state = State.DEFAULT;
				goto case State.DEFAULT;
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
