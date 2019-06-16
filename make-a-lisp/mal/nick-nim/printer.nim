import sequtils, strutils, tables

import types

proc readable_string(str: string, print_readably = true): string =
  if str.startsWith(parseHexStr("ff")):
    result = ":" & str[1 .. ^1]
  elif print_readably:
    result = "\"" & str.replace("\\", "\\\\").replace("\n", "\\n").replace("\"", "\\\"") & "\""
  else:
    result = str

proc pr_str*(data: MalType, print_readably = true): string =
  case data.type
  of Nil:      result = "nil"
  of True:     result = "true"
  of False:    result = "false"
  of Integer:  result = $(data.integer)
  of Symbol:   result = data.str
  of Atom:     result = "(atom " & pr_str(data.value) & ")"
  of Function: result = "#<function>"
  of List:     result = "(" & data.list.mapIt(pr_str(it, print_readably)).join(" ") & ")"
  of Vector:   result = "[" & data.list.mapIt(pr_str(it, print_readably)).join(" ") & "]"
  of Hashmap:
    result = "{"
    for k,v in data.map.pairs:
      result &= readable_string(k) & " " & pr_str(v)
    result &= "}"
  else: result = readable_string(data.str, print_readably)
