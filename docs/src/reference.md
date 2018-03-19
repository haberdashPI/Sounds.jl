# Sound Construction

```@docs
Sound
tone
noise
silence
harmonic_complex
irn
inHz
inframes
inseconds
```

# Interface

```@docs
samplerate
set_default_samplerate!
nchannels(::Sounds.Sound)
nframes(::Sounds.Sound)
duration
left
right
ismono
isstereo
asmono
asstereo
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
normpower
mix
envelope
dc_offset
leftright
DSP.Filters.resample(::Sounds.Sound,::Quantity)
```

