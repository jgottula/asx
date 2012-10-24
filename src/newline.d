/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module newline;


/* newline pass: { CR LF CRLF LFCR } -> LF */


void fixNewlines(ref string src) {
	auto dst = new char[0];
	
	while (src.length > 0) {
		if (src[0] == '\r') {
			dst ~= '\n';
			
			if (src.length >= 2 && src[1] == '\n') {
				src = src[2..$];
			} else {
				src = src[1..$];
			}
		} else if (src[0] == '\n') {
			dst ~= '\n';
			
			if (src.length >= 2 && src[1] == '\r') {
				src = src[2..$];
			} else {
				src = src[1..$];
			}
		} else {
			dst ~= src[0];
			src = src[1..$];
		}
	}
	
	src = cast(string)dst;
}
