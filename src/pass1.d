/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module pass1;

import std.c.stdlib;
import std.conv;
import std.stdio;
import std.string;
import expression;
import instruction;
import pass0;
import table;


/* pass1: symbol table, label addrs, expression loading, some directives */


public enum Section {
	TEXT,
}

public struct Location {
	Section section;
	ulong offset;
}

public enum StatementType {
	DATA,
	DIRECTIVE,
}

/+public enum DirectiveType {
	
}+/

public struct DataStatement {
	byte[] bytes;
}

/+public struct DirectiveStatement {
	DirectiveType type;
	
	union {
		
	}
}+/

public struct Statement {
	StatementType type;
	Location loc;
	TokenLocation origin;
	
	union {
		DataStatement data;
		/+DirectiveStatement dir;+/
	}
}

private class Context {
	this(Line[] lines) {
		this.lines = lines;
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
	
	void addStatement(Statement s) {
		statements ~= s;
	}
	
	Statement[] getStatements() {
		return statements;
	}
	
	SymbolTable symTable;
	Location[string] labels;
	
private:
	ulong line;
	Line[] lines;
	Section section;
	ulong offset;
	Statement[] statements;
}

Context ctx;


private void error(in TokenLocation l, in string msg) {
	stderr.writefln("[pass1|error|%d:%d] %s", l.line, l.col, msg);
	exit(1);
}

private void warn(in TokenLocation l, in string msg) {
	stderr.writefln("[pass1|warn|%d:%d] %s", l.line, l.col, msg);
}

private Token[] getExpr(Token[] tokens, out Expression expr) {
	try {
		expr = new Expression(tokens);
	} catch (ExprEmptyException e) {
		error(e.origin, "empty expression");
	} catch (ExprEmptyParenException e) {
		error(e.origin, "empty parentheses");
	} catch (ExprUnmatchedParenLException e) {
		error(e.origin, "unmatched '('");
	} catch (ExprUnmatchedParenRException e) {
		error(e.origin, "unmatched ')'");
	} catch (ExprException e) {
		error(e.origin, "unspecified expression error");
	}
	
	/* tokens AFTER the expression */
	return tokens[expr.length..$];
}

private Integer evalExprNoLabels(Expression expr) {
	try {
		return expr.evalNoLabels(ctx.symTable);
	} catch (EvalException e) {
		error(e.token.origin, "unspecified expression evaluation error");
	} /* TODO: ensure that all exception types are here */
	/* use e.token.type for better messages */
	
	return Integer(Sign.POSITIVE, 0);
}

private void directiveByte() {
	Token[] tokens = ctx.getLine().tokens;
	bool hasQuantity = false;
	
	if (tokens.length == 1) {
		error(tokens[0].origin, "expected value parameter for .byte directive");
	}
	
	Expression exprValue, exprQuantity;
	Integer intValue, intQuantity;
	TokenLocation locValue, locQuantity;
	
	Token[] tokValue = tokens[1..$];
	Token[] tokPostValue = getExpr(tokValue, exprValue);
	locValue = tokValue[0].origin;
	
	if (tokPostValue.length > 0) {
		if (tokPostValue[0].type == TokenType.COMMA) {
			Token[] tokQuantity = tokPostValue[1..$];
			
			if (tokQuantity.length > 0) {
				hasQuantity = true;
				Token[] tokPostQuantity = getExpr(tokQuantity, exprQuantity);
				locQuantity = tokQuantity[0].origin;
				
				if (tokPostQuantity.length > 0) {
					error(tokPostQuantity[0].origin,
						"unexpected %s after .byte directive".format(
						tokPostQuantity[0].type.to!string()));
				}
			} else {
				error(tokPostValue[0].origin,
					"expected quantity parameter for .byte directive");
			}
		} else {
			error(tokPostValue[0].origin,
				"unexpected %s in .byte directive".format(
				tokPostValue[0].type.to!string()));
		}
	}
	
	intValue = evalExprNoLabels(exprValue);
	
	if (intValue.sign != Sign.POSITIVE) {
		error(locValue, "value for .byte cannot be negative");
	} else if (intValue.value > byte.max) {
		error(locValue, "value for .byte must be in the range [%d,%d]".format(
			byte.min, byte.max));
	}
	
	byte value = cast(byte)intValue.value;
	ulong quantity = 1;
	
	if (hasQuantity) {
		intQuantity = evalExprNoLabels(exprQuantity);
		
		if (intQuantity.sign != Sign.POSITIVE) {
			error(locValue, "quantity for .byte cannot be negative");
		} else if (intQuantity.value == 0) {
			error(locValue, "quantity for .byte cannot be zero");
		}
		
		quantity = intQuantity.value;
	}
	
	stderr.writefln(".byte: %x [%d]", value, quantity);
	
	auto data = new byte[quantity];
	
	auto st = Statement(StatementType.DATA, Location(ctx.section, ctx.offset),
		tokens[0].origin);
	st.data = DataStatement(data);
	
	ctx.addStatement(st);
	ctx.offset += quantity;
}

Statement[] doPass1(Line[] lines) {
	ctx = new Context(lines);
	
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
		case TokenType.IDENTIFIER:
			// check if this is a mneumonic
			// otherwise, goto case invalid
			break;
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
		case TokenType.REGISTER:
		case TokenType.INTEGER:
		case TokenType.STRING:
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
	
	return ctx.getStatements();
}
