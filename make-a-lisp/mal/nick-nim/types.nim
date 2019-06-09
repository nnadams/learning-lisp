import strutils

type
  MalTypeSpace* = enum Nil, True, False, String, Symbol, Integer, List, Vector, Keyword, Hashmap

  MalType* = ref object
    case type*: MalTypeSpace
    of Nil, True, False:        nil
    of String, Symbol, Keyword: str*: string
    of Integer:                 integer*: int
    of List, Vector, Hashmap:   list*: seq[MalType]

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
proc mal_int*(value: string): MalType = MalType(type: Integer, integer: parseInt(value))

proc mal_list*(value: seq[MalType]): MalType = MalType(type: List, list: value)

proc mal_vec*(value: seq[MalType]): MalType = MalType(type: Vector, list: value)

proc mal_hash*(value: seq[MalType]): MalType = MalType(type: Hashmap, list: value)
