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
  return cst2ast(f, src=f@\loc);
}

AForm cst2ast((Form)`form <Id name> { <Question+ questions> }`) {
  return form("<name>", [ cst2ast(q) | Question q <- questions]); 
}

AQuestion cst2ast(qs: Question q) {
  switch(q) {
    case (Question)`<Str sentence> <Id variable> : <Type answer>`: 
      return question("<sentence>", cst2ast((Expr)`<Id variable>`), cst2ast(answer)
            , src = qs@\loc);
    case (Question)`<Str sentence> <Id variable> : <Type answer> = <Expr assignment>`:
      return question("<sentence>", cst2ast((Expr)`<Id variable>`), cst2ast(answer), cst2ast(assignment)
            , src = qs@\loc);
    case (Question)`if (<Expr condition>) <Question then>`:
      return question(cst2ast(condition), cst2ast(then)
            , src = qs@\loc);
    case (Question)`if (<Expr condition>) <Question then> else <Question els>`:
      return question(cst2ast(condition), cst2ast(then), cst2ast(els)
            , src = qs@\loc);
    case (Question)`{ <Question+ questions> }`:
      return question([cst2ast(quest)| Question quest <- questions]
            , src = qs@\loc);
  }
}

AExpr cst2ast(es: Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: 
      return ref("<x>", src=x@\loc);
    case (Expr)`<Int n>`:
      return expr(toInt("<n>"), src = es@\loc);
    case (Expr)`(<Expr ex>)`:
      return expr(cst2ast(ex), src = es@\loc);
    case (Expr)`!<Expr ex>`:
      return expr(cst2ast(ex), src = es@\loc);   
    case (Expr)`<Expr lhs> * <Expr rhs>`:
      return expr("*", cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> / <Expr rhs>`:
      return expr("/", cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> + <Expr rhs>`:
      return expr("+", cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> - <Expr rhs>`:
      return expr("-", cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> \> <Expr rhs>`:
      return expr("\>", cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> \< <Expr rhs>`:
      return expr("\<", cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> \<= <Expr rhs>`:
      return expr("\<=", cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> \>= <Expr rhs>`:
      return expr("\>=", cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> == <Expr rhs>`:
      return expr("==", cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> != <Expr rhs>`:
      return expr("!=", cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> && <Expr rhs>`:
      return expr("&&", cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> || <Expr rhs>`:
      return expr("||", cst2ast(lhs), cst2ast(rhs), src = es@\loc);
    	
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(ts: Type t) {
  return \type("<t>", src = ts@\loc);
}


