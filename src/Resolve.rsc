module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

// the reference graph
alias UseDef = rel[loc use, loc def];

UseDef resolve(AForm f) = uses(f) o defs(f);

Use uses(AForm f) {
  Use useSet = {};
  for (/AExpr e := f) {
    if (e has name) {
      useSet += { <e.src, e.name> };
    }
  }
  return useSet; 
}

Def defs(AForm f) {
  Def defSet = {};
  for (/AQuestion e := f) {
    if (e has variable) {
      AExpr variable = e.variable;
      defSet += { <variable.name, variable.src> };
    }
  }
  return defSet; 
}