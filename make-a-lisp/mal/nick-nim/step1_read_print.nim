import os
import types, reader, printer

proc READ(param: string): MalType = read_str(param, false)

proc EVAL(param: MalType): MalType = param

proc PRINT(param: MalType): string = pr_str(param)

proc rep(param: string): string = PRINT(EVAL(READ(param)))

var input: string
while true:
  try:
    write(stdout, "user> ")
    input = readLine(stdin)
    echo rep(input), "\n"
  except EOFError:
    break
