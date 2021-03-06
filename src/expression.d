/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module expression;

import std.container;
import std.conv;
import std.string;
import pass1;
import segment;
import symbol;
import token;


public enum Sign {
	POSITIVE,
	NEGATIVE,
}

public struct Integer {
	Sign sign;
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
	
	void negate() {
		if (sign == Sign.POSITIVE) {
			sign = Sign.NEGATIVE;
		} else {
			sign = Sign.POSITIVE;
		}
	}
	
	string toString() {
		if (sign == Sign.NEGATIVE) {
			return '-' ~ value.to!string();
		} else {
			return value.to!string();
		}
	}
}

public class ExprException : Exception {
	this(const(Token) token) {
		super("");
		this.token = token;
	}
	
	const(Token) token;
}
public class ExprEmptyException : ExprException {
	this(const(Token) token) {
		super(token);
	}
}
public class ExprEmptyParenException : ExprException {
	this(const(Token) token) {
		super(token);
	}
}
public class ExprUnmatchedParenLException : ExprException {
	this(const(Token) token) {
		super(token);
	}
}
public class ExprUnmatchedParenRException : ExprException {
	this(const(Token) token) {
		super(token);
	}
}
public class ExprBadTokenException : ExprException {
	this(const(Token) token) {
		super(token);
	}
}

public class EvalException : Exception {
	this(const(Token) token) {
		super("");
		this.token = token;
	}
	
	const(Token) token;
}
public class EvalSymNotFoundException : EvalException {
	this(const(Token) token) {
		super(token);
	}
}
public class EvalNoLHSException : EvalException {
	this(const(Token) token) {
		super(token);
	}
}
public class EvalNoRHSException : EvalException {
	this(const(Token) token) {
		super(token);
	}
}
public class EvalUnexpectedLHSException : EvalException {
	this(const(Token) token) {
		super(token);
	}
}
public class EvalUnexpectedRHSException : EvalException {
	this(const(Token) token) {
		super(token);
	}
}
public class EvalConsecutiveIntegerException : EvalException {
	this(const(Token) token) {
		super(token);
	}
}

public struct Expression {
	this(in Token[] inTokens, ulong level = 0) {
		for (ulong i = 0; i < inTokens.length; ++i) {
			auto token = inTokens[i];
			
			final switch (token.type) {
			case TokenType.PAREN_L:
				auto t = Token(TokenType.EXPRESSION, token.origin);
				auto subExpr = new Expression(inTokens[i+1..$], level + 1);
				t.tagExpr = subExpr;
				
				tokens ~= t;
				
				length += subExpr.length + 1;
				i += subExpr.length;
				break;
			case TokenType.PAREN_R:
				if (tokens.length == 0) {
					throw new ExprEmptyParenException(token);
				} else if (level == 0) {
					throw new ExprUnmatchedParenRException(token);
				}
				
				++length;
				return;
			case TokenType.IDENTIFIER:
			case TokenType.INTEGER:
			case TokenType.LABEL:
			case TokenType.ADD:
			case TokenType.SUBTRACT:
			case TokenType.MULTIPLY:
			case TokenType.DIVIDE:
			case TokenType.MODULO:
			case TokenType.EXPRESSION:
				tokens ~= cast(Token)token;
				++length;
				break;
			case TokenType.COMMA:
				goto done;
			case TokenType.DIRECTIVE:
			case TokenType.STRING:
			case TokenType.BRACKET_L:
			case TokenType.BRACKET_R:
				throw new ExprBadTokenException(token);
			}
		}
		
	done:
		if (tokens.length == 0) {
			throw new ExprEmptyException(tokens[0]);
		} else if (level != 0) {
			throw new ExprUnmatchedParenLException(tokens[$-1]);
		}
	}
	
	Integer eval(in Symbol[string] symbols) {
		/* replace Expressions with Integers by evaluating them recursively;
		 * also, replace symbols with Integers if they exist */
		foreach (ref token; tokens) {
			if (token.type == TokenType.EXPRESSION) {
				auto newToken = Token(TokenType.INTEGER, token.origin);
				newToken.tagInt =
					token.tagExpr.eval(symbols);
				
				token = newToken;
			} else if (token.type == TokenType.IDENTIFIER) {
				const(Symbol)* symValue = token.tagStr in symbols;
				
				if (symValue == null) {
					throw new EvalSymNotFoundException(token);
				}
				
				auto newToken = Token(TokenType.INTEGER, token.origin);
				newToken.tagInt = Integer(Sign.POSITIVE, symValue.value);
				
				token = newToken;
			}
		}
		
		
		/* AT THIS POINT, there should only be integers and operators in the
		 * expression (no identifiers or parentheses) */
		
		
		/* evaluate unary minus (right to left) */
		for (long i = tokens.length - 2; i >= 0; --i) {
			auto token = tokens[i];
			Token* lhs = null, rhs = null;
			
			if (i > 0) {
				lhs = &tokens[i-1];
			}
			/* no need to check if rhs exists, as we accounted for it in the
			 * for loop declaration */
			rhs = &tokens[i+1];
			
			if (token.type == TokenType.SUBTRACT &&
				rhs.type == TokenType.INTEGER &&
				(lhs == null || lhs.type != TokenType.INTEGER)) {
				rhs.tagInt.negate();
				
				Token[] tokensBefore = tokens[0..i];
				Token[] tokensAfter = tokens[i+1..$];
				
				tokens = tokensBefore ~ tokensAfter;
			}
		}
		
		/* evaluate multiplications, divisions, and modulos (left to right) */
		for (long i = 0; i < tokens.length; ++i) {
			auto token = tokens[i];
			Token* lhs = null, rhs = null;
			
			if (i > 0) {
				lhs = &tokens[i-1];
			}
			if (i < tokens.length - 1) {
				rhs = &tokens[i+1];
			}
			
			if (token.type == TokenType.MULTIPLY ||
				token.type == TokenType.DIVIDE ||
				token.type == TokenType.MODULO) {
				if (lhs == null) {
					throw new EvalNoLHSException(token);
				} else if (rhs == null) {
					throw new EvalNoRHSException(token);
				}
				
				if (lhs.type != TokenType.INTEGER) {
					throw new EvalUnexpectedLHSException(*lhs);
				} else if (rhs.type != TokenType.INTEGER) {
					throw new EvalUnexpectedRHSException(*rhs);
				}
				
				Integer result;
				
				if (token.type == TokenType.MULTIPLY ||
					token.type == TokenType.DIVIDE) {
					if (lhs.tagInt.sign == rhs.tagInt.sign) {
						result.sign = Sign.POSITIVE;
					} else {
						result.sign = Sign.NEGATIVE;
					}
				} else if (token.type == TokenType.MODULO) {
					/* result has same side as divisor; see wikipedia */
					result.sign = rhs.tagInt.sign;
				} else {
					assert(0);
				}
				
				if (token.type == TokenType.MULTIPLY) {
					result.value = lhs.tagInt.value * rhs.tagInt.value;
				} else if (token.type == TokenType.DIVIDE) {
					result.value = lhs.tagInt.value / rhs.tagInt.value;
				} else if (token.type == TokenType.MODULO) {
					/* TODO: handle signs properly; see wikipedia for details */
					assert(0);
				} else {
					assert(0);
				}
				
				auto resultToken = Token(TokenType.INTEGER, token.origin);
				resultToken.tagInt = result;
				
				Token[] tokensBefore = tokens[0..i-1];
				Token[] tokensAfter = tokens[i+2..$];
				
				tokens = tokensBefore ~ resultToken ~ tokensAfter;
				
				--i;
			} else if (token.type == TokenType.INTEGER) {
				if (lhs != null && lhs.type == TokenType.INTEGER) {
					throw new EvalConsecutiveIntegerException(token);
				}
			}
		}
		
		assert(tokens.length == 1);
		assert(tokens[0].type == TokenType.INTEGER);
		
		return tokens[0].tagInt;
	}
	
	string toString() {
		char[] str;
		
		foreach (token; tokens) {
			if (token.type == TokenType.EXPRESSION) {
				str ~= "EXPRESSION(%s)".format(token.to!string());
			} else {
				str ~= "%s ".format(token.to!string());
			}
		}
		
		return cast(string)str;
	}
	
	ulong length;
	Token[] tokens;
}
