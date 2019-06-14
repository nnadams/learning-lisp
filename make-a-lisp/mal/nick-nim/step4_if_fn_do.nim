import tables, sequtils
import types, reader, printer, env, core

proc eval_ast(ast: MalType, env: Env): MalType

proc READ(param: string): MalType = read_str(param, false)

proc EVAL(ast: MalType, env: Env): MalType =
  if ast.type != List:
    result = eval_ast(ast, env)
  else:
    var al = ast.list
    if al.len == 0:
      result = ast
    else:
      case al[0].str
      of "def!":
        let evaled = EVAL(al[2], env)
        env.set(al[1].str, evaled)
        result = evaled

      of "let*":
        let bindings = al[1].list
        let new_env = env.new_inner()
        for i in countup(0, bindings.high, 2):
          new_env.set(bindings[i].str, EVAL(bindings[i+1], new_env))
        result = EVAL(al[2], new_env)

      of "fn*":
        result = mal_fn(proc (args: varargs[MalType]): MalType =
                          let new_env = env.new_inner(al[1], mal_list args)
                          EVAL(al[2], new_env)
                 )

      of "do":
        result = eval_ast(mal_list al[1 .. ^1], env).list[^1]

      of "if":
        let cond = EVAL(al[1], env)
        if cond.type in {Nil, False}:
          if al.len > 3:
            result = EVAL(al[3], env)
          else:
            result = mal_nil()
        else:
          result = EVAL(al[2], env)

      else:
        let evaled = eval_ast(ast, env)
        result = evaled.list[0].fn(evaled.list[1 .. ^1])

proc PRINT(param: MalType): string = pr_str(param)

proc rep(param: string, env: Env): string = PRINT(EVAL(READ(param), env))

proc eval_ast(ast: MalType, env: Env): MalType =
  case ast.type
  of List:    mal_list ast.list.mapIt(EVAL(it, env))
  of Vector:  mal_vec ast.list.mapIt(EVAL(it, env))
  of Hashmap:
    for k, v in ast.map.pairs:
      ast.map[k] = EVAL(v, env)
    ast
  of Symbol: env.get(ast.str)
  else: ast

var repl_env = Env(outer: nil, data: initTable[string, MalType]())
for sym, fn in ns.items:
  repl_env.set(sym, fn)

discard rep("(def! not (fn* (a) (if a false true)))", repl_env)

var input: string
while true:
  try:
    write(stdout, "user> ")
    input = readLine(stdin)
    echo rep(input, repl_env), "\n"
  except EOFError:
    break
  except ValueError:
    echo getCurrentExceptionMsg()
