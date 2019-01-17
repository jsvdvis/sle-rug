module Syntax

extend lang::std::Layout;
extend lang::std::Id;



/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 


syntax Question
  = Str Id ":" Type !>> "="
  | ComputedQuestion
  | "if" "(" Expr ")" Question !>> "else"
  | "if" "(" Expr ")" Question "else" Question
  | "{" Question+ "}"
  ; 
  
syntax ComputedQuestion
  = Str Id ":" Type "=" Expr;


syntax Expr 
  = var: Id \ "true" \ "false" // true/false are reserved keywords.
  | dec: Int
  | \str: Str
  | boo: Bool
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
  > non-assoc (
      gt: Expr "\>" Expr
    | lt: Expr "\<" Expr
    | leq: Expr "\<=" Expr
    | geq: Expr "\>=" Expr
  )
  > non-assoc (
      eq: Expr "==" Expr
    | neq: Expr "!=" Expr
  )
  > left and: Expr "&&" Expr
  > left or: Expr "||" Expr
  ;
  
  
syntax Type
  = "integer" | "boolean" | "string";  
  
lexical Str = "\"" ![\"]* "\"";

lexical Int 
  = [+\-]? [0-9]+ !>>[0-9];

lexical Bool = "true"|"false";


