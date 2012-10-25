/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module expression;

import std.container;
/* vvv remove me vvv*/
import std.conv;
import std.stdio;
/* ^^^ remove me ^^^ */
import pass0;
import pass1;
import table;


public enum Sign {
	POSITIVE,
	NEGATIVE,
}

public struct Integer {
	bool sign;
	ulong value;
	
	Integer add(Integer x) {
		if (this.sign == x.sign) {
			return Integer(this.sign, this.value + x.value);
		} else if (this.value > x.value) {
			return Integer(this.sign, this.value - x.value);
		} else if (this.value < x.value) {
			return Integer(x.sign, x.value - this.value);
		} else {
			/* zero will always be positive */
			return Integer(Sign.POSITIVE, 0);
		}
	}
}

public class ExprException : Exception {
	this(TokenLocation origin) {
		super("");
		this.origin = origin;
	}
	
	TokenLocation origin;
}
public class ExprEmptyException : ExprException {
	this(TokenLocation origin) {
		super(origin);
	}
}
public class ExprEmptyParenException : ExprException {
	this(TokenLocation origin) {
		super(origin);
	}
}
public class ExprUnmatchedParenLException : ExprException {
	this(TokenLocation origin) {
		super(origin);
	}
}
public class ExprUnmatchedParenRException : ExprException {
	this(TokenLocation origin) {
		super(origin);
	}
}

public class ExprEvalException : ExprException {
	this(TokenLocation origin) {
		super(origin);
	}
}

public class Expression {
	this(Token[] tokens, ulong level = 0) {
		list = DList!Token(new Token[0]);
		
		for (ulong i = 0; i < tokens.length; ++i) {
			auto token = tokens[i];
			
			final switch (token.type) {
			case TokenType.PAREN_L:
				auto t = Token(TokenType.EXPRESSION, token.origin);
				auto subExpr = new Expression(tokens[i+1..$], level + 1);
				t.tagExpr = &subExpr;
				
				list.insertBack(t);
				i += t.tagExpr.length;
				continue;
			case TokenType.PAREN_R:
				if (list.empty()) {
					throw new ExprEmptyParenException(token.origin);
				} else if (level == 0) {
					throw new ExprUnmatchedParenRException(token.origin);
				}
				
				length = i + 1;
				return;
			case TokenType.IDENTIFIER:
			case TokenType.INTEGER:
			case TokenType.ADD:
			case TokenType.SUBTRACT:
			case TokenType.MULTIPLY:
			case TokenType.DIVIDE:
			case TokenType.MODULO:
			case TokenType.EXPRESSION:
				list.insertBack(token);
				break;
			case TokenType.DIRECTIVE:
			case TokenType.LABEL:
			case TokenType.REGISTER:
			case TokenType.STRING:
			case TokenType.COMMA:
			case TokenType.BRACKET_L:
			case TokenType.BRACKET_R:
				length = i;
				goto done;
			}
		}
		
		length = tokens.length;
		
	done:
		if (list.empty()) {
			throw new ExprEmptyException(tokens[0].origin);
		} else if (level != 0) {
			throw new ExprUnmatchedParenLException(tokens[$-1].origin);
		}
		
	}
	
	Integer evalNoLabels(in SymbolTable symTable) {
		/* replace Expressions with Integers by evaluating them recursively */
		foreach (ref token; list) {
			if (token.type == TokenType.EXPRESSION) {
				auto newToken = Token(TokenType.INTEGER,
					token.tagExpr.list.front().origin);
				newToken.tagInt = token.tagExpr.evalNoLabels(symTable);
				
				token = newToken;
			}
		}
		
		foreach (token; list) {
			string tag;
			
			switch (token.type) {
			case TokenType.INTEGER:
				tag = token.tagInt.to!string();
				break;
			case TokenType.REGISTER:
				tag = token.tagReg.to!string();
				break;
			default:
				tag = token.tagStr;
			}
			
			writefln("%3d:%-3d %s [%s] @ %s", token.origin.line,
				token.origin.col, token.type, tag, token.origin.file);
		}
		
		
		return Integer();
	}
	
	ulong length;
	
private:
	DList!Token list;
}

/+
private Expression subExpr(ref DList!Token tokens) {
	bool init = false;
	Expression expr;
	
	// scan once for each operator precedence class, in the appropriate direc.
	// when an operator is found, check for operand on either side
	// (error if not found) and then replace the three relevant tokens
	// with a TokenType.EXPRESSION containing the result
	
	// for operands of type IDENTIFIER, look up their Expression value in the
	// symbol table; complain if they are absent
	
	//foreach (
	
	return expr;
}+/
