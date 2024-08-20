module StitchBindings

using Scratch
using JSON

function get_stitch_lib()
    bin_folder = @get_scratch!("bin")
    if Sys.isapple()
        path = joinpath(bin_folder, "libstitch_core.dylib")
    elseif Sys.islinux()
        path = joinpath(bin_folder, "libstitch_core.so")
    else
        error("Unsupported platform")
    end
    if !isfile(path)
        error("Stitch library not found at $path")
    end
    return path
end

function build_arg(name::String, val::Bool)::String
    if val
        return "--" * replace(name, "_" => "-")
    else
        return ""
    end
end
function build_arg(name::String, val::Union{Int,String})::String
    return "--$(replace(name, "_" => "-"))=$val"
end

function dreamcoder_program_to_string(program, name_mapping)
    for (name, p) in reverse(name_mapping)
        program = replace(program, p => name)
    end
    if occursin("#", program)
        error("Rewritten program $program contains #")
    end
    program = replace(program, "(lambda " => "(lam ")
    return program
end

function compress_backend(
    programs::Vector{String},
    tasks::Vector{String},
    existing_inventions::Vector{String},
    iterations::Int,
    max_arity::Int = 2,
    threads::Int = 1,
    silent::Bool = true,
    panic_loud::Bool = false,
    rewritten_dreamcoder::Bool = false,
    ;
    kwargs...,
)
    sort!(existing_inventions; by = length)
    if rewritten_dreamcoder
        name_mapping = ["dreamcoder_abstraction_$i" => name for (i, name) in enumerate(existing_inventions)]
        programs = [dreamcoder_program_to_string(program, name_mapping) for program in programs]
    else
        name_mapping = []
    end

    kws = Dict(
        "iterations" => iterations,
        "max_arity" => max_arity,
        "threads" => threads,
        "silent" => silent,
        "rewritten_dreamcoder" => rewritten_dreamcoder,
    )

    merge!(kws, Dict(string(k) => kwargs[k] for k in keys(kwargs)))

    args = join([build_arg(k, v) for (k, v) in kws], " ")

    cname_mapping = [k * "," * v for (k, v) in name_mapping]
    res = @ccall get_stitch_lib().compress_backend_c(
        programs::Ptr{Cstring},
        length(programs)::Csize_t,
        tasks::Ptr{Cstring},
        length(tasks)::Csize_t,
        cname_mapping::Ptr{Cstring},
        length(cname_mapping)::Csize_t,
        panic_loud::Bool,
        args::Cstring,
    )::Cstring
    parsed = JSON.parse(unsafe_string(res))

    @ccall get_stitch_lib().free_string(res::Cstring)::Cvoid

    if rewritten_dreamcoder
        abstractions = [Dict("name" => abs["name"], "body" => abs["dreamcoder"]) for abs in parsed["abstractions"]]
        rewritten = parsed["rewritten_dreamcoder"]
    else
        abstractions = [Dict("name" => abs["name"], "body" => abs["body"]) for abs in parsed["abstractions"]]
        rewritten = parsed["rewritten"]
    end
    return abstractions, rewritten
end

export compress_backend

end # module StitchBindings
