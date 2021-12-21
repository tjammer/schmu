# schmu
A WIP functional programming language focused on a simple and practical core, compiled to native code through LLVM.

Here's what it looks like:

Fibonacci example
``` lua
-- No print function yet, so we use a C stub to print integers
external printi : int -> unit

-- Variable binding
number = 35

-- Calculate fibonacci number
function fib(n)
    -- The function simply returns the expression, no 'return' statement
    if n < 2 then n
    else
        fib(n - 1) + fib(n - 2)

-- and print it
printi(fib(number))
```

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
<!-- printi(apply(function(age) { years = age.years, -->
<!--                              months = age.months, -->
<!--                              days = age.days + b }, -->
<!--              start_age).days) -- prints 19 -->
<!-- ``` -->

More examples can be found in the `test` directory.

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
The goal is to strike a balance between keeping the user focused on writing clean abstractions without getting bogged down in type level trickery, while at the same time providing an expressive type system that doesn't feel like it's holding them back from being productive.


+ **Practical**
schmu aims to be a practical language.
It allows impure functions and the use of immutable data types such as arrays (and vectors, their growable cousins) for their simplicity and performance.
Data types are unboxed (as long as they are non-recursive, anyway) to make interop with C code straightforward. 
It doesn't try to compete with the fastest languages out there, but should be reasonably fast thanks to LLVM.
The memory management story is not fully fleshed out yet, but will most likely use automatic reference counting.

## Roadmap
+ [x] Higher order functions and (downward) closures
+ [x] Polymorphic functions
+ [x] Type-parametrized records
+ [ ] Algebraic data types and pattern matching
+ [ ] Automatic reference counting
+ [ ] Recursive data types
+ [ ] C ABI compatibilty
