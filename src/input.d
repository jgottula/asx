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


private void error(in string path, in string msg) {
	stderr.writefln("[input|error|%s] %s", path, msg);
	exit(1);
}

private void warn(in string path, in string msg) {
	stderr.writefln("[input|warn|%s] %s", path, msg);
}

string readSource(in string path, bool include = false) {
	if (!path.exists()) {
		error(path, "'%s' does not exist".format(path));
	} else if (path.isDir()) {
		error(path, "'%s' is a directory, not a file".format(path));
	} else if (!path.isFile()) {
		error(path, "'%s' is not a file".format(path));
	}
	
	File file;
	
	try {
		file = File(path, "r");
	}
	catch (ErrnoException e) {
		error(path, "encountered an IO error (errno = %d):\n%s".format(e.errno,
			e.msg));
	}
	
	file.seek(0, SEEK_END);
	auto src = new char[file.tell()];
	
	if (!include && file.tell() == 0) {
		error(path, "empty source file");
	}
	
	file.seek(0, SEEK_SET);
	file.rawRead(src);
	
	return cast(string)src;
}
