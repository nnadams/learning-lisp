import tables, sequtils
import types, reader, printer, env

proc eval_ast(ast: MalType, env: Env): MalType

proc READ(param: string): MalType = read_str(param, false)

proc EVAL(ast: MalType, env: Env): MalType =
  if ast.type != List:
    return eval_ast(ast, env)
  else:
    if ast.list.len == 0:
      return ast
    else:
      case ast.list[0].str
      of "def!":
        let evaled = EVAL(ast.list[2], env)
        env.set(ast.list[1].str, evaled)
        return evaled
      of "let*":
        let bindings = ast.list[1].list
        let new_env = env.new_inner()
        for i in countup(0, bindings.high, 2):
          new_env.set(bindings[i].str, EVAL(bindings[i+1], new_env))
        return EVAL(ast.list[2], new_env)
      else:
        let evaled = eval_ast(ast, env)
        return evaled.list[0].function.fn(evaled.list[1 .. ^1])

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
repl_env.set("+", mal_fn(proc (args: varargs[MalType]): MalType = mal_int(args[0].integer   +  args[1].integer)))
repl_env.set("-", mal_fn(proc (args: varargs[MalType]): MalType = mal_int(args[0].integer   -  args[1].integer)))
repl_env.set("*", mal_fn(proc (args: varargs[MalType]): MalType = mal_int(args[0].integer   *  args[1].integer)))
repl_env.set("/", mal_fn(proc (args: varargs[MalType]): MalType = mal_int(args[0].integer  div  args[1].integer)))

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
