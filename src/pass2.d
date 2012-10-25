/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module pass2;

import pass1;


/* pass2: section output, code gen */


/+private Expression addExprs(in Expression a, in Expression b) {
	if (a.sign == b.sign) {
		return Expression(a.sign, a.value + b.value);
	} else if (a.value >= b.value) {
		return Expression(a.sign, a.value - b.value);
	} else if (a.value < b.value) {
		return Expression(b.sign, b.value - a.value);
	} else {
		/* ensures that zero is always positive */
		return Expression(Sign.POSITIVE, 0);
	}
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
}

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
}+/

void doPass2(in Statement[] statements) {
	
}
