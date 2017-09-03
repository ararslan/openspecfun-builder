# openspecfun-builder

This is a small wrapper over the [OpenSpecFun](https://github.com/JuliaLang/openspecfun)
library meant to utilize continuous integration infrastructure to compile OpenSpecFun as
a shared library and store the resulting binaries in releases.
These binaries are intended to be used by
[SpecialFunctions.jl](https://github.com/JuliaMath/SpecialFunctions.jl) and are thus
built in a Julia-specific manner.

**NOTE**: If you're reading this, any releases in this repository should NOT be considered
production-ready.
Generally speaking, they should not be used.
