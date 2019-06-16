import strutils, tables

type
  MalTypeSpace* = enum Nil, True, False, String, Symbol, Integer, List, Vector, Keyword, Hashmap, Function

  MalFn* = ref object
    ast*:    MalType
    params*: MalType
    env*:    Env
    fn*:     proc(data: varargs[MalType]): MalType

  MalType* = ref object
    str*: string
    case type*: MalTypeSpace
    of Integer:                 integer*: int
    of List, Vector:            list*: seq[MalType]
    of Hashmap:                 map*: Table[string, MalType]
    of Function:                function*: MalFn
    else:                       nil

  Env* = ref object
    outer*: Env
    data*: Table[string, MalType]

proc mal_nil*(): MalType = MalType(type: Nil)
proc mal_true*(): MalType = MalType(type: True)
proc mal_false*(): MalType = MalType(type: False)

proc mal_bool*(value: bool): MalType =
  if value:
    MalType(type: True)
  else:
    MalType(type: False)

proc `==`*(a, b: MalType): bool =
  if (a.type == b.type) or
     (a.type in {List, Vector} and b.type in {List, Vector}):

    case a.type
    of Integer:                 a.integer == b.integer
    of List, Vector:            a.list == b.list
    of Hashmap:                 a.map == b.map
    of Function:                a.function.fn == b.function.fn
    of Symbol, String, Keyword: a.str == b.str
    else: true
  else:
    false

proc mal_sym*(value: string): MalType = MalType(type: Symbol, str: value)

proc mal_key*(value: string): MalType = MalType(type: Keyword, str: parseHexStr("ff") & value)

proc mal_str*(value: string): MalType = MalType(type: String, str: value)

proc mal_int*(value: int): MalType = MalType(type: Integer, integer: value)

proc mal_list*(values: varargs[MalType]): MalType = MalType(type: List, list: @values)
proc mal_list*(values: seq[MalType]): MalType = MalType(type: List, list: values)

proc mal_vec*(values: seq[MalType]): MalType = MalType(type: Vector, list: values)

proc mal_hash*(values: seq[MalType]): MalType =
  var table = initTable[string, MalType]()
  for i in countup(0, values.high, 2):
    table[values[i].str] = values[i+1]

  MalType(type: Hashmap, map: table)

proc mal_fn*(fn: proc(data: varargs[MalType]): MalType): MalType = MalType(type: Function, function: MalFn(fn: fn))
proc mal_optimized_fn*(ast, params: MalType, env: Env, fn: proc(data: varargs[MalType]): MalType): MalType =
  MalType(type: Function, function: MalFn(ast: ast, params: params, env: env, fn: fn))
