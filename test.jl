using Base.Test

if get(ENV, "CI", "") == "true"
    builddir = get(ENV, "TRAVIS", "")   == "true" ? ENV["TRAVIS_BUILD_DIR"]         :
               get(ENV, "CIRCLECI", "") == "true" ? ENV["CIRCLE_WORKING_DIRECTORY"] :
               get(ENV, "APPVEYOR", "") == "True" ? ENV["APPVEYOR_BUILD_FOLDER"]    :
               error("unrecognized CI environment")
    builddir = abspath(expanduser(builddir))
else
    builddir = pwd()
end

const libdir = joinpath(builddir, "usr", "lib")
const osf = joinpath(libdir, "libopenspecfun." * Libdl.dlext)

@test isdir(libdir)
@test isfile(osf)
@test Libdl.dlopen_e(osf) != C_NULL

z = ccall((:Faddeeva_erf, osf), Complex{Float64}, (Complex{Float64}, Float64), 1.0+0.0im, 0.0)
@test isreal(z)
@test 0 < real(z) < 1
