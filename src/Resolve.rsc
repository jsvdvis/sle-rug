module Resolve

import AST;
import IO;

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
  return { <e.src, e.name> | /AExpr e := f, e is ref };  
}

Def defs(AForm f) {
  return { <q.variable, q.src> | /AQuestion q := f, (q is question || q is computedQuestion) };  
}