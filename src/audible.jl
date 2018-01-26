using DSP
using Unitful

export samplerate, set_default_samplerate!, audible, mix, mult, silence,
  envelope, noise, highpass, lowpass, bandpass, bandstop, tone, ramp,
  harmonic_complex, amplify, rampon, rampoff, fadeto, irn, samplerate

"""
    audible(fn,len,asseconds=true;rate=samplerate(),eltype=Float64,
            offset=0s)

Creates monaural sound where `fn(t)` returns the amplitudes for a given `Range`
of time points, with resulting values ranging between -1 and 1 as an iterable
object.

If `asseconds` is false, `fn(i)` returns the amplitudes for a given `Range` of
sample indices instead of time points.

The function `fn` should always return elements of type `eltype`.

If `offset` is specified, return the section of the sound starting
from `offset` (rather than 0 seconds).
"""
function audible(fn::Function,len=Inf,asseconds=true;
                 offset=0s,rate=samplerate(),eltype=Float64)
  rate_Hz = inHz(rate)

  n = ustrip(insamples(offset,rate_Hz))
  m = ustrip(insamples(len,rate_Hz))
  R = floor(Int,ustrip(rate_Hz))
  Sound(!asseconds ? fn(n:m) : fn(((n:m)-1)/R),rate=rate)
end

"""
    mix(x,y,...)

mix several sounds together so that they play at the same time.

Unlike normal addition, this acts as if each sound is padded with
zeros at the end so that the lengths of all sounds match.
"""
mix(xs...) = soundop(+,xs...)

"""
    mult(x,y,...)

Mutliply several sounds together. Typically used to apply an
amplitude envelope.

Unlike normal multiplication, this acts as if each sound is padded with
ones at the end so that the lengths of all sounds match.
"""
mult(xs...) = soundop(*,xs...)

function soundop(op,xs...)
  channels = maximum(nchannels.(xs))
  len = maximum(nsamples.(xs))
  rate = samplerate(xs[1])

  @assert(all(samplerate.(xs) .== rate),
          "Sounds had unmatched samplerates $(samplerate.(xs)).")

  sorted = sort(collect(xs),by=nsamples,rev=true)
  y = similar(xs[1],(len,channels))
  y .= sorted[1]

  for x in sorted[2:end]
    y[1:nsamples(x),:] .= op.(y[1:nsamples(x),:],x[:,:])
  end

  y
end


"""
    silence(length;[rate=samplerate()])

Creates period of silence of the given length (in seconds).
"""
function silence(length;rate=samplerate())
  audible(t -> zeros(t),length,false,rate=rate)
end

"""
    envelope(mult,length;[rate_Hz=44100])

creates an envelope of a given multiplier and length (in seconds).

If mult = 0 this is the same as calling [`silence`](@ref). This function
is useful in conjunction with [`fadeto`](@ref) and [`mult`](@ref)
when defining an envelope that changes in level. For example,
the following will play a 1kHz tone for 1 second, which changes
in volume halfway through to a softer level.

    mult(tone(1000,1),fadeto(envelope(1,0.5),envelope(0.1,0.5)))

"""
function envelope(mult,length;rate=samplerate())
  audible(t -> mult*ones(t),length,rate=rate)
end

"""
    noise(length=Inf;[rate=samplerate()],[rng=RandomDevice()])

Creates a period of white noise of the given length (in seconds).

"""
function noise(len=Inf;rate=samplerate(),rng=RandomDevice())
  audible(i -> 1.0-2.0rand(rng,length(i)),len,false,rate=rate)
end

"""
    tone(freq,length;[rate=samplerate()],[phase=0])

Creates a pure tone of the given frequency and length (in seconds).

"""
function tone(freq,len=Inf;rate=samplerate(),phase=0.0)
  freq_Hz = ustrip(inHz(freq))
  audible(t -> sin.(2π*t * freq_Hz + phase),len,rate=rate)
end

function complex_cycle(f0,harmonics,amps,rate,phases)
  @assert all(0 .<= phases) && all(phases .< 2π)
	n = maximum(harmonics)+1

  # generate single cycle of complex
  cycle = silence((1/f0),rate=rate)

	highest_freq = tone(f0,2n*length(cycle)*samples;rate=rate)

	for (amp,harm,phase) in zip(amps,harmonics,phases)
		phase_offset = round(Int,n*phase/2π*rate/f0)
    wave = highest_freq[(1:length(cycle)) * (n-harm) + phase_offset]
		cycle += amp*wave[1:length(cycle)]
	end

  cycle
end

"""
    harmonic_complex(f0,harmonics,amps,length,
                     [rate=samplerate()],[phases=zeros(length(harmonics))])

Creates a harmonic complex of the given length, with the specified harmonics
at the given amplitudes. This implementation is somewhat superior
to simply summing a number of pure tones generated using `tone`, because
it avoids beating in the sound that may occur due floating point errors.

"""
function harmonic_complex(f0,harmonics,amps,len=Inf;
						              rate=samplerate(),
                          phases=zeros(length(harmonics)))
  cycle = complex_cycle(inHz(f0),harmonics,amps,
                        inHz(Int,rate),phases)
  N = size(cycle,1)
  audible(i -> cycle[(i.-1) .% N + 1],len,false,rate=rate)
end

"""
    irn(n,λ,[length=Inf];[g=1],[rate=samplerate()],
                         [rng=Base.GLOBAL_RNG])

Creates an iterated ripple ``y_n(t)`` for a noise ``y_0(t)`` according to
the following formula.

``
y_n(t) = y_{n-1}(t) + g⋅y_{n-1}(t-d)
``
"""
function irn(n,λ,length=Inf;g=1,rate=samplerate(),rng=Base.GLOBAL_RNG)
  irn_helper(noise(length,rate=rate,rng=rng),n,λ,g,rng)
end

function irn_helper(source,n,λ,g,rng)
  if n == 0
    source
  else
    irn_helper(mix(source,[silence(λ); g * source]),n-1,λ,g,rng)
  end
end

"""
    bandpass(x,low,high;[order=5])

Band-pass filter the sound at the specified frequencies.

Filtering uses a butterworth filter of the given order.
"""
bandpass(x,low,high;order=5) = filter_helper(x,low,high,Bandpass,order)

"""
    bandstop(x,low,high,[order=5])

Band-stop filter of the sound at the specified frequencies.

Filtering uses a butterworth filter of the given order.
"""
bandstop(x,low,high;order=5) = filter_helper(x,low,high,Bandstop,order)

"""
    lowpass(x,low,[order=5])

Low-pass filter the sound at the specified frequency.

Filtering uses a butterworth filter of the given order.
"""
lowpass(x,low;order=5) = filter_helper(x,low,0,Lowpass,order)

"""
    highpass(x,high,[order=5])

High-pass filter the sound at the specified frequency.

Filtering uses a butterworth filter of the given order.
"""
highpass(x,high;order=5) = filter_helper(x,0,high,Highpass,order)

function buildfilt(samplerate,low,high,kind)
  if kind == Bandpass
	  Bandpass(float(ustrip(inHz(low))),float(ustrip(inHz(high))),fs=samplerate)
  elseif kind == Lowpass
    Lowpass(float(ustrip(inHz(low))),fs=samplerate)
  elseif kind == Highpass
    Highpass(float(ustrip(inHz(high))),fs=samplerate)
  elseif kind == Bandstop
    Bandstop(float(ustrip(inHz(low))),float(ustrip(inHz(high))),fs=samplerate)
  end
end

function filter_helper(sound,low,high,kind,order)
  ftype = buildfilt(ustrip(samplerate(sound)),low,high,kind)
  f = digitalfilter(ftype,Butterworth(order))
  Sound(DSP.filt(f,sound),samplerate(sound))
end

"""
    ramp(x,[length=5ms])

Applies a half cosine ramp to start and end of the sound.

Ramps prevent clicks at the start and end of sounds.
"""
function ramp(x,len=5ms)
  ramp_n = insamples(len,samplerate(x))
	if nsamples(x) < 2ramp_n
    error("Cannot apply two $(rounded_time(len,samplerate(x))) ramps to ",
          "$(rounded_time(duration(x),samplerate(x))) sound.")
  end

  n = nsamples(x)
	r = audible(duration(x),false,rate=samplerate(x)) do t
    ifelse.(t .< ramp_n,
      -0.5.*cos.(π.*t./ramp_n).+0.5,
    ifelse.(t .< n .- ramp_n,
      1,
      -0.5.*cos.(π.*(t .- n .+ ramp_n)./ramp_n.+π).+0.5))
	end
	mult(x,r)
end

"""
    rampon(sound,[len=5ms])

Applies a half consine ramp to start of the sound.
"""
function rampon(x,len=5ms)
  ramp_n = insamples(len,samplerate(x))
	if nsamples(x) < ramp_n
    error("Cannot apply a $(rounded_time(len,samplerate(x))) ramp to ",
          "$(rounded_time(duration(x),samplerate(x))) sound.")
  end

	r = audible(ramp_n*samples,false,rate=samplerate(x)) do t
    -0.5.*cos.(π.*t./ramp_n).+0.5
	end
	mult(x,r)
end

"""
    rampoff(sound,[len=5ms],[after=len])

Applies a half consine ramp to the end of the sound.
"""

function rampoff(x,len=5ms)
  len = insamples(len,samplerate(x))
  after = nsamples(x)

  R = ustrip(samplerate(x))
  if !(0 < after <= nsamples(x))
    if len_s > nsamples(x)
      error("Cannot apply $(rounded_time(len_s/R,R)) ramp to",
            " $(rounded_time(duration(x),R)) of audio.")
    else
      error("Cannot apply $(rounded_time(len_s/R,R)) ramp after ",
            "$(rounded_time(after/R - len_s/R,R)) to",
            " $(rounded_time(duration(x),R)) of audio.")
    end
  end

  rampstart = (after - len_s)
	r = audible(after*samples,false) do t
    ifelse.(t .< rampstart,1,-0.5.*cos.(π.*(t.-rampstart)./len_s.+π).+0.5)
	end
	mult(limit(x,after),r)
end

"""
    fadeto(a,b,[transition=50ms],[after=overlap])

A smooth transition from a to b, overlapping the end of one
with the start of the other by `overlap`.
"""
function fadeto(a,b,transition=50ms)
  @assert(samplerate(a) == samplerate(b),
          "Sounds must have the same sample rate.")
  mix(rampoff(a,transition),
      [silence(duration(a) - transition); rampon(b,transition)])
end

"""
    amplify(x,dB)

Amplify (positive) or attenuate (negative) the sound by a given number of
decibels

"""
amplify(x,dB) = 10^(dB/20) .* x

"""
    normalize(x)

Normalize the sound so it has a power of 1.
"""
normalize(x) = x ./ sqrt(mean(x.^2))


"""
    leftright(left,right)

Create a stereo sound from two monaural sounds.
"""
function leftright(x,y)
  @assert(samplerate(x) == samplerate(y),
          "Sounds had unmatched samplerates $(samplerate.((x,y))).")
  @assert size(x,2) == size(y,2) == 1 "Expected two monaural sounds."

  len = maximum(nsamples.((x,y)))
  z = similar(x,(len,2))
  z .= zero(x[1])
  z[1:nsamples(x),1] = x
  z[1:nsamples(y),2] = y
  z
end

"""
    resample(x::Sound,new_rate)

Returns a new sound representing `x` at the given sampling rate.

You will loose all frequencies in `x` that are above `new_rate/2` if you
reduce the sampling rate. This will produce a warning.
"""
function resample(x,new_rate)
  R = ustrip(inHz(samplerate(x)))
  new_rate = floor(Int,ustrip(inHz(new_rate)))
  if new_rate < R
    warn("The function `resample` reduced the sample rate, high freqeuncy",
         " information above $(new_rate/2) will be lost.")
  end
  T = eltype(x)
  if isstereo(x)
    Sound{new_rate,T,2}(hcat(T.(resample(left(x),new_rate // R)),
                             T.(resample(right(x),new_rate // R))))
  else
    Sound{new_rate,T,1}(T.(resample(x,new_rate // R)))
  end
end
