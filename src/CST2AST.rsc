module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return form("", [], src=f@\loc); 
}

AQuestion cst2ast(Question q) {
  switch(q) {
    case (Question)`<Str sentence> <Id variable> : <Type answer>`: 
      return question(toString(sentence), cst2ast((Expr)`<Id variable>`), cst2ast(answer));
    case (Question)`<Str sentence> <Id variable> : <Type answer> = <Expr assignment>`:
      return question(toString(sentence), cst2ast((Expr)`<Id variable>`), cst2ast(answer), cst2ast(assignment));
    case (Question)`if (<Expr condition>) <Question then>`:
      return question(cst2ast(condition), cst2ast(then));
    case (Question)`if (<Expr condition>) <Question then> else <Question els>`:
      return question(cst2ast(condition), cst2ast(then), cst2ast(els));
    case (Question)`{ <Question+ questions> }`:
      return question(cst2ast([q | q <- questions]));
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: 
      return ref("<x>", src=x@\loc);
    case (Expr)`<Num n>`:
      return expr(toInt("<n>"));
    case (Expr)`(<Expr e>)`:
      return expr(cst2ast(e));
    case (Expr)`!<Expr e>`:
      return expr(cst2ast(e));
    case (Expr)`<Expr lhs> * <Expr rhs>`:
      return expr(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> / <Expr rhs>`:
      return expr(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> + <Expr rhs>`:
      return expr(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> - <Expr rhs>`:
      return expr(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> \> <Expr rhs>`:
      return expr(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> \< <Expr rhs>`:
      return expr(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> \<= <Expr rhs>`:
      return expr(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> \>= <Expr rhs>`:
      return expr(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> == <Expr rhs>`:
      return expr(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> != <Expr rhs>`:
      return expr(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> && <Expr rhs>`:
      return expr(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> || <Expr rhs>`:
      return expr(cst2ast(lhs), cst2ast(rhs));
    
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
  throw "Not yet implemented";
}
