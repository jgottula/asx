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


string strTable = '\0' ~ ".strtab\0" ~ ".text\0";

immutable(ubyte)[] helloData = [
	'h', 'e', 'l', 'l', 'o'
];

int fd;
Elf* eDesc;
Elf64_Ehdr* eExecHeader;
Elf64_Phdr* ePrgmHeader;
Elf64_Shdr* eSectHeader;
Elf_Scn* eSect;
Elf_Data* eData;


public struct BackendPkg {
	
}

private string elfErrorStr() {
	int elfErr = elf_errno();
	
	assert(elfErr != 0);
	
	return "[%d] %s".format(elfErr, elf_errmsg(elfErr).to!string());
}

private void error(in string msg, bool elfMsg = true) {
	stderr.writefln("[backend|error] %s%s", msg, (elfMsg ? elfErrorStr() : ""));
	exit(1);
}

private void warn(in string msg, bool elfMsg = true) {
	stderr.writefln("[backend|warn] %s", msg, (elfMsg ? elfErrorStr() : ""));
}

private void elfInit() {
	if (elf_version(EV_CURRENT) == EV_NONE) {
		error("libelf init failed");
	}
}

void makeObject() {
	elfInit();
	
	/* open the object file to which we will write */
	if ((fd = open("test_output.o".toStringz(), O_WRONLY | O_CREAT,
		octal!644)) < 0) {
		error("could not create output file (errno: %d)".format(errno()),
			false);
	}
	
	scope(exit) close(fd);
	
	/* get an ELF descriptor for writing a new ELF object */
	if ((eDesc = elf_begin(fd, Elf_Cmd.WRITE, null)) == null) {
		error("elf_begin failure: ");
	}
	
	scope(exit) elf_end(eDesc);
	
	/* allocate an ELF executable header */
	if ((eExecHeader = elf64_newehdr(eDesc)) == null) {
		error("elf64_newehdr failure: ");
	}
	
	eExecHeader.e_ident[EI_DATA] = ELFDATA2LSB;
	eExecHeader.e_type           = ET_REL;
	eExecHeader.e_machine        = EM_X86_64;
	eExecHeader.e_version        = EV_CURRENT;
	eExecHeader.e_shstrndx       = 1;
	
	/* allocate a program header with size 1 (for now) */
	if ((ePrgmHeader = elf64_newphdr(eDesc, 1)) == null) {
		error("elf64_newphdr failure: ");
	}
	
	/* allocate a new section */
	if ((eSect = elf_newscn(eDesc)) == null) {
		error("elf_newscn(a) failure: ");
	}
	
	/* allocate a new data buffer for the section */
	if ((eData = elf_newdata(eSect)) == null) {
		error("elf_newdata(a) failure: ");
	}
	
	eData.d_buf     = cast(void*)helloData;
	eData.d_type    = Elf_Type.BYTE;
	eData.d_version = EV_CURRENT;
	eData.d_size    = helloData.length;
	eData.d_off     = 0;
	
	/* get the section header for the text section */
	if ((eSectHeader = elf64_getshdr(eSect)) == null) {
		error("elf64_getshdr(a) failure: ");
	}
	
	eSectHeader.sh_name      = 2;
	eSectHeader.sh_type      = SHT_PROGBITS;
	eSectHeader.sh_flags     = SHF_ALLOC | SHF_EXECINSTR;
	eSectHeader.sh_addralign = 4;
	
	/* allocate a new section for the string table */
	if ((eSect = elf_newscn(eDesc)) == null) {
		error("elf_newscn(b) failure: ");
	}
	
	/* allocate a new data buffer for the section */
	if ((eData = elf_newdata(eSect)) == null) {
		error("elf_newdata(b) failure: ");
	}
	
	eData.d_buf  = cast(void*)strTable;
	eData.d_type = Elf_Type.BYTE;
	eData.d_version = EV_CURRENT;
	eData.d_size = strTable.length;
	eData.d_off  = 0;
	
	/* get the section header for the string table section */
	if ((eSectHeader = elf64_getshdr(eSect)) == null) {
		error("elf64_getshdr(b) failure: ");
	}
	
	eSectHeader.sh_name    = 1;
	eSectHeader.sh_type    = SHT_STRTAB;
	eSectHeader.sh_flags   = 0;
	eSectHeader.sh_entsize = 0;
	
	/* compute the layout but don't write it out */
	if (elf_update(eDesc, Elf_Cmd.NULL) < 0) {
		error("elf_update(a) failure: ");
	}
	
	ePrgmHeader.p_type = PT_PHDR;
	ePrgmHeader.p_offset = eExecHeader.e_phoff;
	ePrgmHeader.p_filesz = elf64_fsize(Elf_Type.PHDR, 1, EV_CURRENT);
	
	elf_flagphdr(eDesc, Elf_Cmd.SET, ELF_F_DIRTY);
	
	if (elf_update(eDesc, Elf_Cmd.WRITE) < 0) {
		error("elf_update(b) failure: ");
	}
}
