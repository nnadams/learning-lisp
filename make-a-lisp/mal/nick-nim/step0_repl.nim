proc READ(param: string): string = param

proc EVAL(param: string): string = param

proc PRINT(param: string): string = param

proc rep(param: string): string = PRINT(EVAL(READ(param)))

var input: string
while true:
  try:
    write(stdout, "user> ")
    input = readLine(stdin)
    echo rep(input), "\n"
  except EOFError:
    break
