/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module input;

import std.c.stdlib;
import std.conv;
import std.exception;
import std.file;
import std.stdio;


void readSource(in string inputPath, out string fileContents) {
	if (inputPath.length < 3 || inputPath[$-2..$] != ".s") {
		stderr.write("[input|error] expected a file ending in '.s'\n");
		exit(1);
	}
	
	if (!inputPath.exists()) {
		stderr.writef("[input|error] the source file '%s' does not exist\n",
			inputPath);
		exit(1);
	}
	
	File inputFile;
	
	try {
		inputFile = File(inputPath, "r");
	}
	catch (ErrnoException e) {
		stderr.writef("[input|error] encountered an IO error " ~
			"(errno = %d):\n%s\n", e.errno, e.msg);
		exit(1);
	}
	
	inputFile.seek(0, SEEK_END);
	char[] buffer = new char[inputFile.tell()];
	
	if (inputFile.tell() == 0) {
		stderr.writef("[input|error] empty source file\n");
		exit(1);
	}
	
	inputFile.seek(0, SEEK_SET);
	inputFile.rawRead(buffer);
	
	fileContents = to!string(buffer);
}
