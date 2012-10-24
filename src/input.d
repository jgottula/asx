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
import std.string;


/* input: file path -> source string */


private void error(in string msg) {
	stderr.writefln("[input|error] %s", msg);
	exit(1);
}

private void warn(in string msg) {
	stderr.writefln("[input|warn] %s", msg);
}

string readSource(in string path) {
	if (path.length < 3 || path[$-2..$] != ".s") {
		error("expected a file ending in '.s'");
	}
	
	if (!path.exists()) {
		error("the source file '%s' does not exist");
	}
	
	File file;
	
	try {
		file = File(path, "r");
	}
	catch (ErrnoException e) {
		error("encountered an IO error (errno = %d):\n%s".format(e.msg));
	}
	
	file.seek(0, SEEK_END);
	auto src = new char[file.tell()];
	
	if (file.tell() == 0) {
		error("empty source file");
	}
	
	file.seek(0, SEEK_SET);
	file.rawRead(src);
	
	return cast(string)src;
}
