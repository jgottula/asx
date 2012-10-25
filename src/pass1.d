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


/* pass1: symbol table, label addrs, expression loading, some directives */


public enum Section {
	TEXT,
}

public struct Location {
	Section section;
	ulong offset;
}

public enum StatementType {
	DIRECTIVE,
}

public enum DirectiveType {
	BYTE,
}

public struct DataStatement {
	byte[] bytes;
}

public struct DirectiveStatement {
	DirectiveType type;
	
	union {
		
	}
}

public struct Statement {
	StatementType type;
	Location loc;
	TokenLocation origin;
	
	union {
		DataStatement data;
		DirectiveStatement dir;
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
	
	Location[string] labels;
	Integer[string] symbols;
	
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

private void directiveByte() {
	/+Token[] tokens = ctx.getLine().tokens[1..$];
	bool hasQuantity = false;
	
	if (tokens.length == 0) {
		error(ctx.getLine().tokens[0].origin,
			"expected value parameter for .byte directive");
	}
	
	TokenLocation valueLoc = tokens[0].origin;
	TokenLocation quantityLoc;
	
	Expression exprValue = evalExpr(tokens);
	Expression exprQuantity;
	
	if (tokens.length > 0) {
		if (tokens[0].type == TokenType.COMMA) {
			hasQuantity = true;
			quantityLoc = tokens[0].origin;
			
			exprQuantity = evalExpr(tokens);
			
			if (tokens.length > 0) {
				error(tokens[0].origin,
					"unexpected %s after .byte directive".format(
					tokens[0].type.to!string()));
			}
		} else {
			error(tokens[0].origin, "unexpected %s in .byte directive".format(
				tokens[0].type.to!string()));
		}
	}
	
	if (exprValue.sign != Sign.POSITIVE) {
		error(valueLoc, "value for .byte cannot be negative");
	} else if (exprValue.value > byte.max) {
		error(valueLoc, "value for .byte must be in the range [%d,%d]".format(
			byte.min, byte.max));
	}
	
	byte value = cast(byte)exprValue.value;
	ulong quantity = 1;
	
	if (hasQuantity) {
		if (exprQuantity.sign != Sign.POSITIVE) {
			error(quantityLoc, "quantity for .byte cannot be negative");
		} else if (exprQuantity.value == 0) {
			error(quantityLoc, "quantity for .byte cannot be zero");
		}
		
		quantity = exprQuantity.value;
	}
	
	auto aLine =
		AnnotatedLine(LineType.DATA, Location(ctx.section, ctx.offset));
	aLine.data.loc = ctx.getLine().tokens[0].origin;
	aLine.data.data = new byte[quantity];
	aLine.data.data[] = value;
	
	ctx.addALine(aLine);
	
	ctx.offset += quantity;+/
	
	
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
	
	return ctx.getStatements();
}
