module LBblocks

import MacroTools
export @bblock, @lblock

macro bblock(ex)
    @assert ex.head == :block
    :((() -> $(esc(ex)))())
end

lhs(ex::Symbol) = ex
lhs(ex::Expr)   = MacroTools.isexpr(ex, :(=)) ? ex.args[1] : nothing

rhs(ex::Symbol) = ex
rhs(ex::Expr)   = MacroTools.isexpr(ex, :(=)) ? ex.args[end] : nothing

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

    # args from first line of let and global args
    lhs_args = map(lhs, vlines)
    rhs_args = map(rhs, vlines)
    globals  = Any[s for s in names(__module__) if !isconst(__module__,s) && !(s in lhs_args) && !(s == :ans)]
    
    # @show lhs_args
    # @show rhs_args
    # @show globals

    # prepend the let body with :(local globals_not_in_arglist...)
    new_body = length(globals) == 0 ? 
        Expr(:block, map(esc,body)...) :
        Expr(:block, esc(:(local $(globals...))) , map(esc,body)...)

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
    return quote
        $fnm_ex
        $fnm($(map(esc,rhs_args)...))
    end

end

end # module
