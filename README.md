# schmu
Strongly typed, compiled pet programming language.

**Disclaimer** schmu is a passion project which I develop for fun. Please don't use it for anything too serious.
Also, the name will most likely change.

schmu is the language I'd like to program in: A strongly typed, type-inferred compiled language that can be programmed in a functional way (see below).
It prefers stack- over heap allocations, and can easily interface with C code.
Think OCaml, but slightly more control over allocations and data layout.

Here's what it looks like:

Fibonacci example
``` lua
-- variable binding
let number = 35

-- calculate fibonacci number
fun rec fib(n):
  match n:
    0 | 1: n
    _: fib(n - 1) + fib(n - 2)

-- and print it
fib(number).fmt().print()
```

More examples can be found in the skeleton `std` library or the `test` directory.

## Features
+ **Functional**
schmu is a functional language based on a Hindley-Milner type system.
This means all the basic features one might expect from an ML style language are (will be) present, like
    + Parametric polymorphism
    + Higher order functions and automatic closures
    + Algebraic data types and pattern matching
    + Module system
    + Full type inference within a module, but interfaces between modules
    + Focus on recursion

+ **Mutable Value Semantics**
schmu implements [mutable value semantics](https://www.jot.fm/issues/issue_2022_02/article2.pdf) a la [hylo/val](https://www.hylo-lang.org/).
This means references are second-class citizens and cannot be stored in records or returned from functions.
To make this feasible, schmu has move semantics and a simple borrow checkers for downward borrows, such as arguments to functions.

+ **Practical**
schmu aims to be a practical language.
Data types are unboxed to make it straightforward to use C code.
It doesn't try to compete with the fastest languages out there, but should be reasonably fast thanks to LLVM.
It also doesn't try to be a system programming language.
Some low-level access necessary to interface with C code, but that's not what schmu excels at.


## Current focus
+ Escape analsyis for closures
+ Backtraces
