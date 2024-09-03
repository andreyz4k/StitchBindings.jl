# StitchBindings.jl

This repo provides Julia bindings to [stitch](https://github.com/mlb2251/stitch)

Usage example

```julia
using StitchBindings

new_abstractions, rewritten_programs = compress_backend(
    programs,                   # List of programs to compress
    tasks,                      # List of task labels for each program. Should be either empty or have the same length as programs
    existing_inventions,        # List of existing invented functions, used only in DreamCoder mode
    iterations,                 # Number of iterations to run the compression for, 0 means run until no more compression is possible
    max_arity,                  # Maximum arity of invented functions
    threads,                    # Number of threads to use
    silent,                     # Whether to print progress information
    panic_loud,                 # Whether to print panic information
    rewritten_dreamcoder,       # Whether incoming programs are in DreamCoder format and whether new programs and abstractions should be returned in DreamCoder format
    ;
    eta_long = true,            # Whether programs should be in the eta-long form
    utility_by_rewrite = true,  # Whether to compute utility by rewriting, should be true for DreamCoder mode
)

# new_abstractions is a list of dicts, each dict contains the 'name' and 'body' of the invented function
# rewritten_programs is a list of the rewritten programs
```
