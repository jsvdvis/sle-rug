module Check

import AST;
import Resolve;
import Message; // see standard library

import Set;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  return { <q.src, q.name, q.sentence, typeCast(q.\type)> | /AQuestion q:= f, (q is question || q is computedQuestion)  };
}

Type typeCast(AType t) {
  switch (t) {
    case integer(): return tint();
    case boolean(): return tbool();
    case string(): return tstr();
    default: return tunknown();  
  }
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  return union({ check(q, tenv, useDef) | /AQuestion q := f })
       + union({ check(e, tenv, useDef) | /AExpr e := f });
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) { 
  if (q is question || q is computedQuestion) {
    types = [tup.\type | tup <- toList(tenv), tup.name == q.name];
    questions = { e | e <- toList(tenv), e<2> == q.sentence };
    return { error("Type error: variable is also defined with a different type.", q.src) | any(t <- types, t != typeCast(q.\type)) }
  		 + { warning("Semantics: Same question defined more than once.", q.src) | size(questions) > 1 }
  		 + { error("Mismatched types, the value assigned to the variable has a different type than expected.", q.src) | q is computedQuestion, typeOf(q.\value, tenv, useDef) != typeCast(q.\type) };
  } else if (q has condition) 
  	return { error("An if-conditional should evaluate to a boolean.", q.src) | typeOf(q.condition, tenv, useDef) != tbool() };
  return {};
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(str x, src = loc u):
      msgs += { error("Undeclared question", u) | useDef[u] == {} };
    case not(AExpr child, src = loc u):
      msgs += { error("Mismatched type used, not operator (!) expects a boolean.", u) | typeOf(child, tenv, useDef) != tbool() };
    case mul(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error("Wrong types used, multiplication operator (*) expects integers.", u) | !(typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(rhs, tenv, useDef) == tint()) };
    case div(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error("Wrong types used, division operator (\\) expects integers.", u) | !(typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(rhs, tenv, useDef) == tint()) };
    case add(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error("Wrong types used, addition operator (+) expects integers.", u) | !(typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(rhs, tenv, useDef) == tint()) };
    case sub(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error("Wrong types used, subtraction operator (-) expects integers.", u) | !(typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(rhs, tenv, useDef) == tint()) };
    case gt(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error("Wrong types used, greater than operator (\>) expects integers.", u) | !(typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(rhs, tenv, useDef) == tint()) };    
    case lt(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error("Wrong types used, less than operator (\<) expects integers.", u) | !(typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(rhs, tenv, useDef) == tint()) };    
    case leq(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error("Wrong types used, less or equal operator (\<=) expects integers.", u) | !(typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(rhs, tenv, useDef) == tint()) };    
    case geq(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error("Wrong types used, greater or equal operator (\>=) expects integers.", u) | !(typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(rhs, tenv, useDef) == tint()) };    
    case eq(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error("Mismatched types used, equals operator (==) expects operands of the same type, .", u) | typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) };
    case neq(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error("Mismatched types used, not equals operator (!=) expects operands of the same type, .", u) | typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) };
    case and(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error("Wrong types used, and operator (&&) expects booleans, .", u) | !(typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(rhs, tenv, useDef) == tbool()) };
    case or(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error("Wrong types used, or operator (||) expects booleans, .", u) | !(typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(rhs, tenv, useDef) == tbool()) };    

    // etc.
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(str x, src = loc u):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    case dec(_): return tint();
    case chr(_): return tstr();
    case boo(_): return tbool();
    case not(_): return tbool();
    case mul(_,_): return tint();
    case div(_,_): return tint();
    case add(_,_): return tint();
    case sub(_,_): return tint();
    case gt(_,_): return tbool();
    case lt(_,_): return tbool();
    case leq(_,_): return tbool();
    case geq(_,_): return tbool();
    case eq(_,_): return tbool();
    case neq(_,_): return tbool();
    case and(_,_): return tbool();
    case or(_,_): return tbool();
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(str x, src = loc u), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

