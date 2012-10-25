/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module instruction;

import std.string;


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

public Mneumonic[string] mneumonics;

public struct Instruction {
	Mneumonic mneumonic;
	
	/* need to add 'parameters' here, and they must be able to contain
	 * expressions that include labels */
}
