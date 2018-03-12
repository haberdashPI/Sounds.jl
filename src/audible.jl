using DSP
using Unitful

export samplerate, set_default_samplerate!, mix, envelope, silence,
  envelope, noise, highpass, lowpass, bandpass, bandstop, tone, ramp,
  harmonic_complex, amplify, rampon, rampoff, fadeto, irn, samplerate,
  normpower



"""
    mix(x,...)

Add several sounds together so that they play at the same time.

Unlike normal addition, this acts as if each sound is padded with
zeros at the end so that the lengths of all sounds match and sounds
of differing fidelity are promoted to the highest fidelity representation.

With one argument `x`, this returns a function `f(y)` that mixes `y` with `x`
"""
mix(xs...) = soundop(+,xs...)
mix(x) = y -> mix(x,y)

"""
    envelope([x],y)

Mutliply several sounds together. Typically used to apply an
amplitude envelope x to sound y.

Unlike normal multiplication, this acts as if each sound is padded with
ones at the end so that the lengths of all sounds match and sounds
of differing fidelity are promoted to the highest fidelity representation.

With one argument `x`, this returns a function `f(y)` that multiplies `y` with `x`
"""
envelope(x,y) = soundop(*,x,y)
envelope(x) = y -> envelope(x,y)

function soundop(op,x_in...)
  xs = promote_sounds(x_in...)
  len = maximum(nsamples.(xs))

  sorted = sortperm(collect(nsamples.(xs)),rev=true)
  y = similar(xs[1],(len,nchannels(xs[1])))
  y .= xs[sorted[1]]

  for i in sorted[2:end]
    y[1:nsamples(xs[i]),:] .= op.(y[1:nsamples(xs[i]),:],xs[i][:,:])
  end

  y
end


"""
    silence(length;[rate=samplerate()])

Creates period of silence of the given length (in seconds).
"""
function silence(length;rate=samplerate())
  Sound(t -> fill(0.0,size(t)),length,false,rate=rate)
end

"""
    dc_offset(length;[rate_Hz=44100])

Creates a DC offset of unit value.

In other words, this just returns samples all with the value 1: `silence` is
to `zeros` just as `dc_offset` is to `ones`.
"""
function dc_offset(length;rate=samplerate())
  Sound(t -> fill(1.0,size(t)),length,false,rate=rate)
end

"""
    noise(length=Inf;[rate=samplerate()],[rng=RandomDevice()])

Creates a period of white noise of the given length (in seconds).

"""
function noise(len=Inf;rate=samplerate(),rng=RandomDevice())
  Sound(i -> 1.0-2.0rand(rng,length(i)),len,false,rate=rate)
end

"""
    tone(freq,length;[rate=samplerate()],[phase=0])

Creates a pure tone of the given frequency and length (in seconds).

"""
function tone(freq,len=Inf;rate=samplerate(),phase=0.0)
  freq_Hz = ustrip(inHz(freq))
  Sound(t -> sin.(2π*t * freq_Hz + phase),len,rate=rate)
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
  Sound(i -> cycle[(i.-1) .% N + 1],len,false,rate=rate)
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
    bandpass([x],low,high;[order=5])

Band-pass filter the sound at the specified frequencies.

Filtering uses a butterworth filter of the given order.

With two positional arguments this returns a function f(x)
that applies the filter on x.
"""
bandpass(x,low,high;order=5) = filter_helper(x,low,high,Bandpass,order)
bandpass(low,high;order=5) = x -> bandpass(x,low,high,order=order)

"""
    bandstop([x],low,high,[order=5])

Band-stop filter of the sound at the specified frequencies.

Filtering uses a butterworth filter of the given order.

With two positional arguments this returns a function f(x)
that applies the filter on x.
"""
bandstop(x,low,high;order=5) = filter_helper(x,low,high,Bandstop,order)
bandstop(low,high;order=5) = x -> bandstop(x,low,high,order=order)

"""
    lowpass([x],low,[order=5])

Low-pass filter the sound at the specified frequency.

Filtering uses a butterworth filter of the given order.

With two positional arguments this returns a function f(x)
that applies the filter on x.
"""
lowpass(x,low;order=5) = filter_helper(x,low,0,Lowpass,order)
lowpass(low,high;order=5) = x -> lowpass(x,low,high,order=order)

"""
    highpass([x],high,[order=5])

High-pass filter the sound at the specified frequency.

Filtering uses a butterworth filter of the given order.

With two positional arguments this returns a function f(x)
that applies the filter on x.
"""
highpass(x,high;order=5) = filter_helper(x,0,high,Highpass,order)
highpass(low,high;order=5) = x -> highpass(x,low,high,order=order)

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
  Sound(DSP.filt(f,sound),rate=samplerate(sound))
end

"""
    ramp([x],[length=5ms])

Applies a half cosine ramp to start and end of the sound.

Ramps prevent clicks at the start and end of sounds.

When passed no argument or a length, this returns a function f(x)
which applies the specified ramp to the sound `x`.
"""
function ramp(x::AbstractArray,length=5ms)
  ramp_n = insamples(length,samplerate(x))
	if nsamples(x) < 2ramp_n
    error("Cannot apply two $(rounded_time(length,samplerate(x))) ramps to ",
          "$(rounded_time(duration(x),samplerate(x))) sound.")
  end

  n = nsamples(x)
	r = Sound(n*samples,false,rate=samplerate(x)) do t
    ifelse.(t .< ramp_n,
      -0.5.*cos.(π.*t./ramp_n).+0.5,
    ifelse.(t .< n .- ramp_n,
      1.0,
      -0.5.*cos.(π.*(t .- n .+ ramp_n)./ramp_n.+π).+0.5))
	end
	envelope(x,r)
end
ramp(length=5ms) = x -> ramp(x,length)

"""
    rampon([sound],[length=5ms])

Applies a half consine ramp to start of the sound.

When passed no argument or a length, this returns a function f(x)
which applies the specified ramp to the sound `x`.
"""
function rampon(x::AbstractArray,length=5ms)
  ramp_n = insamples(length,samplerate(x))
	if nsamples(x) < ramp_n
    error("Cannot apply a $(rounded_time(length,samplerate(x))) ramp to ",
          "$(rounded_time(duration(x),samplerate(x))) sound.")
  end

	r = Sound(ramp_n*samples,false,rate=samplerate(x)) do t
    -0.5.*cos.(π.*t./ramp_n).+0.5
	end
	envelope(x,r)
end
rampon(length=5ms) = x -> rampon(x,length=length)

"""
    rampoff([sound],[length=5ms])

Applies a half consine ramp to the end of the sound.

With no positional arguments this returns a function f(x) that
applies the ramp to x.
"""
function rampoff(x::AbstractArray,length=5ms)
  len_s = insamples(length,samplerate(x))
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
	r = Sound(after*samples,false) do t
    ifelse.(t .< rampstart,1,-0.5.*cos.(π.*(t.-rampstart)./len_s.+π).+0.5)
	end
	envelope(x,r)
end
rampoff(length=5ms) = x -> rampon(x,length=length)

"""
    fadeto([a],[b],[transition=50ms])

A smooth transition from a to b, overlapping the end of one
with the start of the other by `overlap`.

With only one sound `a` specified, this returns a function `f(b)` that fades
from `a` to `b`.
"""
function fadeto(a::AbstractArray,b::AbstractArray,transition=50ms)
  @assert(samplerate(a) == samplerate(b),
          "Sounds must have the same sample rate.")
  mix(rampoff(a,transition),
      [silence(duration(a) - transition,rate=samplerate(a));
       rampon(b,transition)])
end
fadeto(b::AbstractArray,transition=50ms) = a -> fadeto(a,b,transition)

"""
    amplify([x],ratio)

Amplify (positive) or attenuate (negative) the sound by a given ratio, typically
specified in decibels (e.g. amplify(x,10dB)).

*Note*: you can also directly multiply by a factor, e.g. x * 10dB,
which has the same effect as this function.

With one position argument `ratio` this returns a function which scales its
input by th given ratio.
"""
amplify(x,ratio) = x*uconvertrp(unit(1),ratio)
amplify(ratio) = x -> amplify(x,ratio)

"""
    normpower(x)

Normalize the sound so it has a power of 1.
"""
normpower(x) = x ./ sqrt.(mean(x.^2,1))
normpower(x::Sound{R,T,C}) where {R,T,C} = Sound(R,C,x ./ sqrt.(mean(x.^2,1)))
