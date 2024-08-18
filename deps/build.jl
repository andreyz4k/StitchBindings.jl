
using StitchBindings
using Scratch
build_folder = get_scratch!(StitchBindings, "build")
cmd = Cmd(`cargo build -r --target-dir=$build_folder`, dir="../stitch_bindings")
run(cmd)
bin_folder = get_scratch!(StitchBindings, "bin")
cp(joinpath(build_folder, "release/libstitch_core.dylib"), joinpath(bin_folder, "libstitch_core.dylib"); force=true)
