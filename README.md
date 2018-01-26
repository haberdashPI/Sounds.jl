# Sounds

[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](http://www.repostatus.org/badges/latest/wip.svg)](http://www.repostatus.org/#wip) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://haberdashPI.github.io/Sounds.jl/latest)
<!-- [![Build status](https://ci.appveyor.com/api/projects/status/uvxq5mqlq0p2ap02/branch/master?svg=true)](https://ci.appveyor.com/project/haberdashPI/weber-jl/branch/master) -->
<!-- [![TravisCI Status](https://travis-ci.org/haberdashPI/Weber.jl.svg?branch=master)](https://travis-ci.org/haberdashPI/Weber.jl) -->
<!-- [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://haberdashPI.github.io/Weber.jl/stable) -->

Sounds provides a simple interface to create and manipulate sounds. 

```julia
using Sounds

sound1 = @> tone(1kHz,5s) normalize amplify(-20)
sound2 = @> Sound("mysound.wav") normalize amplify(-10)
sound3 = @> audible(t -> 1000t .% 1,2s)
```

Sounds work much like arrays, and you can access parts of them using [Untiful.jl](https://github.com/ajkeller34/Unitful.jl) values and [IntervalSets.jl](https://github.com/JuliaMath/IntervalSets.jl). For example:

```julia
sound1[1s .. 2s,:left]
sound1[3s .. ends,:right]
leftright(sound1[0s .. 1s,:left],sound2[0s .. 1s,:right])
```

See the [documentation](https://haberdashPI.github.io/Sounds.jl/latest) for more
information.

# Alternative solutions

There are two other ways you might represent sounds in Julia,
[AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) and
[SampledSignals.jl](https://github.com/JuliaAudio/SampledSignals.jl). Rather
than use these existing types to generate sounds, I chose to create a new
type. The `Sound` type provided here differs from those types in a few small
ways that make it a little more convienient to work with (IMHO).

1. `SampledSignals` uses some out of date pacakges, and aims to support some older versions of julia, and has been a little slow to update recently. This can make it a little tricky for interoperability with newer packages. `Sound` uses the more modern [Unitful.jl](https://github.com/ajkeller34/Unitful.jl) package to handle units, and the [IntervalSets.jl](https://github.com/scheinerman/IntervalSets.jl) package to handle intervals of time. I wanted to make use of Unitful.jl in this package but
having two exported versions of `s` from Unitful and SIUnits (which SampledSignals uses) just doesn't work that well. (If/when SampledSignals is updated I may switch to it.)

2. Unlike `AxisArray`, for a `Sound` when indexing in time or channel you don't need to explicitly specify the axis name.

However, if you want to use either of these other types, the code here is
written generically enough that it should work relatively seamlessly with these other types. If you construct a sound using this package you can easily
convert it to one of these other types by calling an appropriate constructor.
(e.g. `SampleBuf(tone(1kHz,1s))` or `Sound(myaxis_array)`). However, bear in mind that SampledSignals exports symbols 
