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
import segment;
import symbol;
import token;


/* pass1: symbols/labels, directives, evaluation (but not of instructions),
 * instruction size measurement and operand parsing */


public enum DataSize {
	BYTE,
	WORD,
	DWORD,
	QWORD,
}

public enum StatementType {
	DATA,
	INSTRUCTION,
}

/+public enum DirectiveType {
	
}+/

public struct DataStatement {
	DataSize size;
	ulong[] data;
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
		
		segment = Segment.NULL;
		/* offsets are implicitly zero */
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
	
	void switchSegment(Segment seg) {
		segment = seg;
	}
	
	bool advance(ulong offset) {
		final switch (segment) {
		case Segment.NULL:
			return false;
		case Segment.TEXT:
		case Segment.DATA:
		case Segment.BSS:
			offsets[segment] = offsets.get(segment, 0) + offset;
			return true;
		}
	}
	
	Location getLocation() {
		return Location(segment, offsets.get(segment, 0));
	}
	
	Symbol[string] symbols;
	
private:
	Line[] lines;
	ulong line;
	
	Statement[] statements;
	
	Segment segment;
	ulong[Segment] offsets;
}

Context ctx;


private void error(in TokenLocation l, in string msg) {
	stderr.writefln("[pass1|error|%s:%d:%d] %s", l.file, l.line, l.col, msg);
	exit(1);
}

private void warn(in TokenLocation l, in string msg) {
	stderr.writefln("[pass1|warn|%s:%d:%d] %s", l.file, l.line, l.col, msg);
}

private Token[] getExpr(Token[] tokens, out Expression expr) {
	try {
		expr = Expression(tokens);
	} catch (ExprEmptyException e) {
		error(e.token.origin, "empty expression");
	} catch (ExprEmptyParenException e) {
		error(e.token.origin, "empty parentheses");
	} catch (ExprUnmatchedParenLException e) {
		error(e.token.origin, "unmatched '('");
	} catch (ExprUnmatchedParenRException e) {
		error(e.token.origin, "unmatched ')'");
	} catch (ExprBadTokenException e) {
		error(e.token.origin, "unexpected %s in expression".format(
			e.token.type.to!string()));
	} catch (ExprException e) {
		error(e.token.origin, "unspecified expression error");
	}
	
	/* tokens AFTER the expression */
	return tokens[expr.length..$];
}

private Integer evalExpr(Expression expr) {
	try {
		return expr.eval(ctx.symbols);
	} catch (EvalSymNotFoundException e) {
		error(e.token.origin,
			"the symbol '%s' has not been defined".format(e.token.tagStr));
	} catch (EvalNoLHSException e) {
		error(e.token.origin,
			"missing LHS for %s operator".format(e.token.type.to!string()));
	} catch (EvalNoRHSException e) {
		error(e.token.origin,
			"missing RHS for %s operator".format(e.token.type.to!string()));
	} catch (EvalUnexpectedLHSException e) {
		error(e.token.origin,
			"unexpected LHS in operation: %s".format(e.token.type.to!string()));
	} catch (EvalUnexpectedRHSException e) {
		error(e.token.origin,
			"unexpected RHS in operation: %s".format(e.token.type.to!string()));
	} catch (EvalConsecutiveIntegerException e) {
		error(e.token.origin, "expected an operator");
	} catch (EvalException e) {
		error(e.token.origin, "unspecified expression evaluation error");
	}
	
	return Integer(Sign.POSITIVE, 0);
}

private void dirSeg() {
	Token[] tokens = ctx.getLine().tokens;
	
	if (tokens.length > 1) {
		error(tokens[1].origin, "unexpected %s in segment directive".format(
			tokens[1].type.to!string()));
	}
	
	Segment segment;
	
	switch (tokens[0].tagStr[1..$]) {
	case "text":
		segment = Segment.TEXT;
		break;
	case "data":
		segment = Segment.DATA;
		break;
	case "bss":
		segment = Segment.BSS;
		break;
	default:
		assert(0);
	}
	
	ctx.switchSegment(segment);
}

private void dirDef() {
	Token[] tokens = ctx.getLine().tokens;
	
	if (tokens.length == 1) {
		error(tokens[0].origin, "expected identifier for .def directive");
	} else if (tokens[1].type != TokenType.IDENTIFIER) {
		error(tokens[1].origin, "unexpected %s in .def directive".format(
			tokens[1].type.to!string()));
	} else if (tokens.length < 3) {
		error(tokens[1].origin, "expected value for .def directive");
	} else if (tokens[2].type != TokenType.COMMA) {
		error(tokens[2].origin, "unexpected %s in .def directive".format(
			tokens[2].type.to!string()));
	} else if (tokens.length < 4) {
		error(tokens[2].origin, "missing value in .def directive");
	}
	
	Expression exprValue;
	Integer intValue;
	TokenLocation locValue;
	
	Token[] tokValue = tokens[3..$];
	Token[] tokPostValue = getExpr(tokValue, exprValue);
	locValue = tokValue[0].origin;
	
	if (tokPostValue.length > 0) {
		error(tokPostValue[0].origin, "unexpected %s after .def " ~
			"directive".format(tokPostValue[0].type.to!string()));
	}
	
	intValue = evalExpr(exprValue);
	
	if (intValue.sign != Sign.POSITIVE) {
		error(locValue, "symbols cannot have negative values");
	}
	
	string name = tokens[1].tagStr;
	
	ctx.symbols[name] = Symbol(intValue.value);
}

private void dirData() {
	Token[] tokens = ctx.getLine().tokens;
	string sizeStr = tokens[0].tagStr[1..$];
	DataSize size;
	
	switch (sizeStr) {
	case "byte":
		size = DataSize.BYTE;
		break;
	case "word":
		size = DataSize.WORD;
		break;
	case "dword":
		size = DataSize.DWORD;
		break;
	case "qword":
		size = DataSize.QWORD;
		break;
	default:
		assert(0);
	}
	
	if (tokens.length == 1) {
		error(tokens[0].origin,
			"expected value for .%s directive".format(sizeStr));
	}
	
	bool hasQuantity = false;
	
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
						"unexpected %s after .%s directive".format(
						tokPostQuantity[0].type.to!string(), sizeStr));
				}
			} else {
				error(tokPostValue[0].origin,
					"expected quantity for .%s directive".format(sizeStr));
			}
		} else {
			error(tokPostValue[0].origin,
				"unexpected %s in .%s directive".format(
				tokPostValue[0].type.to!string(), sizeStr));
		}
	}
	
	intValue = evalExpr(exprValue);
	
	if (intValue.sign != Sign.POSITIVE) {
		error(locValue, "value for .%s cannot be negative".format(sizeStr));
	}
	
	ulong value;
	
	final switch (size) {
	case DataSize.BYTE:
		if (intValue.value > ubyte.max) {
			error(locValue, "value for .byte must be in the range " ~
				"[%d,%d]".format(ubyte.min, ubyte.max));
		} else {
			value = cast(ubyte)intValue.value;
		}
		break;
	case DataSize.WORD:
		if (intValue.value > ushort.max) {
			error(locValue, "value for .word must be in the range " ~
				"[%d,%d]".format(ushort.min, ushort.max));
		} else {
			value = cast(ushort)intValue.value;
		}
		break;
	case DataSize.DWORD:
		if (intValue.value > uint.max) {
			error(locValue, "value for .dword must be in the range " ~
				"[%d,%d]".format(uint.min, uint.max));
		} else {
			value = cast(uint)intValue.value;
		}
		break;
	case DataSize.QWORD:
		if (intValue.value > ulong.max) {
			error(locValue, "value for .qword must be in the range " ~
				"[%d,%d]".format(ulong.min, ulong.max));
		} else {
			value = cast(ulong)intValue.value;
		}
		break;
	}
	
	ulong quantity = 1;
	
	if (hasQuantity) {
		intQuantity = evalExpr(exprQuantity);
		
		if (intQuantity.sign != Sign.POSITIVE) {
			error(locValue,
				"quantity for .%s cannot be negative".format(sizeStr));
		} else if (intQuantity.value == 0) {
			error(locValue,
				"quantity for .%s cannot be zero".format(sizeStr));
		}
		
		quantity = intQuantity.value;
	}
	
	stderr.writefln(".%s: %x x %d", sizeStr, value, quantity);
	
	auto data = new ulong[quantity];
	data[] = value;
	
	auto st = Statement(StatementType.DATA, ctx.getLocation(),
		tokens[0].origin);
	st.data = DataStatement(size, data);
	
	ctx.addStatement(st);
	ctx.advance(quantity);
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
			case ".text":
			case ".data":
			case ".bss":
				dirSeg();
				break;
			case ".def":
				dirDef();
				break;
			case ".byte":
			case ".word":
			case ".dword":
			case ".qword":
				dirData();
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
			/* labels cannot be redefined because they have a finite position */
			if ((token.tagStr in ctx.symbols) == null) {
				ctx.symbols[token.tagStr] = Symbol(ctx.getLocation().offset);
			} else {
				error(token.origin,
					"'%s' has already been defined".format(token.tagStr));
			}
			break;
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
			/+error(token.origin, "unexpected %s at start of line".format(
				token.type.to!string()));+/
			warn(token.origin, "unexpected %s at start of line".format(
				token.type.to!string()));
			break;
		}
	} while (ctx.nextLine());
	
	/* debug */
	stderr.writefln("symbol table:\n--------");
	foreach (key; ctx.symbols.byKey()) {
		stderr.writefln("'%s' -> %016x", key, ctx.symbols[key].value);
	}
	stderr.writefln("--------");
	
	return ctx.getStatements();
}
