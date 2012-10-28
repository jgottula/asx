/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module table;

import expression;
import segment;


public class SymbolTable {
	Integer[string] symbols;
}

public class LabelTable {
	Location[string] labels;
}
