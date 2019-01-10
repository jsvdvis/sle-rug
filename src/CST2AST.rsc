module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import Boolean;

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
  return cst2ast(f);
}

AForm cst2ast(fs: (Form)`form <Id name> { <Question+ questions> }`) {
  return form("<name>", [ cst2ast(q) | Question q <- questions], src = fs@\loc); 
}

AQuestion cst2ast(qs: Question q) {
  switch(q) {
    case (Question)`<Str sentence> <Id name> : <Type t>`: 
      return question("<sentence>", "<name>", cst2ast(t)
            , src = q.name@\loc);
    case (Question)`<Str sentence> <Id name> : <Type t> = <Expr v>`:
      return computedQuestion("<sentence>",  "<name>", cst2ast(t), cst2ast(v)
            , src = qs@\loc);
    case (Question)`if (<Expr condition>) <Question then>`:
      return ifThen(cst2ast(condition), cst2ast(then)
            , src = qs@\loc);
    case (Question)`if (<Expr condition>) <Question then> else <Question els>`:
      return ifThenElse(cst2ast(condition), cst2ast(then), cst2ast(els)
            , src = qs@\loc);
    case (Question)`{ <Question+ questions> }`:
      return block([cst2ast(quest)| Question quest <- questions]
            , src = qs@\loc);
  }
}

AExpr cst2ast(es: Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: 
      return ref("<x>", src = x@\loc);
    case (Expr)`<Int n>`:
      return dec(toInt("<n>"), src = es@\loc);
    case (Expr)`<Str s>`:
      return chr("<s>", src = es@\loc);
    case (Expr)`<Bool b>`:
      return boo(fromString("<b>"), src = es@\loc);
    case (Expr)`(<Expr ex>)`:
      return cst2ast(ex);
    case (Expr)`!<Expr ex>`:
      return not(cst2ast(ex), src = es@\loc);   
    case (Expr)`<Expr lhs> * <Expr rhs>`:
      return mul(cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> / <Expr rhs>`:
      return div(cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> + <Expr rhs>`:
      return add(cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> - <Expr rhs>`:
      return sub(cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> \> <Expr rhs>`:
      return gt(cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> \< <Expr rhs>`:
      return lt(cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> \<= <Expr rhs>`:
      return leq(cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> \>= <Expr rhs>`:
      return geq(cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> == <Expr rhs>`:
      return AExpr::eq(cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> != <Expr rhs>`:
      return neq(cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> && <Expr rhs>`:
      return and(cst2ast(lhs), cst2ast(rhs), src = es@\loc);
      
    case (Expr)`<Expr lhs> || <Expr rhs>`:
      return or(cst2ast(lhs), cst2ast(rhs), src = es@\loc);
    	
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(ts: Type t) {
  switch ("<t>") {
    case "integer": return integer(src = ts@\loc);
    case "boolean": return boolean(src = ts@\loc);
    case "string": return string(src = ts@\loc);
    default: return unknown(src = ts@\loc);
  }
}


