using LBblocks
using Test

@testset "LBblocks.jl" begin
    # Write your own tests here.

	d      = 1.2
	anon1  = ()->rand()
	decl() = rand()

	const c     = 1
	const anon2 = ()->rand()

	w,z = @lblock let a=1, b=3, d, anon1
	    y = a+b+c+d+anon1()+anon2()+decl()
	    return sin(y), y
	end

	#= this should error
	w,z = @sblock let a=1, b=3, d, anon1
	    y = a+b+c+d+anon1()+anon2()+decl()
	    return sin(y), y
	end
	=#

	w,z = @sblock let a=1, b=3, d, anon1, c, anon2
	    y = a+b+c+d+anon1()+anon2()+decl()
	    return sin(y), y
	end



end
