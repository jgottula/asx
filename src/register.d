/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module register;

import std.string;
import token;


static this() {
	/* reflection: loop over all enum members */
	foreach (reg; __traits(allMembers, Register)) {
		regNames[reg.toLower()] = mixin("Register." ~ reg);
	}
}


public enum Register {
	AL, AH, AX, EAX,
	BL, BH, BX, EBX,
	CL, CH, CX, ECX,
	DL, DH, DX, EDX,
	
	ESI, EDI,
	ESP, EBP,
	
	EIP, EFLAGS,
}

public Register[string] regNames;


public bool isRegName(string s) {
	Register* reg = (s in regNames);
	return (reg != null);
}
