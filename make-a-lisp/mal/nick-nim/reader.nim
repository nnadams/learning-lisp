import nre
import strutils

import types

type Reader = ref object
    tokens: seq[string]
    pos: int

proc read_atom(r: Reader): MalType
proc read_list(r: Reader): MalType
proc read_vector(r: Reader): MalType
proc read_hashmap(r: Reader): MalType
proc read_seq(r: Reader, end_token: string): seq[MalType]
proc read_transforms(r: Reader): MalType

proc next(r: Reader): string =
  if r.tokens.len < 1:
    return ""

  let token = r.tokens[r.pos]
  r.pos += 1
  return token

proc peek(r: Reader): string =
  if r.tokens.len < 1 or r.pos >= r.tokens.len:
    return nil
  else:
    return r.tokens[r.pos]

proc tokenize(input: string): seq[string] =
  let pattern = re"""[\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"?|;.*|[^\s\[\]{}('"`,;)]*)"""
  result = @[]
  for match in input.findIter(pattern):
    let token = match.captures[0]
    if len(token) > 0 and not token.startsWith(";"):
        result.add token

proc read_from(r: Reader): MalType =
  case r.peek
  of "'", "`", "~", "@", "~@", "^": r.read_transforms
  of "(":                           r.read_list
  of "[":                           r.read_vector
  of "{":                           r.read_hashmap
  else:                             r.read_atom

proc read_list(r: Reader): MalType = mal_list r.read_seq(")")
proc read_vector(r: Reader): MalType = mal_vec r.read_seq("]")
proc read_hashmap(r: Reader): MalType = mal_hash r.read_seq("}")

proc read_seq(r: Reader, end_token: string): seq[MalType] =
  var list: seq[MalType] = @[]

  discard r.next
  var token = r.peek

  while token != end_token:
    if token == nil:
      echo "unbalanced"
      return @[]

    list.add r.read_from
    token = r.peek
  discard r.next
  return list

proc read_atom(r: Reader): MalType =
  let token = r.next

  if token.startsWith('"'):
    if not token.endsWith('"'):
      echo "unbalanced"
      return mal_nil()
    else:
      return mal_str token[1 .. ^2].multiReplace(("\\\\", "\\"), ("\\\"", "\""), ("\\n", "\n"))
  elif token.startsWith(':'): return mal_key token[1 .. ^1]
  elif token == "nil":        return mal_nil()
  elif token == "true":       return mal_true()
  elif token == "false":      return mal_false()
  else:
    if isDigit(token[0]) or token.startsWith('-'):
      try:
        return mal_int parseInt(token)
      except ValueError:
        return mal_sym token
    else:
      return mal_sym token

proc read_transforms(r: Reader): MalType =
  # Reader macros that transform tokens directly
  let token = r.next
  case token
  of "'":  mal_list @[mal_sym "quote", r.read_from]
  of "`":  mal_list @[mal_sym "quasiquote", r.read_from]
  of "~":  mal_list @[mal_sym "unquote", r.read_from]
  of "~@": mal_list @[mal_sym "splice-unquote", r.read_from]
  of "@":  mal_list @[mal_sym "deref", r.read_from]
  of "^": # TODO understand the purpose of this one
    let arg2 = r.read_from
    let arg1 = r.read_from
    mal_list @[mal_sym "with-meta", arg1, arg2]
  else:
    raise newException(ValueError, "Unknown reader transform")

proc read_str*(input: string, print_tokens = false): MalType =
  # Create new reader and parse
  let reader: Reader = Reader(tokens: tokenize(input), pos: 0)

  if print_tokens: echo reader.tokens # useful to see tokens for debugging

  reader.read_from
