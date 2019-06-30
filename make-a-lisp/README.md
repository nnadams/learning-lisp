# Make a Lisp
[Make a Lisp (MAL)](https://github.com/kanaka/mal/) is series of detailed steps to guide you through creating a full featured Lisp implementation of the author's own Mal Lisp (based on Clojure). Two birds one stone style, I did my MAL in [Nim](https://nim-lang.org/), a language I hadn't gotten around to learning. This is the first Nim or Lisp code I've written so don't look too closely.

The MAL repo is included here as a subtree. There is an existing Mal Nim implementation, so mine is called "nick-nim" to avoid overlap. 

The MAL process comes with tests to run after each step. There are steps 0 through 9 and A. You can pass in `REGRESS=1` to rerun all the tests on a specific step. Enter the mal directory, and the following will run every test on the final step's code:

```bash
make REGRESS=1 "test^nick-nim^stepA"
```

There are also a few performance tests. My results were perf1=1ms, perf2=1ms, perf3=17497. This is on my laptop and using Nim version 0.20.99. The final implementation is around 700 lines of Nim code.

```bash
make MAL_IMPL=nick-nim "perf^nick-nim"
```

The final test is self-hosting. The following command will run every test again through a Mal implementation written in Mal, running on your Mal implementation:

```bash
make MAL_IMPL=nick-nim "test^mal"
```

