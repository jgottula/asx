/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module token;

import expression;


/* in approximate order of precedence, where appropriate */
public enum TokenType {
	IDENTIFIER,
	LABEL,
	DIRECTIVE,
	
	STRING,
	INTEGER,
	
	BRACKET_L,
	BRACKET_R,
	
	PAREN_L,
	PAREN_R,
	
	/+BANG,
	NEGATE,+/
	
	MULTIPLY,
	DIVIDE,
	MODULO,
	
	ADD,
	SUBTRACT,
	
	/+SHIFT_L,
	SHIFT_R,
	
	INEQUAL_LT,
	INEQUAL_GT,
	INEQUAL_LE,
	INEQUAL_GE,
	
	EQUAL,
	NOT_EQUAL,
	
	BITWISE_AND,
	
	BITWISE_XOR,
	
	BITWISE_OR,
	
	LOGICAL_AND,
	
	LOGICAL_OR,+/
	
	COMMA,
	
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
