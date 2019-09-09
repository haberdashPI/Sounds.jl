# Sounds

[![Project Status: Abandoned – Initial development has started, but there has not yet been a stable, usable release; the project has been abandoned and the author(s) do not intend on continuing development.](https://www.repostatus.org/badges/latest/abandoned.svg)](https://www.repostatus.org/#abandoned)
[![TravisCI Status](https://travis-ci.org/haberdashPI/Sounds.jl.svg?branch=master)](https://travis-ci.org/haberdashPI/Sounds.jl)
[![codecov](https://codecov.io/gh/haberdashPI/Sounds.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/haberdashPI/Sounds.jl)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://haberdashPI.github.io/Sounds.jl/stable)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://haberdashPI.github.io/Sounds.jl/latest)

**NOTE**: This package is being renamed and move to a new repository [SignalOperators](https://github.com/haberdashPI/SignalOperators.jl). This version of the repository is for Julia 0.6 and lower. 

Sounds is a [Julia](https://julialang.org/) package that aims to provide a clean interface for generating and manipulating sounds.

```julia
using Sounds

# create a pure tone 20 dB below a power 1 signal
sound1 = tone(1kHz,5s) |> normpower |> amplify(-20dB)

# load a sound from a file, matching the power to that of sound1
sound2 = Sound("mysound.wav") |> normpower |> amplify(-20dB)

# create a 1kHz sawtooth wave 
sound3 = Sound(t -> 1000t .% 1,2s) |> normpower

# create a 5Hz amplitude modulated noise
sound4 = noise(2s) |> envelope(tone(5Hz,2s)) |> normpower

# create 1kHz tone surrounded by a notch noise
SNR = 5dB
x = tone(1kHz,1s) |> ramp |> normpower |> amplify(-20dB + SNR)
y = noise(1s) |> bandstop(0.5kHz,2kHz) |> normpower |>
  amplify(-20dB)
scene = mix(x,y)
```

Once you've created a sound you can save it or use
[PortAudio.jl](https://github.com/JuliaAudio/PortAudio.jl) to play it.

```julia
sound1 = tone(1kHz,5s) |> normpower |> amplify(-20dB)
save("puretone.wav",sound1)

using PortAudio
play(sound1)
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

# Alternative Solutions

There are two other ways you might represent sounds in Julia,
[AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) and
[SampledSignals.jl](https://github.com/JuliaAudio/SampledSignals.jl). A lot of
the ideas for this package came from these two packages (thanks!). Here are some
of the ways that a `Sound` differs from these other solutions.

`SampledSignals` vs. `Sounds`:
1. `SampledSignals` does not include the various sound manipulation routines
   available in `Sounds`. This was the primary motivation for the present package.
   `Sound` objects were designed to make these manipulation routines easy to define.
2. In `SampledSignals` automatic conversion is handled with I/O sinks
   and sources. In `Sounds`, I use the standard type promotion mechanism.
3. `Sounds` uses more recent packages for representing units and intervals of time.
4. `SampledSignals` has a more ambitious scope, and seeks to represent many
   kinds of signals in multiple domains, not just sounds in their time-amplitude
   representation. 

`AxisArray` vs. `Sounds`:
1. An `AxisArray` must have its dimensions explicitly specified 
   during construction. `Sounds` knows what the axes for a sound should be.
2. There is no automatic promotion of the sample rate or channel number when using
   an `AxisArray`.
3. The methods defined on an `AxisArray` are not defined for a `Sound`
   (e.g. axes, axisnames, etc...).
4. Unlike indexing  into a `Sound`, there is no `ends` defined for an `AxisArray`;
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
Sounds or SampledSignals and employ `using` on the other.

# Status

I use this package all the time in other projects, so it should be pretty bug free. However, it is not yet well integrated into the rest of the ecosystem in Julia for working with audio. I'm in the process of thinking through how to do that with this [issue](https://github.com/JuliaAudio/SampledSignals.jl/issues/29).
