module LBblocks

import MacroTools
export @bblock, @lblock, @sblock


# check if m.s is a declared function (necessarily const)
function isdeclaredfunction(m::Module, s::Symbol)
  m_s = getfield(m, s)
  return isconst(m,s) && isa(m_s,Function) && nameof(m_s)==s 
end

# check if m.s is a module function (necessarily const)
function ismod(m::Module, s::Symbol)
  m_s = getfield(m, s)
  return isconst(m,s) && isa(m_s,Module)
end

# Note: we partition 
# names(m::Module) = Ω₁ ∪ Ω₂ ∪ Ω₃ where
# Ω₁ = {non const} 
# Ω₂ = {consts which are delcared functions or Modules}
# Ω₃ = {consts which are *not* delcared functions or Modules}

#  Ω₁ = {non const} 
function non_const_vals(m::Module)
    return [s for s in names(m) if !isconst(m,s)]
end

# Ω₁ᶜ
function const_vals(m::Module)
    return [s for s in names(m) if isconst(m,s)]
end

# Ω₂  = {consts which are delcared functions or Modules}
function const_delcaredfun_or_mod(m::Module)
    return [s for s in const_vals(m) if (ismod(m,s) || isdeclaredfunction(m,s))] 
end

# Ω₃ = {consts which are *not* delcared functions or Modules}
function const_other(m::Module)
    return [s for s in const_vals(m) if !(ismod(m,s) || isdeclaredfunction(m,s))] 
end


lhs(ex::Symbol) = ex
lhs(ex::Expr)   = MacroTools.isexpr(ex, :(=)) ? ex.args[1] : nothing

rhs(ex::Symbol) = ex
rhs(ex::Expr)   = MacroTools.isexpr(ex, :(=)) ? ex.args[end] : nothing


"""
```
rtn = @bblock begin
    code body
end
```
Begin block decorator which return anon eval
"""
macro bblock(ex)
    @assert ex.head == :block
    :((() -> $(esc(ex)))())
end


"""
```
rtn = @lblock let args
    code body
end
```
Let block decorator for function eval of code blocks ... need to explicitly pass
all non-const variables as let args
"""
macro lblock(ex) 
    @assert ex.head == :let
    
    # grab first line and body of let
    MacroTools.@capture(
        ex, 
        let fline_ 
            body__ 
        end
    )

    # split the first line into an array of Symbols
    MacroTools.@capture(fline, vlines__)

    # args from first line of let
    lhs_args    = map(lhs, vlines)
    rhs_args    = map(rhs, vlines)

    # declare local if in (Ω₁ - lhs_args) where Ω₁ = {non const} 
    declared_local = Any[s for s in non_const_vals(__module__) if !(s in lhs_args)]

    # @show lhs_args
    # @show rhs_args
    # @show declared_local

    # prepend the let body with :(local declared_local_not_in_arglist...)
    new_body = length(declared_local) == 0 ? 
        Expr(:block, map(esc,body)...) :
        Expr(:block, esc(:(local $(declared_local...))) , map(esc,body)...)

    # put the modified body and first line of let back together as a function
    fnm = gensym()
    fnm_ex = MacroTools.combinedef(
        Dict{Symbol,Any}(
            :name        => fnm,
            :args        => map(esc,lhs_args),
            :kwargs      => Any[],
            :body        => new_body,
            :whereparams => ()
        )
    )
    
    # the return expression defines the function and then calls it on the let args
    return MacroTools.rmlines(quote
        $fnm_ex
        $fnm($(map(esc,rhs_args)...))
    end)

end



"""
```
rtn = @sblock let args
    code body
end
```
The most strict let block decorator ... need to explicitly pass
all variables as let args with the exception of modules and explicitly declared 
(non-anon) functions
"""
macro sblock(ex) 
    @assert ex.head == :let
    
    # grab first line and body of let
    MacroTools.@capture(
        ex, 
        let fline_ 
            body__ 
        end
    )

    # split the first line into an array of Symbols
    MacroTools.@capture(fline, vlines__)

    # args from first line of let 
    lhs_args    = map(lhs, vlines)
    rhs_args    = map(rhs, vlines)

    # declare local if in (Ω₁ ∪ Ω₃ - lhs_args) where Ω₁ = {non const} 
    # and Ω₃ = {consts which are *not* delcared functions or Modules}
    declared_local1  = Any[s for s in non_const_vals(__module__) if !(s in lhs_args)]
    declared_local2  = Any[s for s in const_other(__module__) if !(s in lhs_args)]
    declared_local   = vcat(declared_local1, declared_local2)

    # @show declared_local

    # prepend the let body with :(local declared_local_not_in_arglist...)
    new_body = length(declared_local) == 0 ? 
        Expr(:block, map(esc,body)...) :
        Expr(:block, esc(:(local $(declared_local...))) , map(esc,body)...)

    # put the modified body and first line of let back together as a function
    fnm = gensym()
    fnm_ex = MacroTools.combinedef(
        Dict{Symbol,Any}(
            :name        => fnm,
            :args        => map(esc,lhs_args),
            :kwargs      => Any[],
            :body        => new_body,
            :whereparams => ()
        )
    )
    
    # the return expression defines the function and then calls it on the let args
    return MacroTools.rmlines(quote
        $fnm_ex
        $fnm($(map(esc,rhs_args)...))
    end)

end


end # module
