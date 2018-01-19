# How to create sounds

There are two primary ways to create sounds: loading a file and using sound primitives. 

## Loading a file

You can create sounds from files, like so

```julia
x = Sound("mysound_file.wav")
```

## Sound Primitives

There are several primitives you can use to generate or manipulate simple
sounds. They are [`tone`](@ref) (to create a pure), [`noise`](@ref) (to generate
white noise), [`silence`](@ref) (for a silent period) and
[`harmonic_complex`](@ref) (to create multiple pure tones with integer frequency
ratios).

These primitives can then be combined and manipulated to generate more interesting sounds. You can filter sounds ([`bandpass`](@ref), [`bandstop`](@ref), [`lowpass`](@ref), [`highpass`](@ref) and [`lowpass`](@ref)), mix them together ([`mix`](@ref)) and set an appropriate decibel level ([`amplify`](@ref)). You can also manipulate the envelope of the sound ([`ramp`](@ref), [`rampon`](@ref), [`rampoff`](@ref), [`fadeto`](@ref), [`envelope`](@ref) and [`mult`](@ref)).

For instance, to create a 1 kHz tone for 1 second inside of a noise with a notch from 0.5 to 1.5 kHz, with 5 dB SNR you could call the following.

```julia
mysound = tone(1kHz,1s)
mysound = ramp(mysound)
mysound = normalize(mysound)
mysound = amplify(mysound,-20)

mynoise = noise(1s)
mynoise = bandstop(mynoise,0.5kHz,1.5kHz)
mynoise = normalize(mysound)
mynoise = amplify(mynoise,-25)

scene = mix(mysound,mynoise)
```

TimedSound exports the macro `@>` (from [Lazy.jl](https://github.com/MikeInnes/Lazy.jl#macros)) to simplify this pattern. It is easiest to understand the macro by example: the below code yields the same result as the code above.

```juila
mytone = @> tone(1kHz,1s) ramp normalize amplify(-20)
mynoise = @> noise(1s) bandstop(0.5kHz,1.5kHz) normalize amplify(-25)
scene = mix(mytone,mynoise))
```

TimedSound also exports `@>>`, and `@_` (refer to [Lazy.jl](https://github.com/MikeInnes/Lazy.jl#macros) for details).

### Sounds are arrays

Sounds are just a specific kind of array of real numbers. The amplitudes
of a sound are represented as real numbers between -1 and 1 in sequence at a
sampling rate specific to the sound's type. They can be manipulated in the same way that any array can be manipulated in Julia, with some additional support for indexing sounds using time units. For instance, to get the first 5 seconds of a sound you can do the following.

```julia
mytone = tone(1kHz,10s)
mytone[0s .. 5s]
```

To represent the end of a sound using this special indexing, you can use `ends`. For instance, to get the last 5 seconds of `mysound` you can do the following.

```julia
mytone[5s .. ends]
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

### Stereo Sounds

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

### Sounds are forgiving

You can concatenate stereo and monaural sounds, and you can mix sounds of
different lengths, and the "right thing" will happen.

```julia
# the two sounds are mixed over one another
# resutling in a single 2s sound
x = mix(tone(1kHz,1s),tone(2kHz,2s)) 

# the two sounds are played one after another, in steroe.
y = [leftright(tone(1kHz,1s),tone(2kHz,1s)); tone(3kHz,1s)]
```

## Low-level Sound Generation

Finally, there are two more approachs to creating sounds. First, you can use the function [`audible`](@ref) to define a sound using a function `f(t)` or `f(i)` defining the amplitudes for any given time or index, respectively. Second, any aribtrary `AbstractArray` can be converted to a sound using e.g. `Sound(x,rate=44.1kHz)`.

