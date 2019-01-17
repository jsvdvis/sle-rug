module Eval

import AST;
import Resolve;

import IO;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  VEnv env = ();
  for (/AQuestion q := f) {
    if (q is question || q is computedQuestion) {
      switch (q.\type) {
      	case integer(): env[q.name] = vint(0);
      	case boolean(): env[q.name] = vbool(false);
      	case string(): env[q.name] = vstr("");
      }
    }
  }
  return env;
}


// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  return (venv | eval(q, inp, it) | AQuestion q <- f.questions ); 
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  switch(q) {
  	case question(_, name,_): 
  	  if (name == inp.question) venv[inp.question] = inp.\value;
  	case computedQuestion(_, name,_, \value): 
  	  venv[name] = eval(\value, venv);
  	case ifThen(condition, then): 
  	  if (eval(condition, venv) == vbool(true)) 
  	    venv = eval(then, inp, venv);
  	case ifThenElse(condition, then, \else): 
  	  if (eval(condition, venv) == vbool(true)) 
  	    venv = eval(then, inp, venv); 
  	  else 
  	    venv = eval(\else, inp, venv);
  	case block(questions): 
  	  return ( venv | eval(aq, inp, it) | AQuestion aq <- questions );
  }
  return venv; 
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(str x): return venv[x];
    case dec(int n): return vint(n);
    case chr(str s): return vstr(s[1..-1]); // This is to remove \" \" from strings, makes the interpreter more user-friendly
    case boo(bool b): return vbool(b);
    case not(AExpr a): return (eval(a, venv).b ? vbool(false) : vbool(true));
    case mul(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n * eval(rhs, venv).n);
    case div(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n / eval(rhs, venv).n);
    case add(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n + eval(rhs, venv).n);
    case sub(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n - eval(rhs, venv).n);
    case gt(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv) > eval(rhs, venv));
    case lt(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv) < eval(rhs, venv));
    case leq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv) <= eval(rhs, venv));
    case geq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv) >= eval(rhs, venv));
    case eq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv) == eval(rhs, venv));
    case neq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv) != eval(rhs, venv));
    case and(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b && eval(rhs, venv).b);
    case or(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b || eval(rhs, venv).b);

    default: throw "Unsupported expression <e>";
  }
}