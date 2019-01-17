module Transform

extend lang::std::Id;

import Syntax;
import AST;
import CST2AST;
import Resolve;
import Set;


/* 
 * Transforming QL forms
 */
 
 
/* Normalization */
 
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


/* Rename refactoring */
 
 Form rename(Form f, loc useOrDef, str newName, UseDef useDef) { 
   set[loc] occurrences = findOccurrences(useOrDef, useDef);
   if (isUnused(f, newName)) {
     return visit(f) {
       case Id x => tryRename(x, newName) when (x@\loc) in occurrences
     } 
   }
   return f;
 } 
 
 
 set[loc] findOccurrences(loc useOrDef, UseDef useDef) {
   loc definition = getOneFrom({ l | <useOrDef, loc l> <- useDef } + { useOrDef | <loc l, useOrDef> <- useDef });
   set[loc] usages = { l | <loc l, definition> <- useDef };
   
   return usages + { definition };
 }

 
 Id tryRename(Id current, str id) { 
 	try return parse(#Id, id); 
 	  catch: return current; 
 }
 
 bool isUnused(Form f, str newName) {
 	AForm af = cst2ast(f);
	return isEmpty({ newName | <newName, _> <- defs(af) });
 }
 

