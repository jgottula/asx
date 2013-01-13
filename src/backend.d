/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module backend;

import core.stdc.errno;
import core.sys.posix.fcntl;
import core.sys.posix.unistd;
import std.c.stdlib;
import std.conv;
import std.stdio;
import std.string;
import elf.libelf;
import symbol;


string shStrTable =
	"\0.shstrtab\0.text\0.rodata\0.data\0.bss\0.strtab\0.symtab\0";
immutable(Elf64_Word) shStrTable_shstrtab = 0x01;
immutable(Elf64_Word) shStrTable_text     = 0x0b;
immutable(Elf64_Word) shStrTable_rodata   = 0x11;
immutable(Elf64_Word) shStrTable_data     = 0x19;
immutable(Elf64_Word) shStrTable_bss      = 0x1f;
immutable(Elf64_Word) shStrTable_strtab   = 0x24;
immutable(Elf64_Word) shStrTable_symtab   = 0x2c;

immutable(Elf64_Xword) sectAlign = 16;

int fd = -1;
Elf* eDesc = null;
Elf64_Ehdr* eExecHeader;
Elf64_Shdr* eSectHeader;
Elf_Scn* eSect;
Elf_Data* eData;


public struct BackendPkg {
	ubyte[] text;
	ubyte[] rodata;
	ubyte[] data;
	ulong bssLen;
	SymbolTable symTab;
}

private string elfErrorStr() {
	int elfErr = elf_errno();
	
	assert(elfErr != 0);
	
	return "[%d] %s".format(elfErr, elf_errmsg(elfErr).to!string());
}

private void error(in string phase, in string msg, bool elfMsg = true) {
	stderr.writefln("[backend|%s|error] %s%s", phase, msg,
		(elfMsg ? elfErrorStr() : ""));
	
	objEnd();
	exit(1);
}

private void warn(in string phase, in string msg, bool elfMsg = true) {
	stderr.writefln("[backend|%s|warn] %s%s", phase, msg,
		(elfMsg ? elfErrorStr() : ""));
}

private void objBegin(string path) {
	/* initialize libelf */
	
	if (elf_version(EV_CURRENT) == EV_NONE) {
		error("begin", "libelf init failed");
	}
	
	/* open the object file for writing */
	
	if ((fd = open(path.toStringz(), O_WRONLY | O_CREAT,
		octal!644)) < 0) {
		error("begin", "could not create output file (errno: %d)".format(
			errno()), false);
	}
	
	/* get a new elf descriptor */
	
	if ((eDesc = elf_begin(fd, Elf_Cmd.WRITE, null)) == null) {
		error("begin", "elf_begin failure: ");
	}
	
	/* allocate and set up the elf header */
	
	if ((eExecHeader = elf64_newehdr(eDesc)) == null) {
		error("begin", "elf64_newehdr failure: ");
	}
	
	eExecHeader.e_ident[EI_DATA] = ELFDATA2LSB;
	eExecHeader.e_type           = ET_REL;
	eExecHeader.e_machine        = EM_X86_64;
	eExecHeader.e_version        = EV_CURRENT;
	eExecHeader.e_shstrndx       = 1;
}

private void obj_shstrtab() {
	if ((eSect = elf_newscn(eDesc)) == null) {
		error("shstrtab", "elf_newscn failure: ");
	}
	
	if ((eData = elf_newdata(eSect)) == null) {
		error("shstrtab", "elf_newdata failure: ");
	}
	
	eData.d_buf  = cast(void*)shStrTable;
	eData.d_type = Elf_Type.BYTE;
	eData.d_version = EV_CURRENT;
	eData.d_size = shStrTable.length;
	eData.d_off  = 0;
	
	if ((eSectHeader = elf64_getshdr(eSect)) == null) {
		error("shstrtab", "elf64_getshdr failure: ");
	}
	
	eSectHeader.sh_name    = shStrTable_shstrtab;
	eSectHeader.sh_type    = SHT_STRTAB;
	eSectHeader.sh_flags   = 0;
	eSectHeader.sh_entsize = 0;
}

private void obj_text(in ubyte[] data) {
	if ((eSect = elf_newscn(eDesc)) == null) {
		error("text", "elf_newscn failure: ");
	}
	
	if ((eData = elf_newdata(eSect)) == null) {
		error("text", "elf_newdata failure: ");
	}
	
	eData.d_buf     = cast(void*)data;
	eData.d_type    = Elf_Type.BYTE;
	eData.d_version = EV_CURRENT;
	eData.d_size    = data.length;
	eData.d_off     = 0;
	
	if ((eSectHeader = elf64_getshdr(eSect)) == null) {
		error("text", "elf64_getshdr failure: ");
	}
	
	eSectHeader.sh_name      = shStrTable_text;
	eSectHeader.sh_type      = SHT_PROGBITS;
	eSectHeader.sh_flags     = SHF_ALLOC | SHF_EXECINSTR;
	eSectHeader.sh_addralign = sectAlign;
}

private void obj_rodata(in ubyte[] data) {
	if ((eSect = elf_newscn(eDesc)) == null) {
		error("rodata", "elf_newscn failure: ");
	}
	
	if ((eData = elf_newdata(eSect)) == null) {
		error("rodata", "elf_newdata failure: ");
	}
	
	eData.d_buf     = cast(void*)data;
	eData.d_type    = Elf_Type.BYTE;
	eData.d_version = EV_CURRENT;
	eData.d_size    = data.length;
	eData.d_off     = 0;
	
	if ((eSectHeader = elf64_getshdr(eSect)) == null) {
		error("rodata", "elf64_getshdr failure: ");
	}
	
	eSectHeader.sh_name      = shStrTable_rodata;
	eSectHeader.sh_type      = SHT_PROGBITS;
	eSectHeader.sh_flags     = SHF_ALLOC;
	eSectHeader.sh_addralign = sectAlign;
}

private void obj_data(in ubyte[] data) {
	if ((eSect = elf_newscn(eDesc)) == null) {
		error("data", "elf_newscn failure: ");
	}
	
	if ((eData = elf_newdata(eSect)) == null) {
		error("data", "elf_newdata failure: ");
	}
	
	eData.d_buf     = cast(void*)data;
	eData.d_type    = Elf_Type.BYTE;
	eData.d_version = EV_CURRENT;
	eData.d_size    = data.length;
	eData.d_off     = 0;
	
	if ((eSectHeader = elf64_getshdr(eSect)) == null) {
		error("data", "elf64_getshdr failure: ");
	}
	
	eSectHeader.sh_name      = shStrTable_data;
	eSectHeader.sh_type      = SHT_PROGBITS;
	eSectHeader.sh_flags     = SHF_ALLOC | SHF_WRITE;
	eSectHeader.sh_addralign = sectAlign;
}

private void obj_bss(Elf64_Xword size) {
	if ((eSect = elf_newscn(eDesc)) == null) {
		error("bss", "elf_newscn failure: ");
	}
	
	if ((eData = elf_newdata(eSect)) == null) {
		error("bss", "elf_newdata failure: ");
	}
	
	eData.d_type    = Elf_Type.BYTE;
	eData.d_version = EV_CURRENT;
	eData.d_size    = size;
	eData.d_off     = 0;
	
	if ((eSectHeader = elf64_getshdr(eSect)) == null) {
		error("bss", "elf64_getshdr failure: ");
	}
	
	eSectHeader.sh_name      = shStrTable_bss;
	eSectHeader.sh_type      = SHT_NOBITS;
	eSectHeader.sh_flags     = SHF_ALLOC | SHF_WRITE;
	eSectHeader.sh_addralign = sectAlign;
}

private void obj_strtab(string[] strs) {
	
}

private void obj_symtab(SymbolTable symTab) {
	
}

private void objWrite() {
	if (elf_update(eDesc, Elf_Cmd.WRITE) < 0) {
		error("write", "elf_update failure: ");
	}
}

private void objEnd() {
	if (eDesc != null) {
		elf_end(eDesc);
		eDesc = null;
	}
	
	if (fd != -1) {
		close(fd);
		fd = -1;
	}
}

void makeObject(string path, BackendPkg pkg) {
	objBegin(path);
	
	obj_shstrtab();
	obj_text(pkg.text);
	obj_rodata(pkg.rodata);
	obj_data(pkg.data);
	obj_bss(pkg.bssLen);
	/* TODO: str table? */
	obj_symtab(pkg.symTab);
	
	objWrite();
	objEnd();
}
