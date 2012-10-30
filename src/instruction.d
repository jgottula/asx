/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module instruction;

import std.string;
import expression;
import pass0;
import pass1;
import register;
import token;


static this() {
	static assert(__traits(allMembers, Mneumonic).length == 117);
	
	/* reflection: loop over all enum members */
	foreach (instr; __traits(allMembers, Mneumonic)) {
		mneumonics[instr.toLower()] = mixin("Mneumonic." ~ instr);
	}
}


public enum Mneumonic {
	/* 8086 */
	AAA, AAD, AAM, AAS, ADC, ADD, AND, CALL, CBW, CLC, CLD, CLI, CMD, CMP,
	CMPSB, CMPSW, CWD, DAA, DAS, DEC, DIV, ESC, HLT, IDIV, IMUL, IN, INC, INT,
	INTO, IRET, JA, JAE, JB, JBE, JC, JCXZ, JE, JG, JGE, JL, JLE, JNA, JNAE,
	JNB, JNBE, JNC, JNE, JNG, JNGE, JNL, JNLE, JNO, JNP, JNS, JNZ, JO, JP, JPE,
	JPO, JS, JZ, JMP, LAHF, LDS, LEA, LES, LOCK, LODSB, LODSW, LOOP, LOOPE,
	LOOPNZ, LOOPZ, MOV, MOVSB, MOVSW, MUL, NEG, NOP, NOT, OR, OUT, POP, POPF,
	PUSH, PUSHF, RCL, RCR, REP, REPE, RPENE, REPNZ, REPZ, RET, RETN, RETF, ROL,
	ROR, SAHF, SAL, SAR, SBB, SCASB, SCASW, SHL, SHR, STC, STD, STI, STOSB,
	STOSW, SUB, TEST, WAIT, XCHG, XLAT, XOR
}

/+public enum OperandType {
	EMPTY,
	REGISTER,
	EXPRESSION,
}

public struct Operand {
	OperandType type;
	Expression expr;
}+/

/* in pass2, we will determine the actual TYPES of operands (immediate, reg,
 * indexed, etc) */

public struct Instruction {
	Mneumonic mneu;
	Expression[] operands;
	/+Operand[] operands;+/
}

public class InstrException : Exception {
	this(const(Token) token) {
		super("");
		this.token = token;
	}
	
	const(Token) token;
}
public class InstrMissingOperandException : InstrException {
	this(const(Token) token) {
		super(token);
	}
}
public class InstrExtraOperandException : InstrException {
	this(const(Token) token) {
		super(token);
	}
}
public class InstrEmptyOperandException : InstrException {
	this(const(Token) token) {
		super(token);
	}
}
public class InstrHangingCommaException : InstrException {
	this(const(Token) token) {
		super(token);
	}
}
public class InstrUnexpectedTokenException : InstrException {
	this(const(Token) token) {
		super(token);
	}
}

public Mneumonic[string] mneumonics;


public bool isMneumonic(string s) {
	Mneumonic* mneu = (s in mneumonics);
	return (mneu != null);
}

private Expression[] getOperands(Token[] tokens, ubyte expected) {
	Expression[] operands;
	Token tokLast = tokens[$-1];
	
	tokens = tokens[1..$];
	
	while (tokens.length > 0) {
		auto expr = Expression(tokens);
		tokens = tokens[expr.length..$];
		
		if (expr.length == 0) {
			throw new InstrEmptyOperandException(tokens[0]);
		} else if (operands.length > expected) {
			throw new InstrExtraOperandException(expr.tokens[0]);
		} else if (tokens.length > 0) {
			if (tokens[0].type != TokenType.COMMA) {
				throw new InstrUnexpectedTokenException(tokens[0]);
			} else if (tokens.length < 2) {
				throw new InstrHangingCommaException(tokens[0]);
			}
			
			/* advance past comma */
			tokens = tokens[1..$];
		}
	}
	
	if (operands.length < expected) {
		throw new InstrMissingOperandException(tokLast);
	}
	
	return operands;
}

public Instruction parseInstruction(Line line) {
	auto tokens = line.tokens;
	Mneumonic* mneu = (tokens[0].tagStr in mneumonics);
	assert(mneu != null);
	
	auto instr = Instruction(*mneu);
	ubyte expOperands = 0;
	
	/+final+/ switch (*mneu) {
	case Mneumonic.NOP:
	case Mneumonic.RET:
		break;
	case Mneumonic.CALL:
	case Mneumonic.POP:
	case Mneumonic.PUSH:
		expOperands = 1;
		break;
	case Mneumonic.ADD:
	case Mneumonic.MOV:
	case Mneumonic.MUL:
	case Mneumonic.XOR:
		expOperands = 2;
		break;
	default:
		assert(0);
	}
	
	instr.operands = getOperands(tokens, expOperands);
	
	return instr;
}
