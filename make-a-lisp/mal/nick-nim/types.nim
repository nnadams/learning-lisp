import strutils, tables

type
  MalTypeSpace* = enum Nil, True, False, String, Symbol, Integer, List, Vector, Keyword, Hashmap, Function

  MalType* = ref object
    case type*: MalTypeSpace
    of Nil, True, False:        nil
    of String, Symbol, Keyword: str*: string
    of Integer:                 integer*: int
    of List, Vector:            list*: seq[MalType]
    of Hashmap:                 map*: Table[string, MalType]
    of Function:                fn*: proc(data: varargs[MalType]): MalType

proc mal_nil*(): MalType = MalType(type: Nil)
proc mal_true*(): MalType = MalType(type: True)
proc mal_false*(): MalType = MalType(type: False)

proc mal_bool*(value: bool): MalType =
  if value:
    MalType(type: True)
  else:
    MalType(type: False)

proc mal_sym*(value: string): MalType = MalType(type: Symbol, str: value)

proc mal_key*(value: string): MalType = MalType(type: Keyword, str: parseHexStr("ff") & value)

proc mal_str*(value: string): MalType = MalType(type: String, str: value)

proc mal_int*(value: int): MalType = MalType(type: Integer, integer: value)

proc mal_list*(values: seq[MalType]): MalType = MalType(type: List, list: values)

proc mal_vec*(values: seq[MalType]): MalType = MalType(type: Vector, list: values)

proc mal_hash*(values: seq[MalType]): MalType =
  var table = initTable[string, MalType]()
  for i in countup(0, values.high, 2):
    if values[i].type == Keyword:
      table[values[i].str[1 .. ^1]] = values[i+1]
    else:
      table[values[i].str] = values[i+1]

  MalType(type: Hashmap, map: table)

proc mal_fn*(value: proc(data: varargs[MalType]): MalType): MalType = MalType(type: Function, fn: value)
