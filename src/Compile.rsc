module Compile

import AST;
import Resolve;
import IO;
import HTML5DOM; // see standard library


/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

// Extra required attributes
HTML5Attr v_if(value val) = html5attr("v-if", val);
HTML5Attr v_for(value val) = html5attr("v-for", val);
HTML5Attr v_else_if(value val) = html5attr("v-else-if", val);
HTML5Attr v_else() = html5attr("v-else", "");
HTML5Attr v_model(value val) = html5attr("v-model", val);


HTML5Attr v_bind_for(value val) = html5attr(":for", val);
HTML5Attr v_bind_key(value val) = html5attr(":key", val);
HTML5Attr v_bind_id(value val) = html5attr(":id", val);
HTML5Attr v_bind_name(value val) = html5attr(":name", val);



void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}


HTML5Node form2html(AForm f) {
  return 
  html(
  	head(
  	  meta(
  		charset("UTF-8")
  	  ),
  	  script(
  	    \type("text/javascript"),
  		src("https://cdn.jsdelivr.net/npm/vue/dist/vue.js")
  	  ),
  	  title(
  		f.name
  	  )
    ),
    body(
      div(
        id("app"),
        form(
          template(
            v_for("(q, id) in questions"),
            div(
              v_if("$root[\'_condition_\'+q.name] == true"),
              v_bind_key("id"),
              p("{{ q.sentence }}"),
              
              div(
                v_if("q.computed"),
                div(
                  v_if("q.type==\'boolean\'"),
                  input(
                    \type("radio"),
                    v_bind_id("\'boolTrue_\' + id"),
                    v_bind_name("\'boolQuestion_\' + id"),
                    \value("true"),
                    v_model("$root[\'_computed_\' + q.name]"),
                    disabled("true")
                  ),
                  label(
                    v_bind_for("\'boolTrue_\' + id"),
                    "Yes"
                  ),
                  input(
                    \type("radio"),
                    v_bind_id("\'boolFalse_\' + id"),
                    v_bind_name("\'boolQuestion_\' + id"),
                    \value("false"),
                    v_model("$root[\'_computed_\' + q.name]"),
                    disabled("true")
                  ),
                  label(
                    v_bind_for("\'boolFalse_\' + id"),
                    "No"
                  )
                ),
                div(
                  v_else_if("q.type==\'integer\'"),
                  label(
                    v_bind_for("\'number_\' + id"),
                    "Number: "
                  ),
                  input(
                    \type("number"),
                    v_bind_id("\'number_\' + id"),
					v_model("$root[\'_computed_\' + q.name]"),
					disabled("true")
                  )
                ),
                div(
                  v_else(),
                  label(
                    v_bind_for("\'string_\' + id"),
                    "String: "
                  ),
                  input(
                    \type("text"),
					v_bind_id("\'string_\' + id"),
					v_model("$root[\'_computed_\' + q.name]"),
					disabled("true")
                  )
                ) 
              ),
              
              div(
                v_else(),
                div(
                  v_if("q.type==\'boolean\'"),
                  input(
                    \type("radio"),
                    v_bind_id("\'boolTrue_\' + id"),
                    v_bind_name("\'boolQuestion_\' + id"),
                    \value("true"),
                    v_model("env[q.name]")
                  ),
                  label(
                    v_bind_for("\'boolTrue_\' + id"),
                    "Yes"
                  ),
                  input(
                    \type("radio"),
                    v_bind_id("\'boolFalse_\' + id"),
                    v_bind_name("\'boolQuestion_\' + id"),
                    \value("false"),
                    v_model("env[q.name]")
                  ),
                  label(
                    v_bind_for("\'boolFalse_\' + id"),
                    "No"
                  )
                ),
                div(
                  v_else_if("q.type==\'integer\'"),
                  label(
                    v_bind_for("\'number_\' + id"),
                    "Number: "
                  ),
                  input(
                    \type("number"),
                    v_bind_id("\'number_\' + id"),
					v_model("env[q.name]")
                  )
                ),
                div(
                  v_else(),
                  label(
                    v_bind_for("\'string_\' + id"),
                    "String: "
                  ),
                  input(
                    \type("text"),
					v_bind_id("\'string_\' + id"),
					v_model("env[q.name]")
                  )
                )                
              )
            )
          ),
          button(
            \type("button"),
            "Submit"
          )
        )
      ),
      script(
      	src(f.src.file[0..-4] + "js")
      )
    )		
  );
}

str form2js(AForm f) {
  return "new Vue({
  '  el: \"#app\",
  '  data: {
  '    <formGetEnv(f)>
  '    <formGetQuestions(f)>
  '  },
  '  computed: {
  '     <formGetConditionals(f)>
  '     <formGetComputed(f)>
  '  },
  '  methods: {
  '    isTrue(variable) {
  '      if (this.env[variable] == undefined) return undefined;
  '      return this.env[variable] === \"true\";
  '    },
  '    not(boolean) {
  '      if (boolean == undefined) return undefined;
  '      return !boolean;
  '    },
  '  },
  '})";
}

str formGetEnv(AForm f) {
  return "env: {
  '<for (/AQuestion q := f) {> 
    '<questionGetEnv(q)> 
  '<}>},";
}

str questionGetEnv(AQuestion q) {
	return "<if ((q is question) || (q is computedQuestion)) {> 
	'  <q.name>: <getTypeDefault(q.\type)>,
	'<}>";
}

str getTypeDefault(AType \type) {
  switch(\type) {
    case integer(): return "undefined";
    case boolean(): return "undefined";
    case string(): return "undefined";
    default: return "\"\"";
  } 
}

str formGetQuestions(AForm f) {
  return "questions: [
  '<for (/AQuestion q := f) {>
    '<if (q is question || q is computedQuestion) {>
  	'  <questionGetQuestion(q)>
    '<}>
  '<}>  
  '],";
}

str questionGetQuestion(AQuestion q) {
  return "{
  '  name: \"<q.name>\",
  '  sentence: <q.sentence>,
  '  type: \"<questionGetType(q)>\",
  '  computed: <q is computedQuestion>,
  '},";
}

str questionGetType(AQuestion q) {
  switch(q.\type) {
    case integer(): return "integer";
    case boolean(): return "boolean";
    case string(): return "string";
  }
}

str formGetConditionals(AForm f) {
  return "
  ' <for (AQuestion q <- f.questions) {><questionGetConditionals(q, "", f)><}> 
  ";
}

str questionGetConditionals(AQuestion q, str conditionals, AForm f) {
  switch(q) {
    case ifThen(condition, then): return questionGetConditionals(then, addCondition(conditionals, expression2js(condition, f)), f);
    case ifThenElse(condition, then, \else): return questionGetConditionals(then, addCondition(conditionals, expression2js(condition, f)), f)
                                                  + questionGetConditionals(\else, addCondition(conditionals, "this.not(" + expression2js(condition, f) + ")"), f);
    case block(questions): return ( "" | it + questionGetConditionals(qq, conditionals, f) | qq <- questions );
    default: return "_condition_<q.name>() {
                          '  return <if (conditionals == "") {>true<} else {><conditionals><}>;
                          '},
                          '";                         
  }
}

str expression2js(AExpr e, AForm f) {
  switch (e) {
    case ref(n): if (isBoolean(n, f)) return "this.isTrue(\"<n>\")"; else return "this.env.<n>"; 
    case dec(n): return "<n>";
    case chr(n): return "<n>";
    case boo(n): return "<n>";
    case not(n): return "this.not(<expression2js(n, f)>)";
    default: return "<expression2js(e.lhs, f)> <operator2str(e)> <expression2js(e.rhs, f)>";
  }
}

str addCondition(str first, str second) {
  return (first == "" ? second : first + " && " + second);
}

str operator2str(AExpr e) {
  switch(e) {
    case mul(_,_): return "*";
    case div(_,_): return "/";
    case add(_,_): return "+";
    case sub(_,_): return "-";
    case gt(_,_): return "\>";
    case lt(_,_): return "\<";
    case leq(_,_): return "\<=";
    case geq(_,_): return "\>=";
    case eq(_,_): return "===";
    case neq(_,_): return "!==";
    case and(_,_): return "&&";
    case or(_,_): return "||";
  }
}

bool isBoolean(str n, AForm f) {
  for (/AQuestion q := f) {
  	if ((q is question || q is computedQuestion) && (q.name == n)) {
  	  return (q.\type is boolean);
  	}  	
  }
  return false;
}

str formGetComputed(AForm f) {
  return "<for (/AQuestion q := f) {><if (q is computedQuestion) {><questionGetComputed(q, f)><}><}>";
}

str questionGetComputed(AQuestion q, AForm f) {
  return "_computed_<q.name>() {
  '  return (this.env.<q.name> = <expression2js(q.\value, f)>);
  '},
  '";
}