import tables, sequtils
import types, reader, printer

proc eval_ast(ast: MalType, env: Table[string, MalType]): MalType

var repl_env = toTable({
  "+": mal_fn(proc (args: varargs[MalType]): MalType = mal_int(args[0].integer  +  args[1].integer)),
  "-": mal_fn(proc (args: varargs[MalType]): MalType = mal_int(args[0].integer  -  args[1].integer)),
  "*": mal_fn(proc (args: varargs[MalType]): MalType = mal_int(args[0].integer  *  args[1].integer)),
  "/": mal_fn(proc (args: varargs[MalType]): MalType = mal_int(args[0].integer div args[1].integer))
})

proc READ(param: string): MalType = read_str(param, false)

proc EVAL(ast: MalType, env: Table[string, MalType]): MalType =
  if ast.type == List:
    if ast.list.len > 0:
      let evaled = eval_ast(ast, env)
      evaled.list[0].function.fn(evaled.list[1 .. ^1])
    else:
      ast
  else:
    eval_ast(ast, env)

proc PRINT(param: MalType): string = pr_str(param)

proc rep(param: string): string = PRINT(EVAL(READ(param), repl_env))

proc eval_ast(ast: MalType, env: Table[string, MalType]): MalType =
  case ast.type
  of List:    mal_list ast.list.mapIt(EVAL(it, env))
  of Vector:  mal_vec ast.list.mapIt(EVAL(it, env))
  of Hashmap:
    for k, v in ast.map.pairs:
      ast.map[k] = EVAL(v, env)
    ast
  of Symbol:
    if env.hasKey(ast.str):
      env[ast.str]
    else:
      raise newException(ValueError, "Unknown symbol '" & ast.str & "' was not found")
  else: ast

var input: string
while true:
  try:
    write(stdout, "user> ")
    input = readLine(stdin)
    echo rep(input), "\n"
  except EOFError:
    break
  except ValueError:
    echo getCurrentExceptionMsg()
