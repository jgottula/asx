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
}

public class ExprParenRException : Exception {
	this() {
		super("");
	}
}

public class Expression {
	this() {
		
	}
	
	void parse() {
		
	}
private:
	DList!Token[] stack;
}
