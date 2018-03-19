Sounds is a [Julia](https://julialang.org/) package that aims to provide a clean
interface for generating and manipulating sounds.

To install it, you can run the following command in julia:

```julia
Pkg.add("https://github.com/haberdashPI/Sounds.jl")
```

Creating sounds is generally a matter of calling a sound generation function,
and then manipulating that sound with a series of `|>` pipes, like so:

```julia
using Sounds

# create a pure tone 20 dB below a power 1 signal
sound1 = tone(1kHz,5s) |> normpower |> amplify(-20dB)

# load a sound from a file, matching the power to that of sound1
sound2 = Sound("mysound.wav") |> normpower |> amplify(-20dB)

# create a 1kHz sawtooth wave 
sound3 = Sound(t -> 1000t .% 1,2s) |> normpower |> amplify(-20dB)

# create a 5Hz amplitude modulated noise
sound4 = noise(2s) |> envelope(tone(5Hz,2s)) |> normpower |> amplify(-20dB)
```

See the [manual](manual.md) for details.
