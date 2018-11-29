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

data AQuestion(loc src = |tmp:///|)
  = question(str sentence, AExpr variable, AType answer)
  | question(str sentence, AExpr variable, AType answer, AExpr assignment)
  | question(AExpr condition, AQuestion quest)
  | question(AExpr condition, AQuestion questTrue, AQuestion questFalse)
  | question(list[AQuestion] questions)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(str name)
  | expr(num number)
  | expr(AExpr exprSingle)
  | expr(str operator, AExpr lhs, AExpr rhs)
  ;

data AType(loc src = |tmp:///|)
  = \type(str name)
  ;
  
  