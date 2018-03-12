# Sounds

[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](http://www.repostatus.org/badges/latest/wip.svg)](http://www.repostatus.org/#wip) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://haberdashPI.github.io/Sounds.jl/latest)
<!-- [![Build status](https://ci.appveyor.com/api/projects/status/uvxq5mqlq0p2ap02/branch/master?svg=true)](https://ci.appveyor.com/project/haberdashPI/weber-jl/branch/master) -->
<!-- [![TravisCI Status](https://travis-ci.org/haberdashPI/Weber.jl.svg?branch=master)](https://travis-ci.org/haberdashPI/Weber.jl) -->
<!-- [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://haberdashPI.github.io/Weber.jl/stable) -->

Sounds is a package that aims to provide a clean interface for generating and manipulating sounds.

```julia
using Sounds

# create a pure tone 20 dB below a power 1 signal
sound1 = tone(1kHz,5s) |> normpower |> amplify(-20dB)

# load a sound from a file
sound2 = Sound("mysound.wav")

# create a sawtooth wave 
sound3 = Sound(t -> 1000t .% 1,2s) |> normpower |> amplify(-20dB)

# create a 5Hz amplitude modulated noise
sound4 = noise(2s) |> envelope(tone(5Hz,2s)) |> normpower |> amplify(-20dB)
```

Sounds work much like arrays, and in addition to the normal ways of indexing an
array, you can also access parts of a sound using
[Untiful.jl](https://github.com/ajkeller34/Unitful.jl) values and
[IntervalSets.jl](https://github.com/JuliaMath/IntervalSets.jl). For example:

```julia
sound1[1s .. 2s,:left]
sound1[3s .. ends,:right]
sound1[200ms .. 500ms]
sound1[:right]
leftright(sound1[0s .. 1s,:left],sound2[1s .. 2s,:right])
```

When working with multiple sounds, methods in this package "just work". If the
sounds have a different number of channels, a different sampling rate or different bit
rate, the sounds are first promoted to the highest fidelity representation, and then
the given method is applied over the promoted representation.

See the [documentation](https://haberdashPI.github.io/Sounds.jl/latest) for a complete
description of available methods.

Once you've created a sound you can use [PortAudio.jl](https://github.com/JuliaAudio/PortAudio.jl) or **TODO_CHANGE**[TimedPortAudio.jl](https://github.com/haberdashPI/TimedPortAudio.jl) to play the sounds, or you can just save the sound.

```julia
sound1 = tone(1kHz,5s) |> normpower |> amplify(-20dB)

using FileIO
save("puretone.wav",sound1)

# **EITHER***
using PortAudio
play(sound1)

## **OR**
using TimedSound
play(sound1)

```

# Alternative Solutions

There are two other ways you might represent sounds in Julia,
[AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) and
[SampledSignals.jl](https://github.com/JuliaAudio/SampledSignals.jl). A `Sound`
differs from these solutions in a number of ways.

1. As of the last update to `Sounds`, the `SampledSignals` package uses some out
   of date packages and aims to support some older versions of Julia. It also
   has a more ambitious scope, and seeks to represent many kinds of signals, not
   just sounds. `SampledSignals` does not include the various sound manipulation
   routines available in `Sounds`.

2. Once you create an `AxisArray`, the interface is very similar to a `Sound`
   but, as a more generic interface, it requires you to explicitly specify the
   axes you want to use when constructing a sound. There is no automatic
   promotion of the sample rate or channel when using `AxisArray`'s.

If you want to use either of these other packages with `Sounds`, many of the
sound manipulation routines provided are written generically enough to handle any type
(though some routines will convert to the result to a `Sound`). If you construct
a sound using this package you can easily convert it to one of these other
types, or vice versa, by calling an appropriate constructor.
(e.g. `SampleBuf(tone(1kHz,1s))` or `Sound(myaxis_array)`). Bear in mind that
`SampledSignals` may export some symbols that conflict with `Sounds` (e.g. last
time I checked it uses an older approach for representing units).
