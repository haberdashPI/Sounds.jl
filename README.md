# Sounds

[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://haberdashPI.github.io/Sounds.jl/stable)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://haberdashPI.github.io/Sounds.jl/latest)
<!-- [![Build status](https://ci.appveyor.com/api/projects/status/uvxq5mqlq0p2ap02/branch/master?svg=true)](https://ci.appveyor.com/project/haberdashPI/weber-jl/branch/master) -->
<!-- [![TravisCI Status](https://travis-ci.org/haberdashPI/Sounds.jl.svg?branch=master)](https://travis-ci.org/haberdashPI/Sounds.jl) -->
<!-- [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://haberdashPI.github.io/Sounds.jl/stable) -->

Sounds is a package that aims to provide a clean interface for generating and manipulating sounds.

```julia
using Sounds

# create a pure tone 20 dB below a power 1 signal
sound1 = tone(1kHz,5s) |> normpower |> amplify(-20dB)

# create a sawtooth wave 
sound2 = Sound(t -> 1000t .% 1,2s) |> normpower |> amplify(-20dB)

# create a 5Hz amplitude modulated noise
sound3 = noise(2s) |> envelope(tone(5Hz,2s)) |> normpower |> amplify(-20dB)

# load a sound from a file match the power to that of sound1
using LibSndFile
sound4 = Sound("mysound.wav") |> normpower |> amplify(-20dB)
```

Sounds work much like arrays, and in addition to the normal ways of indexing an
array, you can access the channels by name (`:left` and `:right`) and you can
access time slices using [Untiful.jl](https://github.com/ajkeller34/Unitful.jl)
values and [IntervalSets.jl](https://github.com/JuliaMath/IntervalSets.jl). For
example:

```julia
sound1[1s .. 2s,:left]
sound1[3s .. ends,:right]
sound1[200ms .. 500ms]
sound1[:right]
leftright(sound1[0s .. 1s,:left],sound2[1s .. 2s,:right])
```

Because sounds have well defined promotion semantics, when working with multiple
sounds, things "just work". Specifically, if the sounds have a different number
of channels, a different sampling rate or different bit rate, the sounds are
first promoted to the highest fidelity representation, and then the given method
is applied over the promoted representation.

See the [documentation](https://haberdashPI.github.io/Sounds.jl/latest) for a complete
description of available methods.

Once you've created a sound you can use
[LibSndFile.jl](https://github.com/JuliaAudio/LibSndFile.jl) to save it, or 
[PortAudio.jl](https://github.com/JuliaAudio/PortAudio.jl) to play it.

```julia
sound1 = tone(1kHz,5s) |> normpower |> amplify(-20dB)

using LibSndFile
save("puretone.wav",sound1)

using PortAudio
play(sound1)
```

# Alternative Solutions

There are two other ways you might represent sounds in Julia,
[AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) and
[SampledSignals.jl](https://github.com/JuliaAudio/SampledSignals.jl). A lot of
the ideas for this package came from these two packages (thanks!). Here are some
of the ways that a `Sound` differs from these other solutions.

For `SapmledSignals` vs. `Sounds`:
1. `SampledSignals` does not include the various sound manipulation routines
   available in `Sounds`. This was the key motivation for the present package.
   The differences in the design of the `Sound` object were motivated by
   making these manipulation routines easy to use.
2. There are a number of automatic promotions that `Sounds` undergoe that
   objects from `SampledSignals` do not undergoe. `SampledSignals` does modify
   the format of sounds automatically in some cases, but this is handled through
   a seperate mechanism as streams are written to various sinks.
3. As of the last update to `Sounds`, `SampledSignals` package uses some out
   of date packages and has deprecation warnings for Julia v0.6. `Sounds`
   uses some a more recent package for representing units and intervals of time.
4. `SampledSignals` has a more ambitious scope, and seeks to represent many
   kinds of signals in multiple domains, not just sounds in their time/amplitude
   representation. 

For `AxisArray` vs. `Sounds`:
1. An `AxisArray` must have its dimensions explicitly specified 
   during construction. `Sounds` knows what the axes for a sound should be.
2. There is no automatic promotion of the sample rate or channel number when using
   an `AxisArray`.
3. Currently, the methods defined on an `AxisArray` are not defined for a `Sound`
   (e.g. axes, axisnames, etc...).
4. Unlike indexing into a `Sound`, there is no `ends` defined for an `AxisArray`;
   you must explicitly calculate the duration of the array when indexing by
   time.

If you want to use either of these other packages with `Sounds`, many of the
sound manipulation routines provided here are written generically enough to
handle any type (though some routines will promote the output to a `Sound`). If
you construct a sound using this package you can easily convert it to one of
these other types, or vice versa, by calling an appropriate constructor.
(e.g. `SampleBuf(tone(1kHz,1s))`, `Sound(samplebuf)`, `AxisArray(sound)`). Bear
in mind that `SampledSignals` exports some symbols that conflict with `Sounds`
(e.g. last time I checked it uses an older approach for representing units and
exports conflicting symbosl for these units), so it is probably best to `import`
Sounds or SampledSignals and call `using` on the other.
