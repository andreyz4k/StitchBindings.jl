
using StitchBindings
using Scratch
build_folder = get_scratch!(StitchBindings, "build")
cmd = Cmd(`cargo update`, dir = "../stitch_bindings")
run(cmd)
cmd = Cmd(`cargo build -r --target-dir=$build_folder`, dir = "../stitch_bindings")
run(cmd)
bin_folder = get_scratch!(StitchBindings, "bin")
if Sys.isapple()
    ext = "dylib"
elseif Sys.islinux()
    ext = "so"
else
    error("Unsupported platform")
end
cp(joinpath(build_folder, "release/libstitch_core.$ext"), joinpath(bin_folder, "libstitch_core.$ext"); force = true)
