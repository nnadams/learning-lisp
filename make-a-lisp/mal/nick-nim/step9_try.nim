import tables, sequtils, os
import types, reader, printer, env, core

proc eval_ast(ast: MalType, env: Env): MalType
proc quasiquote(ast: MalType): MalType
proc macroexpand(ast: MalType, env: Env): MalType

proc READ(param: string): MalType = read_str(param, false)

proc EVAL(ast: MalType, env: Env): MalType =
  var ast = ast
  var env = env

  while true:
    if ast.type != List:
      return eval_ast(ast, env)
    else:
      ast = macroexpand(ast, env)

      if not (ast.type in {List, Vector}):
        return eval_ast(ast, env)
      elif ast.list.len == 0:
        return ast
      else:
        var al = ast.list
        case al[0].str
        of "def!":
          let evl = EVAL(al[2], env)
          return env.set(al[1].str, evl)
        
        of "defmacro!":
          let evl = EVAL(al[2], env)
          evl.function.is_macro = true
          return env.set(al[1].str, evl)
        
        of "macroexpand":
          return macroexpand(al[1], env)

        of "let*":
          let bindings = al[1].list
          let new_env = env.new_inner()
          for i in countup(0, bindings.high, 2):
            new_env.set(bindings[i].str, EVAL(bindings[i+1], new_env))
          env = new_env
          ast = al[2]

        of "fn*":
          let fn = proc (args: varargs[MalType]): MalType =
                     let new_env = env.new_inner(al[1], mal_list args)
                     EVAL(al[2], new_env)
         
          return mal_optimized_fn(al[2], al[1], env, fn)

        of "do":
          discard eval_ast(mal_list al[1 .. ^2], env)
          ast = al[^1]

        of "if":
          let cond = EVAL(al[1], env)
          if cond.type in {Nil, False}:
            if al.len > 3:
              ast = al[3]
            else:
              return mal_nil()
          else:
            ast = al[2]

        of "try*":
          try:
            return EVAL(al[1], env)
          except MalException:
            if al.len > 2:
              let catch = al[2].list
              if catch[0] == mal_sym "catch*":
                let exception = (MalException)getCurrentException()
                let new_env = env.new_inner(mal_list catch[1], mal_list(exception.thrown))
                return EVAL(catch[2], new_env)
            raise getCurrentException()
          except:
            if al.len > 2:
              let catch = al[2].list
              if catch[0] == mal_sym "catch*":
                let new_env = env.new_inner(mal_list catch[1], mal_list(mal_str getCurrentExceptionMsg()))
                return EVAL(catch[2], new_env)
            raise getCurrentException()

        
        of "quasiquote": ast = quasiquote(al[1])
        of "quote": return al[1]

        else:
          let evl = eval_ast(ast, env)
          let f = evl.list[0]
          if f.type == Function:
            if f.function.env == nil:
              return f.function.fn(evl.list[1 .. ^1])
            else: # TCO
              ast = f.function.ast
              env = f.function.env.new_inner(f.function.params, mal_list evl.list[1 .. ^1])
          else:
            raise newException(ValueError, "Excepted function")


proc PRINT(param: MalType): string = pr_str(param)

proc rep(param: string, env: Env): string {.discardable.} = PRINT(EVAL(READ(param), env))

proc eval_ast(ast: MalType, env: Env): MalType =
  case ast.type
  of List:    mal_list ast.list.mapIt(EVAL(it, env))
  of Vector:  mal_vec ast.list.mapIt(EVAL(it, env))
  of Hashmap:
    let hm = mal_hash()
    for k, v in ast.map.pairs:
      let key = EVAL(k, env)
      let value = EVAL(v, env)
      hm.map[key] = value
    hm
  of Symbol: env.get(ast.str)
  else: ast

proc is_pair(param: MalType): bool = param.type in {List, Vector} and param.list.len > 0

proc is_macro_call(ast: MalType, env: Env): bool =
  result = false
  if ast.type == List and ast.list.len > 0:
    if ast.list[0].type == Symbol:
      let found_env = env.find(ast.list[0].str)
      if found_env != nil:
        let f = found_env.get(ast.list[0].str)
        if f.type == Function and f.function.is_macro:
          result = true

proc macroexpand(ast: MalType, env: Env): MalType =
  result = ast
  while result.is_macro_call(env):
    let f = env.get(ast.list[0].str)
    if f.type != Nil:
      result = macroexpand(f.function.fn(ast.list[1 .. ^1]), env)

proc quasiquote(ast: MalType): MalType =
  if not is_pair(ast):
    return mal_list(@[mal_sym "quote", ast])

  let al = ast.list
  if al[0] == mal_sym "unquote":
    return al[1]
  elif is_pair(al[0]) and al[0].list[0] == mal_sym "splice-unquote":
    return mal_list(@[mal_sym "concat", al[0].list[1], quasiquote(mal_list al[1 .. ^1])])
  else:
    return mal_list(@[mal_sym "cons", quasiquote(al[0]), quasiquote(mal_list al[1 .. ^1])])

#proc handler() {.noconv.} =
#  raise newException(EOFError, "Keyboard Interrupt")
#setControlCHook(handler)

var repl_env = Env(outer: nil, data: initTable[string, MalType]())
for sym, fn in ns.items:
  repl_env.set(sym, fn)

repl_env.set("eval", mal_fn(proc(args: varargs[MalType]): MalType = EVAL(args[0], repl_env)))

rep("""(def! not (fn* (a) (if a false true)))""", repl_env)
rep("""(def! load-file (fn* (f) (eval (read-string (str "(do " (slurp f) ")")))))""", repl_env)
rep("""(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw "odd number of forms to cond")) (cons 'cond (rest (rest xs)))))))""", repl_env)
rep("""(defmacro! or (fn* (& xs) (if (empty? xs) nil (if (= 1 (count xs)) (first xs) `(let* (or_FIXME ~(first xs)) (if or_FIXME or_FIXME (or ~@(rest xs))))))))""", repl_env)

let args = commandLineParams()
if paramCount() > 0:
  repl_env.set("*ARGV*", mal_list args[1 .. ^1].map(mal_str))
  discard rep("(load-file \"" & args[0] & "\")", repl_env)
else:
  var input: string
  while true:
    try:
      write(stdout, "user> ")
      input = readLine(stdin)
      echo rep(input, repl_env), "\n"
    except EOFError:
      break
    except MalException:
      let exception = (MalException)getCurrentException()
      echo "Exception: " & pr_str(exception.thrown) & "\n"
    except ValueError, IOError, FieldError, IndexError:
      echo getCurrentExceptionMsg() & "\n"
