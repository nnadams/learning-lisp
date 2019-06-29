import sequtils, strutils, tables, hashes
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

proc nilq(args: varargs[MalType]): MalType = mal_bool args[0].type == Nil
proc trueq(args: varargs[MalType]): MalType = mal_bool args[0].type == True
proc falseq(args: varargs[MalType]): MalType = mal_bool args[0].type == False
proc symbolq(args: varargs[MalType]): MalType = mal_bool args[0].type == Symbol

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
    return mal_list()
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

proc throw(args: varargs[MalType]): MalType =
  raise MalException(thrown: args[0])

proc apply(args: varargs[MalType]): MalType =
  var arglist: seq[MalType] = @[]
  for i in countup(1, args.high - 1):
    arglist.add(args[i])
  arglist = concat(arglist, args[^1].list)

  args[0].function.fn(arglist)

proc map(args: varargs[MalType]): MalType =
  result = mal_list()
  for element in args[1].list:
    result.list.add(args[0].function.fn(element))

proc symbol(args: varargs[MalType]): MalType = mal_sym args[0].str

proc keyword(args: varargs[MalType]): MalType =
  if args[0].type == Keyword: args[0]
  else: mal_key args[0].str

proc keywordq(args: varargs[MalType]): MalType = mal_bool args[0].type == Keyword

proc vector(args: varargs[MalType]): MalType = mal_vec @args

proc vectorq(args: varargs[MalType]): MalType = mal_bool args[0].type == Vector

proc sequentialq(args: varargs[MalType]): MalType = mal_bool args[0].type in {List, Vector}

proc hash_map(args: varargs[MalType]): MalType = mal_hash @args

proc mapq(args: varargs[MalType]): MalType = mal_bool args[0].type == Hashmap

proc assoc(args: varargs[MalType]): MalType =
  result = mal_hash()
  result.map = args[0].map
  for i in countup(1, args.high, 2):
    result.map[args[i]] = args[i+1]

proc dissoc(args: varargs[MalType]): MalType =
  result = mal_hash()
  result.map = args[0].map
  for i in countup(1, args.high):
    result.map.del(args[i])

proc hash_get(args: varargs[MalType]): MalType =
  if args[0].type == Hashmap and args[1] in args[0].map:
    args[0].map[args[1]]
  else:
    mal_nil()

proc containsq(args: varargs[MalType]): MalType = mal_bool args[0].map.hasKey(args[1])

proc hash_keys(args: varargs[MalType]): MalType = 
  result = mal_list()
  for key in args[0].map.keys:
    result.list.add(key)

proc hash_vals(args: varargs[MalType]): MalType = 
  result = mal_list()
  for value in args[0].map.values:
    result.list.add(value)

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

  "=":           mal_fn eq,

  "pr-str":      mal_fn pr_str,
  "str":         mal_fn str,
  "prn":         mal_fn prn,
  "println":     mal_fn println,
  
  "read-string": mal_fn read_string,
  "slurp":       mal_fn slurp,

  "list":        mal_fn list,
  "list?":       mal_fn listq,
  "empty?":      mal_fn emptyq,
  "count":       mal_fn count,

  "nil?":        mal_fn nilq,
  "true?":       mal_fn trueq,
  "false?":      mal_fn falseq,
  "symbol?":     mal_fn symbolq,

  "nth":         mal_fn nth,
  "first":       mal_fn first,
  "rest":        mal_fn rest,

  "cons":        mal_fn cons,
  "concat":      mal_fn mal_concat,

  "atom":        mal_fn atom,
  "atom?":       mal_fn atomq,
  "deref":       mal_fn deref,
  "reset!":      mal_fn reset,
  "swap!":       mal_fn swap,

  "throw":       mal_fn throw,
  "apply":       mal_fn apply,
  "map":         mal_fn map,

  "symbol":      mal_fn symbol,
  "keyword":     mal_fn keyword,
  "keyword?":    mal_fn keywordq,
  "vector":      mal_fn vector,
  "vector?":     mal_fn vectorq,
  "sequential?": mal_fn sequentialq,
  "hash-map":    mal_fn hash_map,
  "map?":        mal_fn mapq,
  "assoc":       mal_fn assoc,
  "dissoc":      mal_fn dissoc,
  "get":         mal_fn hash_get,
  "contains?":   mal_fn containsq,
  "keys":        mal_fn hash_keys,
  "vals":        mal_fn hash_vals,
}
