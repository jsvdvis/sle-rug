module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|, loc labelsrc = |tmp:///|, loc namesrc = |tmp:///|)
  = question(str sentence, str name, AType \type)
  | computedQuestion(str sentence, str name, AType \type, AExpr \value)
  | ifThen(AExpr condition, AQuestion then)
  | ifThenElse(AExpr condition, AQuestion then, AQuestion \else)
  | block(list[AQuestion] questions)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(str name)
  | dec(int number)
  | chr(str string)
  | boo(bool boolean)
  | not(AExpr e)
  | mul(AExpr lhs, AExpr rhs)
  | div(AExpr lhs, AExpr rhs)
  | add(AExpr lhs, AExpr rhs)
  | sub(AExpr lhs, AExpr rhs)
  | gt(AExpr lhs, AExpr rhs)
  | lt(AExpr lhs, AExpr rhs)
  | leq(AExpr lhs, AExpr rhs)
  | geq(AExpr lhs, AExpr rhs)
  | eq(AExpr lhs, AExpr rhs)
  | neq(AExpr lhs, AExpr rhs)
  | and(AExpr lhs, AExpr rhs)
  | or(AExpr lhs, AExpr rhs)
  ;

data AType(loc src = |tmp:///|)
  = integer()
  | boolean()
  | string()
  | unknown()
  ;
  
  