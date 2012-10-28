/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module symbol;


public struct SymbolAttrs {
	/* whether global or not,
	 * type (function, data, etc) */
}

public struct Symbol {
	ulong value;
	/* TODO: attrs
	 * NOTE: adding anything to this struct will make the assoc array lookups
	 * probably fail, so be careful */
}
