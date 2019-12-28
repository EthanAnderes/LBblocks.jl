# LBblocks

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://EthanAnderes.github.io/LBblocks.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://EthanAnderes.github.io/LBblocks.jl/dev)
[![Build Status](https://travis-ci.com/EthanAnderes/LBblocks.jl.svg?branch=master)](https://travis-ci.com/EthanAnderes/LBblocks.jl)


This is an experimental package for better management of script code blocks which are evaluate in global scope. This is done by two macros `@lblock` or `@bblock` that transform a `let` or `begin` block into a function which is subsequently evaluated. In the `let` block case non-constant globals are declared to be local, resulting in an error if the code references non-constant globals which do not appear  in the `let` argument list.


## `@bblock` overview

`@bblock` works by wrapping a `begin ... end` block of code into an anonymous function which is subsequently evaluated. 

The advantages I'm hoping for with the use of `@bblock` is as follows:
1. one can utilize speed advantages offered by anonymous functions
2. keywords such as `return` in code blocks
3. avoid the scoping issues having to do with globals variables in the REPL
4. make sequences of code blocks easier to read by clearly specifying which variables are temporary for a particular code block vrs which variables are used for subsequent code blocks. 

Here is an example of the use of `@bblocks`. 
```julia
a = true
b = 1.0
c, d = @bblock begin
    if a
        return 1,2
    else
        return b*(c+b)
    end
end
```
Which gets expanded to something like
```julia
anon_function = function ()
    if a
        return 1,2
    else
        return b*(c+b)
    end
end
c, d = anon_function()
```


## `@lblock` overview

`@lblock` works by wrapping a `let` block of code into a generic function, which is subsequently evaluated on the variable list specified by the `let` block. In addition `@lblock` has more strict rules for referencing global variables within code code blocks, only allowing global variables declared as `const` to be used in the code block (which are not in the `let` argument list).

The advantages, beyond those for `@bblock`, I'm hoping for with the use of `@lblock` is as follows:
1. type inference and jit compilation so heavy one-off calculations are fast.
2. nudge the programmer (i.e. me or my students) to keep the global namespace clean not littered with temporary variables. 
3. smooth the transition from prototyping code in the REPL to functions in a Module. 

Here are a couple example of the use of `@lblock`. Note: the first use of `@lblock` in the example below is intentionally supposed to give an error to the user.
```julia
julia> using LBblocks

julia> const c = 1
1

julia> d = 1.2
1.2

julia> w,z = @lblock let a=1, b=3
           y = a+b+c+d
           return sin(y), y
       end
ERROR: UndefVarError: d not defined

julia> w,z = @lblock let a=1, b=3, d
           y = a+b+c+d
           return sin(y), y
       end
(-0.0830894028174964, 6.2)

julia> w,z = @lblock let d=d, c=10, b=w, a=1
           y = a+b+c+d
           return sin(y), y
       end
(0.024679550416085317, 3.1169105971825033)

```

To illustrate the code transformation taking place one can now use `MacroTools.@expand`

```julia
julia> using MacroTools

julia> @expand @lblock let a=a,b=3,d
           y = a+b+c+d
           return sin(y), y
       end
quote
    function manatee(a, b, d; )
        local w, z
        y = a + b + c + d
        return (sin(y), y)
    end
    manatee(a, 3, d)
end
```


