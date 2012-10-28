/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module segment;


public enum Segment {
	NULL,
	TEXT,
	DATA,
	BSS,
}

public struct Location {
	Segment segment;
	ulong offset;
}
