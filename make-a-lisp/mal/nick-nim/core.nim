import sequtils, strutils, tables

import types, printer

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

let ns* = {
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

  "list":   mal_fn list,
  "list?":  mal_fn listq,
  "empty?": mal_fn emptyq,
  "count":  mal_fn count,
}
