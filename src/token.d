/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module token;

import expression;


public enum TokenType {
	IDENTIFIER,
	DIRECTIVE,
	LABEL,
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
		Integer tagInt;
		Expression *tagExpr;
	}
}
