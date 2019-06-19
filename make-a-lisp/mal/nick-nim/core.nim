import sequtils, strutils, tables

import types, printer, reader

template sym2fnInt(sym): MalType =
  mal_fn(proc (args: varargs[MalType]): MalType =
    mal_int sym(args[0].integer, args[1].integer)
  )

template sym2fnBool(sym): MalType =
  mal_fn(proc (args: varargs[MalType]): MalType =
    if sym(args[0].integer, args[1].integer):
      mal_true()
    else:
      mal_false()
  )

proc pr_str(args: varargs[MalType]): MalType =
  mal_str @args.mapIt(pr_str(it, true)).join(" ")

proc str(args: varargs[MalType]): MalType =
  mal_str @args.mapIt(pr_str(it, false)).join("")

proc prn(args: varargs[MalType]): MalType =
  echo @args.mapIt(pr_str(it, true)).join(" ")
  mal_nil()

proc println(args: varargs[MalType]): MalType =
  echo @args.mapIt(pr_str(it, false)).join(" ")
  mal_nil()

proc list(args: varargs[MalType]): MalType = mal_list args

proc listq(args: varargs[MalType]): MalType = mal_bool args[0].type == List

proc emptyq(args: varargs[MalType]): MalType = mal_bool args[0].list.len == 0

proc count(args: varargs[MalType]): MalType =
  mal_int if args[0].type in {List, Vector}: args[0].list.len else: 0

proc eq(args: varargs[MalType]): MalType = mal_bool args[0] == args[1]

proc read_string(args: varargs[MalType]): MalType = read_str(args[0].str)

proc slurp(args: varargs[MalType]): MalType = mal_str readFile(args[0].str)

proc atom(args: varargs[MalType]): MalType = mal_atom args[0]

proc atomq(args: varargs[MalType]): MalType = mal_bool args[0].type == Atom

proc deref(args: varargs[MalType]): MalType = args[0].value

proc reset(args: varargs[MalType]): MalType =
  args[0].value = args[1]
  return args[0].value
  
proc swap(args: varargs[MalType]): MalType =
  args[0].value = args[1].function.fn(concat(@[args[0].value], args[2 .. ^1]))
  return args[0].value

proc cons(args: varargs[MalType]): MalType = mal_list concat(@[args[0]], args[1].list)

proc mal_concat(args: varargs[MalType]): MalType = 
  let lists = @args.mapIt(it.list)
  if lists.len == 0:
    return mal_list(@[])
  else: 
    return mal_list(lists.foldl(concat(a, b)))

proc nth(args: varargs[MalType]): MalType = args[0].list[args[1].integer]

proc first(args: varargs[MalType]): MalType =
  if not (args[0].type in {List, Vector}) or args[0].list.len == 0:
    mal_nil()
  else:
    args[0].list[0] 

proc rest(args: varargs[MalType]): MalType =
  if not (args[0].type in {List, Vector}) or args[0].list.len == 0:
    mal_list()
  else:
    mal_list args[0].list[1 .. ^1] 


let ns* = {
  "*ARGV*": mal_list(@[]),

  "+":  sym2fnInt(`+`),
  "-":  sym2fnInt(`-`),
  "*":  sym2fnInt(`*`),
  "/":  sym2fnInt(`div`),

  "<":  sym2fnBool(`<`),
  "<=": sym2fnBool(`<=`),
  ">":  sym2fnBool(`>`),
  ">=": sym2fnBool(`>=`),

  "=": mal_fn eq,

  "pr-str":  mal_fn pr_str,
  "str":     mal_fn str,
  "prn":     mal_fn prn,
  "println": mal_fn println,
  
  "read-string": mal_fn read_string,
  "slurp":       mal_fn slurp,

  "list":   mal_fn list,
  "list?":  mal_fn listq,
  "empty?": mal_fn emptyq,
  "count":  mal_fn count,

  "nth":   mal_fn nth,
  "first": mal_fn first,
  "rest":  mal_fn rest,

  "cons":   mal_fn cons,
  "concat": mal_fn mal_concat,

  "atom":   mal_fn atom,
  "atom?":  mal_fn atomq,
  "deref":  mal_fn deref,
  "reset!": mal_fn reset,
  "swap!":  mal_fn swap,
}
