# openspecfun-builder

This is a small wrapper over the [OpenSpecFun](https://github.com/JuliaLang/openspecfun)
library meant to utilize continuous integration infrastructure to compile OpenSpecFun as
a shared library and store the resulting binaries in releases.
These binaries are intended to be used by
[SpecialFunctions.jl](https://github.com/JuliaMath/SpecialFunctions.jl) and are thus
built in a Julia-specific manner.

| OS      | Arch         | Status    |
| :------ | :----------: | :-------: |
| Linux   | x86-64, i686 | [![CircleCI](https://circleci.com/gh/ararslan/openspecfun-builder/tree/master.svg?style=svg)](https://circleci.com/gh/ararslan/openspecfun-builder/tree/master) |
| macOS   | x86-64       | [![Travis](https://travis-ci.org/ararslan/openspecfun-builder.svg?branch=master)](https://travis-ci.org/ararslan/openspecfun-builder) |
| Windows | x86-64, i686 | [![AppVeyor](https://ci.appveyor.com/api/projects/status/as8un8ve4wkuv754/branch/master?svg=true)](https://ci.appveyor.com/project/ararslan/openspecfun-builder/branch/master) |
