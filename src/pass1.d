/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module pass1;

import std.c.stdlib;
import std.container;
import std.conv;
import std.stdio;
import std.string;
import instruction;
import pass0;


/* pass1: directives, macros, symbols, label addresses */


public enum Section {
	TEXT,
}

public struct Location {
	Section section;
	ulong offset;
}

public enum Sign {
	POSITIVE,
	NEGATIVE,
}

public struct Expression {
	bool sign;
	ulong value;
}

public enum LineType {
	DATA,
	INSTR,
}

public struct AnnotatedLine {
	LineType type;
	Location loc;
	
	union {
		Expression value;
		Instruction instr;
	}
}

private class AsmContext {
	this() {
		line = 0;
		
		section = Section.TEXT;
		offset = 0;
	}
	
	Line getLine() {
		return lines[line];
	}
	
	bool nextLine() {
		if (line + 1 < lines.length) {
			++line;
			return true;
		} else {
			return false;
		}
	}
	
	Location[string] labels;
	Expression[string] symbols;
	
private:
	ulong line;
	Line[] lines;
	Section section;
	ulong offset;
}

AsmContext ctx;


private void error(in TokenLocation l, in string msg) {
	stderr.writefln("[pass1|error|%d:%d] %s", l.line, l.col, msg);
	exit(1);
}

private void warn(in TokenLocation l, in string msg) {
	stderr.writefln("[pass1|warn|%d:%d] %s", l.line, l.col, msg);
}

private Expression addExprs(Expression a, Expression b) {
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

private Expression subExpr(DList!Token tokens) {
	bool init = false;
	Expression expr;
	
	// scan once for each operator precedence class, in the appropriate direc.
	// when an operator is found, check for operand on either side
	// (error if not found) and then replace the three relevant tokens
	// with a TokenType.EXPRESSION containing the result
	
	//foreach (
	
	return expr;
}

private Expression evalExpr(Token[] tokens) {
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
			/* halt evaluation: check if the paren stack has one member only */
			/* then, run subExpr on the last stack member */
		}
	}
	
	return expr;
}

private void directiveByte() {
	Token[] tokens = ctx.getLine().tokens[1..$];
	
	/* TODO: handle expressions; have optional param for quantity */
	
	// call evalExpr
	
	// check next token: comma is fine, that means optional param
	// otherwise, there should be no others
	
	// if we have a comma, call evalExpr again
	// then ensure that no tokens follow that
	
	// having obtained the value and the quantity (if any),
	// now 
}

AnnotatedLine[] doPass1(in Line[] lines) {
	ctx = new AsmContext();
	
lineLoop:
	do {
		Line line = ctx.getLine();
		
		if (line.tokens.length == 0) {
			continue;
		}
		
		Token token = line.tokens[0];
		
		/* errors should read like: "expected ___ after ___"
		 * or "unexpected ___ after|before ___" */
		
		final switch (token.type) {
		case TokenType.DIRECTIVE:
			switch (token.tagStr) {
			case ".byte":
				directiveByte();
				break;
			default:
				/+error(token.origin,
					"unknown directive '%s'".format(token.tagStr));+/
				warn(token.origin,
					"TODO: directive '%s'".format(token.tagStr));
				break;
			}
			break;
		case TokenType.LABEL:
			
			break;
		case TokenType.IDENTIFIER:
		case TokenType.REGISTER:
		case TokenType.LITERAL_STR:
		case TokenType.LITERAL_INT:
		case TokenType.COMMA:
		case TokenType.BRACKET_L:
		case TokenType.BRACKET_R:
		case TokenType.PAREN_L:
		case TokenType.PAREN_R:
		case TokenType.ADD:
		case TokenType.SUBTRACT:
		case TokenType.MULTIPLY:
		case TokenType.DIVIDE:
		case TokenType.MODULO:
		case TokenType.EXPRESSION:
			error(token.origin, "unexpected %s at start of line".format(
				token.type.to!string()));
			break;
		}
	} while (ctx.nextLine());
	
	assert(0);
}
