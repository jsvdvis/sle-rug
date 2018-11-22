module Syntax

extend lang::std::Layout;
extend lang::std::Id;


//layout MyLayout = [\t\n\ \r\f]*;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = Str Id ":" Type !>> "="
  | ComputedQuestion
  | "if" "(" Expr ")" Question !>> "else"
  | "if" "(" Expr ")" Question "else" Question
  | "{" Question+ "}"
  ; 
  
syntax ComputedQuestion
  = Str Id ":" Type "=" Expr;

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = var: Id \ "true" \ "false" // true/false are reserved keywords.
  | dec: Num
  | bracket bra: "(" Expr ")"
  | not: "!" !>> [=] Expr
  > left(
      mul: Expr "*" Expr
    | div: Expr "/" Expr
  )
  > left( 
      add: Expr "+" Expr
    | sub: Expr "-" Expr
  )
  > left (
      gt: Expr "\>" Expr
    | lt: Expr "\<" Expr
    | leq: Expr "\<=" Expr
    | geq: Expr "\>=" Expr
  )
  > left (
      eq: Expr "==" Expr
    | neq: Expr "!=" Expr
  )
  > left and: Expr "&&" Expr
  > left or: Expr "||" Expr
  ;
  
syntax Num
  = [+\-]? [0-9]+ !>>[0-9];  
  
syntax Type
  = Str | Int | Bool;  
  
lexical Str = "\"" ![\"]* "\"";

lexical Int 
  = "integer";

lexical Bool = "boolean";



