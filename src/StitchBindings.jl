module StitchBindings

using Scratch
using JSON

function get_stitch_lib()
    bin_folder = @get_scratch!("bin")
    path = joinpath(bin_folder, "libstitch_core.dylib")
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

function compress_backend(
    programs::Vector{String},
    iterations::Int,
    max_arity::Int = 2,
    threads::Int = 1,
    silent::Bool = true,
    ;
    kwargs...,
)
    tasks = pop!(kwargs, "tasks", [])
    weights = pop!(kwargs, "weights", [])
    name_mapping = pop!(kwargs, "name_mapping", [])
    panic_loud = pop!(kwargs, "panic_loud", false)
    merge!(kwargs, Dict("iterations" => iterations, "max_arity" => max_arity, "threads" => threads, "silent" => silent))

    args = join([build_arg(k, v) for (k, v) in kwargs], " ")

    cname_mapping = [k * "," * v for (k, v) in name_mapping]
    res = @ccall get_stitch_lib().compress_backend_c(
        programs::Ptr{Cstring},
        length(programs)::Csize_t,
        tasks::Ptr{Cstring},
        length(tasks)::Csize_t,
        weights::Ptr{Float32},
        length(weights)::Csize_t,
        cname_mapping::Ptr{Cstring},
        length(cname_mapping)::Csize_t,
        panic_loud::Bool,
        args::Cstring,
    )::Cstring
    parsed = JSON.parse(unsafe_string(res))

    abstractions =
        [Dict("body" => abs["body"], "name" => abs["name"], "arity" => abs["arity"]) for abs in parsed["abstractions"]]
    rewritten = parsed["rewritten"]
    json = parsed
    return abstractions, rewritten, json
end

export compress_backend

end # module StitchBindings
