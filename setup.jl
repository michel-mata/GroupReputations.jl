begin
    "setting directory..." |> print
    (@__DIR__) == pwd() || cd(@__DIR__)
    any(LOAD_PATH .== pwd()) || push!(LOAD_PATH, pwd())
    "done, set in \n\t'$(pwd())'!" |> println
    ""|>print

    using Pkg
    Pkg.activate(".")
    Pkg.instantiate()

    "loading workers..." |> print
    using Distributed
    num_workers = @isdefined(num_workers) ? num_workers : 0
    nworkers()-1 < num_workers && addprocs( num_workers+1 - nworkers() , exeflags="--project=$(Base.active_project())" )
    "done, $(nprocs()) workers loaded!" |> println
end

begin
    "loading modules..." |> print
    @everywhere using GroupReputations
    "done!" |> println
end
