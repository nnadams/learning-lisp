import tables

import types

type
  Env* = ref object
    outer*: Env
    data*: Table[string, MalType]

proc set*(env: Env, sym: string, value: MalType) =
  env.data[sym] = value

proc find*(env: Env, sym: string): Env =
  if env.data.hasKey(sym):
    return env
  else:
    if env.outer == nil:
      return nil
    else:
      return env.outer.find(sym)

proc get*(env: Env, sym: string): MalType =
  let matching_env = env.find(sym)
  if matching_env == nil:
    raise newException(ValueError, "Unknown symbol '" & sym & "' not found.")
  else:
    matching_env.data[sym]

proc new_inner*(env: Env): Env =
  Env(outer: env, data: initTable[string, MalType]())

proc new_inner*(env: Env, binds: MalType, exprs: MalType): Env =
  let new_env = env.new_inner()
  if binds.type in {List, Vector} and exprs.type in {List, Vector}:
    for i in 0..binds.list.high:
      if binds.list[i].str == "&":
        new_env.set(binds.list[i+1].str, mal_list exprs.list[i .. ^1])
        break
      else:
        new_env.set(binds.list[i].str, exprs.list[i])
  return new_env
