module Transform

extend lang::std::Id;

import Syntax;
import AST;
import Resolve;
import Set;


/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; if (a) { if (b) { q1: "" int; } q2: "" int; }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (a && b) q1: "" int;
 *     if (a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  list[AQuestion] questions = flattenQuestions(f.questions);
  AForm ret = form(f.name, questions); 
  return ret; 
}

list[AQuestion] flattenQuestions(list[AQuestion] questions) {
  list[AQuestion] ret = [];
  for (q <- questions) {
    switch(q) {
  	  case ifThen(condition, then): 
  	    ret += flattenQuestions([then], condition);
  	  case ifThenElse(condition, then, \else):
  	    ret += flattenQuestions([then], condition) + flattenQuestions([\else], not(condition));
  	  case block(qs):
  	    ret += flattenQuestions(qs);
  	  default:
  	    ret += ifThen(boo(true), q);  	  
    }
  }
  return ret;
}

list[AQuestion] flattenQuestions(list[AQuestion] questions, AExpr currentCondition) {
  list[AQuestion] ret = [];
  for (q <- questions) {
    switch(q) {
  	  case ifThen(condition, then): 
  	    ret += flattenQuestions([then], and(currentCondition, condition));
  	  case ifThenElse(condition, then, \else):
  	    ret += flattenQuestions([then], and(currentCondition, condition)) + flattenQuestions([\else], and(currentCondition, not(condition)));
  	  case block(qs):
  	    ret += flattenQuestions(qs, currentCondition);
  	  default:
  	    ret += ifThen(currentCondition, q);
    }
  }
  return ret;
}


/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
 Form rename(Form f, loc useOrDef, str newName, UseDef useDef) { 
   list[loc] usad = findUsagesAndDeclaration(useOrDef, useDef);
   return visit(f) {
     case Id x => [Id]newName when (x@\loc) in usad
   } 
 } 
 
 
 list[loc] findUsagesAndDeclaration(loc useOrDef, UseDef useDef) {
   loc definition = getOneFrom({ l | <useOrDef, loc l> <- useDef } + { useOrDef | <loc l, useOrDef> <- useDef });
   set[loc] usages = { l | <loc l, definition> <- useDef };
   
   return toList(usages + { definition });
 }
 
 
 list[loc] occurrences(UseDef useDef) = [useDef.use] + [useDef.def];

