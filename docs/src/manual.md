Sounds is a package that aims to provide a clean interface for generating and manipulating sounds.

# Sound generation

There are four ways to create sounds: loading a file, using sound primitives,
passing a function to [`Sound`](@ref) and converting an aribtrary
`AbstractArray` into a sound.

## Loading a file

Using [`LibSndFile`](https://github.com/JuliaAudio/LibSndFile.jl) you can create
sounds from files, like so:

```julia
using LibSndFile
x = Sound("mysound_file.wav")
```

## Sound Primitives

There are several primitives you can use to generate simple
sounds. They are [`tone`](@ref) (to create a sinusoidal tone), [`noise`](@ref) (to generate
white noise), [`silence`](@ref) (for a silent period) and
[`harmonic_complex`](@ref) (to create multiple pure tones with integer frequency
ratios).

## Using `Sound`

You can pass a function and a duration to [`Sound`](@ref) to define an aribtrary
sound. The function will recieve a `Range` of `Float64` values representing the time in
seconds. 

For example, you can create a sawtooth wave like so:

```julia
x = Sound(t -> 1000t .% 1,2s)
```

All of the sound primitives are defined by passing a function to `Sound`.

## Using Arrays

Any aribtrary `AbstractArray` can be turned into a sound. You just need to
specify the sampling rate the sound is represented at, like so:

```julia
# creates a 1 second noise
x = rand(44100)
Sound(x,rate=44.1kHz)
```

# Sound manipulation

Once you have created some sounds they can be combined and manipulated to
generate more interesting sounds. You can filter sounds ([`bandpass`](@ref),
[`bandstop`](@ref), [`lowpass`](@ref), [`highpass`](@ref) and
[`lowpass`](@ref)), mix them together ([`mix`](@ref)) and set an appropriate
decibel level ([`normpower`](@ref) and [`amplify`](@ref)). You can also
manipulate the envelope of the sound ([`ramp`](@ref), [`rampon`](@ref),
[`rampoff`](@ref), [`fadeto`](@ref), [`dc_offset`](@ref) and [`envelope`](@ref)).

Where appropriate, these manipulation functions employ
[currying](https://en.wikipedia.org/wiki/Currying).

As an example of this currying, the folloiwng code creates a 1 kHz tone for 1
second inside of a noise. The noise has notch from 0.5 to 1.5 kHz. The SNR of
tone to the noise is 5 dB.

```julia
SNR = 5dB
mytone = tone(1kHz,1s) |> ramp |> normpower |> amplify(-20dB + SNR)
mynoise = noise(1s) |> bandstop(0.5kHz,1.5kHz) |> normpower |>
  amplify(-20dB)
scene = mix(mytone,mynoise)
```

Equivalently, if you do not want to take advantage of function currying, you could write this without using julia's `|>` operator, as follows:

```julia
SNR = 5dB
mysound = tone(1kHz,1s)
mysound = ramp(mysound)
mysound = normpower(mysound)
mysound = amplify(mysound,-20dB + SNR)

mynoise = noise(1s)
mynoise = bandstop(mynoise,0.5kHz,1.5kHz)
mynoise = normpower(mysound)
mynoise = amplify(mynoise,-20dB)

scene = mix(mysound,mynoise)
```

### Explicit Filter Design
If you want to have more control over the kind of filters you apply to
sounds, you can using the [DSP](https://juliadsp.github.io/DSP.jl/latest/contents.html)
package. Both `filt` and `filtfilt` have been defined over sounds.

```julia
using DSP
x = noise(1s)
responsetype = Bandpass(10, 40; fs=ustrip(samplerate(x)))
designmethod = Butterworth(4)
filtered_x = filt(digitalfilter(responsetype, designmethod), x)
```

The resulting value, `filtered_x`, will be a sound (not a plain array). Note
that we must use the unitful method `ustrip` because `fs` must be a `Float64`
not a `Quantity{Float64}` (for more information on unitful quantities, see
[Unitful.jl](https://github.com/ajkeller34/Unitful.jl).

## Sounds are arrays

Because sounds are just an `AbstractArray` of real numbers they can be
manipulated much like any array can. The amplitudes of a sound are represented
as real numbers between -1 and 1 in sequence at a sampling rate specific to the
sound's type. Furthermore, sounds use similar semantics to
[`AxisArrays`](https://github.com/JuliaArrays/AxisArrays.jl), and so they have
some additional support for indexing with time units and `:left` and
`:right` channels. For instance, to get the first 5 seconds of a sound you can
do the following.

```julia
mytone = tone(1kHz,10s)
mytone[0s .. 5s]
```

To represent the end of a sound using this special unitful indexing, you can use
`ends`. For instance, to get the last 3 seconds of `mysound` you can do the
following.

```julia
mytone[7s .. ends]
```

We can concatenate multiple sounds, to play them in sequence. The
following creates two tones in sequence, with a 100 ms gap between them.

```julia
interval = [tone(400Hz,50ms); silence(100ms); tone(400Hz * 2^(5/12),50ms)]
```

### Sounds as normal arrays

To represent a sound as a standard array (without copying any data), you may call its `Array` constructor.

```julia
a = Array(mysound)
```

## Stereo Sounds

You can create stereo sounds with [`leftright`](@ref), and reference the left and right channel using `:left` or `:right`, like so.

```julia
stereo_sound = leftright(tone(1kHz,2s),tone(2kHz,2s))
left_channel = stereo_sound[:left]
right_channel = stereo_sound[:right]
```

This can be combined with the time indices to a get a part of a channel.

```julia
stereo_sound = leftright(tone(1kHz,2s),tone(2kHz,2s))
x = stereo_sound[0.5s .. 1s,:left]
```

Stereo sounds can be safely referenced without the second index:

```julia
stereo_sound[0.5s .. 1s]
```

## Sound manipulation is forgiving

You can concatenate stereo and monaural sounds, and you can mix sounds of
different lengths, and the "right thing" will happen.

```julia
# the two sounds are mixed over one another
# resutling in a single 2s sound
x = mix(tone(1kHz,1s),tone(2kHz,2s)) 

# the two sounds are played one after another, in stereo.
y = [leftright(tone(1kHz,1s),tone(2kHz,1s)); tone(3kHz,1s)]
```

This also works for sounds of different sampling or bit rates: the sounds will
first be promoted to the highest fidelity representation (highest sampling rate
and highest bit rate).

```julia
julia> x = noise(1s,rate=22.05kHz)
1.0 s 64 bit floating-point mono sound
Sampled at 22050 Hz
▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆

julia> y = noise(1s,rate=44.1kHz)
1.0 s 64 bit floating-point mono sound
Sampled at 44100 Hz
▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆

julia> [x; y]
2.0 s 64 bit floating-point mono sound
Sampled at 44100 Hz
▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆

```

# Using Sounds

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

The function `play` is defined in `Sounds` and automatically initializes and
closes a `PortAudioStream` object for you. You could equivalently call the
following code.

```julia
playback = PortAudioStream()
write(playback,sound1)

# do some other stuff....

# ...before you close your julia session:
close(playback)
```
