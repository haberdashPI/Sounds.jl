# Sound Construction

```@docs
Sound
tone
noise
silence
harmonic_complex
irn
audible
```

# Interface

```@docs
samplerate
nchannels(::TimedSound.Sound)
nsamples(::TimedSound.Sound)
duration
left
right
```

# Sound Manipulation

```@docs
highpass
lowpass
bandpass
bandstop
ramp
rampon
rampoff
fadeto
amplify
normalize
mix
mult
envelope
leftright
DSP.Filters.resample(::TimedSound.Sound,::Any)
```

