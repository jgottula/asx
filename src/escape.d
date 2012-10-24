/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module escape;


/* TODO: add support for octal/decimal/hex escape sequences */


bool isEscape(char c) {
	return (c == '\a' || c == '\b' || c == '\f' || c == '\n' || c == '\r' ||
		c == '\t' || c == '\v');
}

bool isEscapeStr(string s) {
	assert(s.length >= 2);
	
	switch (s[0..2]) {
	case "\\a":
	case "\\b":
	case "\\f":
	case "\\n":
	case "\\r":
	case "\\t":
	case "\\v":
		return true;
	default:
		return false;
	}
}

char escapize(string s) {
	assert(s.length >= 2);
	assert(isEscapeStr(s));
	
	switch (s[0..2]) {
	case "\\a":
		return '\a';
	case "\\b":
		return '\b';
	case "\\f":
		return '\f';
	case "\\n":
		return '\n';
	case "\\r":
		return '\r';
	case "\\t":
		return '\t';
	case "\\v":
		return '\v';
	default:
		return '\0';
	}
}

string unescapize(char c) {
	switch (c) {
	case '\a':
		return "\\a";
	case '\b':
		return "\\b";
	case '\f':
		return "\\f";
	case '\n':
		return "\\n";
	case '\r':
		return "\\r";
	case '\t':
		return "\\t";
	case '\v':
		return "\\v";
	default:
		return [c];
	}
}


unittest {
	assert(isEscapeStr("\\a"));
	assert(isEscapeStr("\\b"));
	assert(!isEscapeStr("\\c"));
	assert(!isEscapeStr("\\d"));
	assert(!isEscapeStr("\\e"));
	assert(isEscapeStr("\\f"));
	assert(!isEscapeStr("\\g"));
	assert(!isEscapeStr("\\h"));
	assert(!isEscapeStr("\\i"));
	assert(!isEscapeStr("\\j"));
	assert(!isEscapeStr("\\k"));
	assert(!isEscapeStr("\\l"));
	assert(!isEscapeStr("\\m"));
	assert(isEscapeStr("\\n"));
	assert(!isEscapeStr("\\o"));
	assert(!isEscapeStr("\\p"));
	assert(!isEscapeStr("\\q"));
	assert(isEscapeStr("\\r"));
	assert(!isEscapeStr("\\s"));
	assert(isEscapeStr("\\t"));
	assert(!isEscapeStr("\\u"));
	assert(isEscapeStr("\\v"));
	assert(!isEscapeStr("\\w"));
	assert(!isEscapeStr("\\x"));
	assert(!isEscapeStr("\\y"));
	assert(!isEscapeStr("\\z"));
}
