# schmu
A WIP small, mostly functional programming language which compiles to native code.

**Disclaimer** schmu is a passion project which I develop for fun. Please don't use it for anything too serious.

schmu is the language I'd like to program in: A strongly typed, type-inferred compiled language that can be programmed in a functional way (see below). It prefers stack- over heap allocations, and can easily interface with C code.

Here's what it looks like:

Fibonacci example
``` haskell
-- Variable binding
(val number 35)

-- Calculate fibonacci number
(fun fib [n]
  (match n
    ((or 0 1) n)
    (_ (+ (fib (- n 1)) (fib (- n 2))))))

-- and print it
(print (fmt-str (fib number)))
```

A note on syntax:
For ease of development, schmu currently uses an s-expression based syntax.
The plan is to switch back to a more traditional syntax once the semantics are closer to being finalized.

<!-- ``` lua -->
<!-- external printi : int -> unit -->

<!-- -- Define a record type -->
<!-- type age = { years : int, months :int, days : int } -->

<!-- -- Through type inference, the generic type ('a -> 'b, 'a) -> 'b is inferred -->
<!-- function apply(f, x) -->
<!--   f(x) -->

<!-- -- We bind the variable a -->
<!-- a = 2 -->
<!-- -- and add a to some int -->
<!-- function add_a(x) -->
<!--   -- We capture a and return the sum -->
<!--   x + a -->

<!-- b = apply(add_a, 15) -- b is 17 -->

<!-- -- Create age record -->
<!-- start_age = { years = 0, months = 1, days = 2 } -->

<!-- -- Use an anonymous closure to add b to the passed age's days -->
<!-- -- and print the days -->
<!-- printi(apply(fn(age) { years = age.years, -->
<!--                              months = age.months, -->
<!--                              days = age.days + b }, -->
<!--              start_age).days) -- prints 19 -->
<!-- ``` -->

More examples can be found in the `test` directory. It is still WIP, see the roadmap below.

## Features
+ **Functional**
schmu is a functional language based on a Hindley-Milner type system.
This means all the basic features one might expect from a functional language are (will be) present, like 
    + Higher order functions and automatic closures
    + Sum types and pattern matching
    + Recursive data types

+ **Simple**
schmu is a small and simple language.
Apart from parametric polymorphism (and hopefully a robust module system in the future), there are no advanced features like GADTs or type classes, not even operator overloading.
The goal is to strike a balance between keeping the user focused on writing clean abstractions without overwhelming them with many competing options, while at the same time providing an expressive type system that doesn't feel like it's holding them back from being productive.


+ **Practical**
schmu aims to be a practical language.
It allows impure functions and the use of immutable data types such as arrays (and vectors, their growable cousins) for their simplicity and performance.
Data types are unboxed (as long as they are non-recursive, anyway) to make interop with C code straightforward. 
It doesn't try to compete with the fastest languages out there, but should be reasonably fast thanks to LLVM.
The memory management story is not fully fleshed out yet, right now there is a builtin malloc which gets freed at the end of scope automatically, RAII style, but that's all.

## Roadmap
+ [x] Higher order functions and (downward) closures
+ [x] Polymorphic functions and monomorphization
+ [x] Type-parametrized records
+ [x] Algebraic data types and pattern matching
+ [ ] Module system
+ [ ] Recursive data types
+ [ ] C ABI compatibilty. WIP, the machinery is in place and it's mostly done for x86_64-linux-gnu. Other targets will be added in the future.
