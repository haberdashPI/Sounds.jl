# TimedSound

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

Sounds work much like arrays, and you can access parts of them using [Untiful.jl](https://github.com/ajkeller34/Unitful.jl) values. For example:

```julia
sound1[1s .. 2s,:left]
sound1[3s .. ends,:right]
leftright(sound1[0s .. 1s,:left],sound2[0s .. 1s,:right])
```

# Alternative solutions

There are two other ways you might represent sounds in Julia,
[AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) and
[SampledSignals.jl](https://github.com/JuliaAudio/SampledSignals.jl). Rather
than use these existing types to define these sound manipulation functions, I
chose to create a new type. The `Sound` type provided here differs from those in a
few small ways that make it a little more convienient to work with (IMHO).

1. Unlike a `SampledBuf` a `Sound` uses the more modern [Unitful.jl](https://github.com/ajkeller34/Unitful.jl) package to handle units.

2. Unlike a `SampledBuf` or `AxisArray`, a `Sound` is more forgiving. You can
mix two sounds or contactenate them, and even if they have a different number of
channels, or are different lengths, the "right thing" will happen.

3. Unlike `AxisArray`, for a `Sound` when indexing in time or channel you do not need to explicitly specify the axis name.

Some of these features depend on the fact that what you are manipulating really is a sound. Both these other packages are trying to represent more than just sounds, hence the differences.

However, if you want to use either of these other types, all of the sound
primitives provided here should work seamlessly with those types as well. If you
construct a sound you can easily convert it to one of these other types by
calling an appropriate constructor.  (e.g. `AxisArray(tone(1kHz,1s))`). Just
make sure to call `using SoundAxisArray` or `using SoundSampledSignals` if you
plan to make use one of these other types.  (Note: once Julia has the feature to
have glue modules that load automatically this step will no longer be
necessary.)

See the [documentation](https://haberdashPI.github.io/Sounds.jl/latest) for more
documentation.

# Plans

- Seperate out SampledSignals and AxisArrays so we dont depend on them.
- Use another name for samplerate to avoid conflicts with SampledSignals
