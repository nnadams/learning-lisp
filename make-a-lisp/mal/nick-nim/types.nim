import strutils, tables, hashes

type
  MalTypeSpace* = enum Nil, True, False, String, Symbol, Integer, List, Vector, Keyword, Hashmap, Function, Atom

  MalFuncType* = proc(data: varargs[MalType]): MalType

  MalFn* = ref object
    ast*:    MalType
    params*: MalType
    env*:    Env
    fn*:     MalFuncType
    is_macro*: bool

  MalType* = ref object
    str*: string
    case type*: MalTypeSpace
    of Integer:                 integer*: int
    of List, Vector:            list*: seq[MalType]
    of Hashmap:                 map*: Table[MalType, MalType]
    of Function:                function*: MalFn
    of Atom:                    value*: MalType
    else:                       discard

  Env* = ref object
    outer*: Env
    data*: Table[string, MalType]
  
  MalException* = ref object of Exception
    thrown*: MalType

proc `==`*(a, b: MalType): bool
proc hash*(obj: MalType): Hash

proc hash*[A, B](table: Table[A, B]): Hash =
  result = 0
  for k, v in table.pairs:
    result = k.hash !& v.hash
  result = !$result

proc hash*(obj: MalType): Hash =
  case obj.type
  of List, Vector:             !$obj.list.hash  # Compare list add vectors only by elements`
  of Integer:                  !$obj.integer.hash
  of Hashmap:                  !$obj.map.hash
  of Function:                 !$obj.function.fn.hash
  of Atom:                     !$(obj.type.hash !& obj.value.hash)
  of Symbol, String, Keyword:  !$obj.str.hash
  else:                        !$obj.type.hash

proc map_eq(a, b: MalType): bool =
  if a.map.len == b.map.len:
    for k, v in a.map.pairs:
      if not b.map.hasKey(k) or b.map[k] != v:
        return false
    return true
  else:
    return false

proc `==`*(a, b: MalType): bool =
  if (a.type == b.type) or
     (a.type in {List, Vector} and b.type in {List, Vector}):

    case a.type
    of Atom:                    a.value == b.value
    of Integer:                 a.integer == b.integer
    of List, Vector:            a.list == b.list
    of Function:                a.function.fn == b.function.fn
    of Symbol, String, Keyword: a.str == b.str
    of Hashmap:                 map_eq(a, b)
    else: true
  else:
    false

proc mal_nil*(): MalType = MalType(type: Nil)
proc mal_true*(): MalType = MalType(type: True)
proc mal_false*(): MalType = MalType(type: False)

proc mal_bool*(value: bool): MalType =
  if value: MalType(type: True)
  else:     MalType(type: False)

proc mal_sym*(value: string): MalType = MalType(type: Symbol, str: value)
proc mal_str*(value: string): MalType = MalType(type: String, str: value)
proc mal_int*(value: int): MalType = MalType(type: Integer, integer: value)
proc mal_atom*(value: MalType): MalType = MalType(type: Atom, value: value)
proc mal_key*(value: string): MalType = MalType(type: Keyword, str: parseHexStr("ff") & value)

proc mal_list*(values: varargs[MalType]): MalType = MalType(type: List, list: @values)
proc mal_list*(values: seq[MalType]): MalType = MalType(type: List, list: values)
proc mal_list*(value: MalType): MalType = MalType(type: List, list: @[value])

proc mal_vec*(values: varargs[MalType]): MalType = MalType(type: Vector, list: @values)
proc mal_vec*(values: seq[MalType]): MalType = MalType(type: Vector, list: values)
proc mal_vec*(value: MalType): MalType = MalType(type: Vector, list: @[value])

proc mal_hash*(): MalType = MalType(type: Hashmap, map: initTable[MalType, MalType]())
proc mal_hash*(values: seq[MalType]): MalType =
  var table = initTable[MalType, MalType]()
  for i in countup(0, values.high, 2):
    table[values[i]] = values[i+1]

  result = MalType(type: Hashmap, map: table)

proc mal_fn*(fn: MalFuncType, is_macro: bool = false): MalType = MalType(type: Function, function: MalFn(fn: fn, is_macro: is_macro))
proc mal_optimized_fn*(ast, params: MalType, env: Env, fn: MalFuncType, is_macro: bool = false): MalType =
  MalType(type: Function, function: MalFn(ast: ast, params: params, env: env, fn: fn, is_macro: is_macro))
