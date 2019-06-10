import sequtils, strutils, tables

import types

proc pr_str*(data: MalType): string =
  case data.type
  of Nil:     result = "nil"
  of True:    result = "true"
  of False:   result = "false"
  of Integer: result = $(data.integer)
  of Keyword: result = data.str[1 .. ^1]
  of List:    result = "(" & data.list.mapIt(pr_str(it)).join(" ") & ")"
  of Vector:  result = "[" & data.list.mapIt(pr_str(it)).join(" ") & "]"
  of Hashmap:
    result = "{"
    for k,v in data.map.pairs:
      result &= k & " " & pr_str(v)
    result &= "}"
  else: result = data.str
