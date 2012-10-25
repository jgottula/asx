/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module expression;

import std.container;
import pass0;
import pass1;


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
			case TokenType.LITERAL_INT:
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
			case TokenType.LITERAL_STR:
			case TokenType.COMMA:
			case TokenType.BRACKET_L:
			case TokenType.BRACKET_R:
				length = i + 1;
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
	
	Integer evaluate(in Integer[string] symbols) {
		return Integer(Sign.POSITIVE, 0);
	}
	
	ulong length;
	
private:
	Integer subEval(in Integer[string] symbols) {
		return Integer(Sign.POSITIVE, 0);
	}
	
	DList!Token list;
}

/+

private Expression evalExpr(in Token[] tokens) {
	auto expr = Expression(Sign.POSITIVE, 0);
	DList!Token[] parenStack = [DList!Token(new Token[0])];
	
	foreach (token; tokens) {
		switch (token.type) {
		case TokenType.PAREN_L:
			parenStack ~= DList!Token(new Token[0]);
			break;
		case TokenType.PAREN_R:
			if (parenStack[$-1].empty()) {
				error(token.origin, "empty parentheses");
			} else {
				if (parenStack.length == 1) {
					error(token.origin, "unmatched close parenthesis");
				}
				
				auto sub = subExpr(parenStack[$-1]);
				
				--parenStack.length;
				
				auto t = Token(TokenType.EXPRESSION,
					TokenLocation("null", 0, 0));
				t.tagExpr = sub;
				parenStack[$-1].insertBack(t);
			}
			break;
		case TokenType.IDENTIFIER:
		case TokenType.LITERAL_INT:
		case TokenType.ADD:
		case TokenType.SUBTRACT:
		case TokenType.MULTIPLY:
		case TokenType.DIVIDE:
		case TokenType.MODULO:
			parenStack[$-1].insertBack(token);
			break;
		default:
			/* check that we had at least one token previous to this */
			/* halt evaluation: check if the paren stack has one member only */
			/* then, run subExpr on the last stack member */
			/* and, remove all the tokens used in the expression */
		}
	}
	
	return expr;
}

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
