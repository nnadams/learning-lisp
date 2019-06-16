import tables, sequtils
import types, reader, printer, env, core

proc eval_ast(ast: MalType, env: Env): MalType

proc READ(param: string): MalType = read_str(param, false)

proc EVAL(ast: MalType, env: Env): MalType =
  var ast = ast
  var env = env

  while true:
    if ast.type != List:
      return eval_ast(ast, env)
    else:
      var al = ast.list
      if al.len == 0:
        return ast
      else:
        case al[0].str
        of "def!":
          let evl = EVAL(al[2], env)
          env.set(al[1].str, evl)
          return evl

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
          ast = eval_ast(mal_list al[1 .. ^2], env).list[^1]

        of "if":
          let cond = EVAL(al[1], env)
          if cond.type in {Nil, False}:
            if al.len > 3:
              ast = al[3]
            else:
              return mal_nil()
          else:
            ast = al[2]

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
