# Sounds

[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](http://www.repostatus.org/badges/latest/wip.svg)](http://www.repostatus.org/#wip) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://haberdashPI.github.io/Sounds.jl/latest)
<!-- [![Build status](https://ci.appveyor.com/api/projects/status/uvxq5mqlq0p2ap02/branch/master?svg=true)](https://ci.appveyor.com/project/haberdashPI/weber-jl/branch/master) -->
<!-- [![TravisCI Status](https://travis-ci.org/haberdashPI/Weber.jl.svg?branch=master)](https://travis-ci.org/haberdashPI/Weber.jl) -->
<!-- [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://haberdashPI.github.io/Weber.jl/stable) -->

Sounds provides a simple interface to create sounds and variety of means to manipulate
those sounds.

```julia
using Sounds

# create a pure tone 20 dB below a power 1 signal
sound1 = @> tone(1kHz,5s) normalize amplify(-20)

# load a sound from a file
sound2 = Sound("mysound.wav")

# create a sawtooth wave 
sound3 = @> Sound(t -> 1000t .% 1,2s) normalize amplify(-20)
```

Sounds work much like arrays, and in addition to the normal ways of indexing an
array, you can also access parts of a sound using
[Untiful.jl](https://github.com/ajkeller34/Unitful.jl) values and
[IntervalSets.jl](https://github.com/JuliaMath/IntervalSets.jl). For example:

```julia
sound1[1s .. 2s,:left]
sound1[3s .. ends,:right]
leftright(sound1[0s .. 1s,:left],sound2[1s .. 2s,:right])
```

When working with multiple sounds, methods in this package "just work". If the
sounds have a different number of channels, a different sampling rate or different bit
rate, the sounds are first promoted to the highest fidelity representation, and then
the given method is applied to this promoted representation.

See the [documentation](https://haberdashPI.github.io/Sounds.jl/latest) for a complete
description of available methods.

Once you've created a sound you can use [PortAudio.jl](https://github.com/JuliaAudio/PortAudio.jl) or [TimedPortAudio.jl](https://github.com/haberdashPI/TimedPortAudio.jl) to play the sounds, or you can just save the sound.

```julia
sound1 = @> tone(1kHz,5s) normalize amplify(-20)

using TimedPortAudio
play(sound1)

using PortAudio
using SampledSignals
stream = PortAudioStream("Built-in Microph", "Built-in Output")
write(stream,SampleBuf(sound1))

using FileIO
save("puretone.wav",sound1)
```

# Alternative Solutions

There are two other ways you might represent sounds in Julia,
[AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) and
[SampledSignals.jl](https://github.com/JuliaAudio/SampledSignals.jl). A `Sound`
differs from these solutions in a number of ways.

1. The `SampledSignals` package uses some out of date packages and aims to
support some older versions of Julia. It also has a more ambitious scope, and
seeks to represent many kinds of signals, not just sounds. The `Sounds` package
uses the more modern [Unitful.jl](https://github.com/ajkeller34/Unitful.jl)
package to handle units, and the
[IntervalSets.jl](https://github.com/scheinerman/IntervalSets.jl) package to
handle intervals of time. `SampledSignals` does not include the various
sound manipulation routines available in `Sounds`.

2. Unlike `AxisArray`, when indexing a `Sound` by time or channel you don't need to explicitly specify the axis name. There is no automatic promotion of sample rate or channel in `AxisArray`.

If you want to use either of these other types with this package, many of the
sound manipulation routines are written generically enough to handle any type
(though some routines will convert to the result to a `Sound`). If you construct
a sound using this package you can easily convert it to one of these other
types, or vice versa, by calling an appropriate constructor.
(e.g. `SampleBuf(tone(1kHz,1s))` or `Sound(myaxis_array)`). Bear in mind that
`SampledSignals` exports some symbols that conflict with `Sounds` (e.g. it uses
an older approach for representing units).
