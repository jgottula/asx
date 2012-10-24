/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module escape;


bool isEscape(char c) {
	return (c == '\a' || c == '\b' || c == '\f' || c == '\n' || c == '\r' ||
		c == '\t' || c == '\v');
}

string escapize(char c) {
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
