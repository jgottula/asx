/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module table;

import expression;
import segment;


public struct SymbolTable {
	Integer[string] symbols;
}

public struct LabelTable {
	Location[string] labels;
}
