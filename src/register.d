/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module register;


static this() {
	regNames["al"] = Register.al;
	regNames["ah"] = Register.ah;
	regNames["ax"] = Register.ax;
	regNames["eax"] = Register.eax;
	
	regNames["bl"] = Register.bl;
	regNames["bh"] = Register.bh;
	regNames["bx"] = Register.bx;
	regNames["ebx"] = Register.ebx;
	
	regNames["cl"] = Register.cl;
	regNames["ch"] = Register.ch;
	regNames["cx"] = Register.cx;
	regNames["ecx"] = Register.ecx;
	
	regNames["dl"] = Register.dl;
	regNames["dh"] = Register.dh;
	regNames["dx"] = Register.dx;
	regNames["edx"] = Register.edx;
	
	regNames["esi"] = Register.esi;
	regNames["edi"] = Register.edi;
	
	regNames["esp"] = Register.esp;
	regNames["ebp"] = Register.ebp;
	
	regNames["eip"] = Register.eip;
	regNames["eflags"] = Register.eflags;
}


public enum Register {
	al, ah, ax, eax,
	bl, bh, bx, ebx,
	cl, ch, cx, ecx,
	dl, dh, dx, edx,
	
	esi, edi,
	esp, ebp,
	
	eip, eflags,
}

public Register[string] regNames;
