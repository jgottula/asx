/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module expression;

import std.container;
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

public class EvalException : Exception {
	this(Token token) {
		super("");
		this.token = token;
	}
	
	Token token;
}
public class EvalNotImplementedException : EvalException {
	this(Token token) {
		super(token);
	}
}
public class EvalSymNotFoundException : EvalException {
	this(Token token) {
		super(token);
	}
}
public class EvalNoLHSException : EvalException {
	this(Token token) {
		super(token);
	}
}
public class EvalNoRHSException : EvalException {
	this(Token token) {
		super(token);
	}
}
public class EvalUnexpectedLHSException : EvalException {
	this(Token token) {
		super(token);
	}
}
public class EvalUnexpectedRHSException : EvalException {
	this(Token token) {
		super(token);
	}
}
public class EvalConsecutiveIntegerException : EvalException {
	this(Token token) {
		super(token);
	}
}

public class Expression {
	this(Token[] inTokens, ulong level = 0) {
		for (ulong i = 0; i < inTokens.length; ++i) {
			auto token = inTokens[i];
			
			final switch (token.type) {
			case TokenType.PAREN_L:
				auto t = Token(TokenType.EXPRESSION, token.origin);
				auto subExpr = new Expression(inTokens[i+1..$], level + 1);
				t.tagExpr = &subExpr;
				
				tokens ~= t;
				i += t.tagExpr.length;
				continue;
			case TokenType.PAREN_R:
				if (tokens.length == 0) {
					throw new ExprEmptyParenException(token.origin);
				} else if (level == 0) {
					throw new ExprUnmatchedParenRException(token.origin);
				}
				
				length = i + 1;
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
				tokens ~= token;
				break;
			case TokenType.DIRECTIVE:
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
		if (tokens.length == 0) {
			throw new ExprEmptyException(tokens[0].origin);
		} else if (level != 0) {
			throw new ExprUnmatchedParenLException(tokens[$-1].origin);
		}
	}
	
	Integer evalNoLabels(in SymbolTable symTable) {
		/* replace Expressions with Integers by evaluating them recursively;
		 * also, replace identifiers with Integers if they exist */
		foreach (ref token; tokens) {
			if (token.type == TokenType.EXPRESSION) {
				auto newToken = Token(TokenType.INTEGER,
					token.tagExpr.tokens[0].origin);
				newToken.tagInt = token.tagExpr.evalNoLabels(symTable);
				
				token = newToken;
			} else if (token.type == TokenType.IDENTIFIER) {
				const(Integer)* symValue = token.tagStr in symTable.symbols;
				
				if (symValue == null) {
					throw new EvalSymNotFoundException(token);
				}
				
				auto newToken = Token(TokenType.INTEGER, token.origin);
				newToken.tagInt = *symValue;
				
				token = newToken;
			}
		}
		
		for (ulong i = 0; i < tokens.length; ++i) {
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
					throw new EvalNotImplementedException(token);
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
		
		/* DEBUG */
		foreach (token; tokens) {
			string tag;
			
			switch (token.type) {
			case TokenType.INTEGER:
				tag = token.tagInt.to!string();
				break;
			default:
				writeln("warning, not an INTEGER");
				continue;
			}
			
			writefln("%3d:%-3d %s [%s] @ %s", token.origin.line,
				token.origin.col, token.type, tag, token.origin.file);
		}
		
		
		return Integer();
	}
	
	ulong length;
	
private:
	Token[] tokens;
}

import std.conv;
import std.stdio;

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
