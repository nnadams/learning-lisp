import sequtils, strutils

import types

proc pr_str*(data: MalType): string =
  case data.type
  of Nil:     "nil"
  of True:    "true"
  of False:   "false"
  of Integer: $(data.integer)
  of Keyword: data.str[1 .. ^1]
  of List:    "(" & data.list.mapIt(pr_str(it)).join(" ") & ")"
  of Hashmap: "{" & data.list.mapIt(pr_str(it)).join(" ") & "}"
  of Vector:  "[" & data.list.mapIt(pr_str(it)).join(" ") & "]"
  else:       data.str
