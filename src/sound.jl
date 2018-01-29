using FixedPointNumbers
using FileIO
using Lazy: @>, @>>
using IntervalSets

import FileIO: save
import DSP: resample
import LibSndFile

import Base: setindex!, getindex

import Distributions: nsamples

import SampledSignals: SampleBuf

export sound, playable, duration, nchannels, nsamples, save, samplerate, length,
  samples, leftright, similar, left, right, resample,
  audiofn, .., ends, data, Sound, ismono, isstereo

struct Sound{R,T,C,N} <: AbstractArray{T,N}
  data::AbstractArray{T,N}
  function Sound(R::Int,C::Int,x::AbstractArray{T,N}) where {T,N}
    @assert(1 <= C <= 2, "Number of sound channels ($C) must be 1 or 2.")
    @assert(size(x,2) == C,
            "Sounds channels ($C) and data columns ($size(x,2)) must match.")
    @assert(1 <= ndims(x) <= 2,
            "Sound arrays must have 1 or 2 dimensions.")
    @assert(!(T <: Integer),
            "Sounds cannot hold integer value ($T). Use `FixedPointNumbers` instead.")
    new{R,T,C,N}(x)
  end
end

MonoSound{R,T,N} = Sound{R,T,1,N}
StereoSound{R,T,N} = Sound{R,T,2,N}

"""
    Sound(x::AbstractArray;[rate=samplerate(x)])

Creates a sound object from an array.

Assumes 1 is the loudest and -1 the softest. The array should be 1d for mono
signals, or an array of size (N,2) for stereo sounds.
"""
function Sound(x::AbstractArray;rate=samplerate())
  R = floor(Int,ustrip(inHz(rate)))
  Sound(R,size(x,2),x)
end

function Sound(x::Sound;rate=samplerate(x))
  if rate == samplerate(x)
    x
  else
    resample(x,rate)
  end
end

Base.convert(to::Type{<:Sound},x::Array) = convert(to,Sound(x,rate=R*Hz))

function Base.convert(to::Type{Sound{R1,T1,C1}},
                      x::Sound{R2,T2,C2}) where {R1,R2,T1,T2,C1,C2}
  if R1 != R2
    convert(to,resample(x,R1*Hz))
  elseif C1 != C2
    if C1 == 1
      convert(to,asmono(x))
    else
      convert(to,asstereo(x))
    end
  elseif T1 != T2
    Sound(R1,C1,convert(Array{T1},x.data))
  else
    x
  end
end

"""

    resample(x::Sound,new_rate;warn=true)

Returns a new sound representing `x` at the given sampling rate.

You will loose all frequencies in `x` that are above `new_rate/2` if you
reduce the sampling rate. This will produce a warning unless `warn` is false.

"""

function resample(x::Sound,new_rate::Quantity;warn=true)
  R = ustrip(inHz(Int,samplerate(x)))
  new_rate = floor(Int,ustrip(inHz(new_rate)))
  if new_rate < R && warn
    Base.warn("The function `resample` reduced the sample rate, high freqeuncy"*
              " information above $(new_rate/2) will be lost.",
              bt=backtrace())
  elseif new_rate == R
    return x
  end

  T = eltype(x)
  if isstereo(x)
    Sound(new_rate,2,hcat(T.(resample(x.data[:,1],new_rate // R)),
                          T.(resample(x.data[:,2],new_rate // R))))
  else
    Sound(new_rate,1,T.(resample(x.data[:],new_rate // R)))
  end
end

function resample(x::Sound{R,T,C,N},new_rate::Real;warn=true) where {R,T,C,N}
  resample(x,inHz(new_rate),warn=warn)
end

function Base.Array(x::Sound{R,T,C}) where {R,T,C}
  x.data
end

"""
    Sound(file)

Load a specified file as a `Sound` object.
"""
Sound(file::File) = Sound(load(file))
Sound(file::String) = Sound(load(file))
Sound(stream::IOStream) = Sound(load(stream))

"""
    Sound(x::SampledSignals.SampleBuf)

Convert `SampleBuf` to `Sound` object, without copying data.
"""
Sound(x::SampleBuf) = Sound(x.data,rate=samplerate(x)*Hz)

"""
    Sound(x::AxisArray)

Convert `AxisArray` to `Sound` object. Avoids copying data when possible
(e.g. when underlying data is an `Array` object).
"""
Sound(x::AxisArray) = Sound(x.data,rate=samplerate(x))

save(file::Union{AbstractString,IO},sound::Sound) = save(file,SampleBuf(sound))

SampleBuf(x::Sound) = SampleBuf(x.data,float(ustrip(samplerate(x))))
function AxisArray(x::Sound)
  time_axis = Axis{:time}(((1:nsamples(x))-1)/samplerate(x))
  ismono(x) ? AxisArray(x,time_axis) :
    AxisArray(x,time_axis,Axis{:channel}([:left,:right]))
end


"""
    Sound(fn,len,asseconds=true;rate=samplerate(),offset=0s)

Creates monaural sound where `fn(t)` returns the amplitudes for a given `Range`
of time points (in seconds as a `Float64`q). The function `fn(t)` should return
values ranging between -1 and 1 as an iterable object, and should be just
as long as `t`.

If `asseconds` is false, `fn(i)` returns the amplitudes for a given `Range` of
sample indices (rather than time points).

If `offset` is specified, return the section of the sound starting
from `offset` (rather than starting from 0 seconds).
"""
function Sound(fn::Function,len=Inf,asseconds=true;
               offset=0s,rate=samplerate())
  rate_Hz = inHz(rate)

  n = ustrip(insamples(offset,rate_Hz))
  m = ustrip(insamples(len,rate_Hz))
  R = floor(Int,ustrip(rate_Hz))
  Sound(!asseconds ? fn(n+1:m) : fn(((n:m-1)-1)/R),rate=rate)
end


"""
    duration(x)

Returns the duration of the sound. If passed an `Array`, takes a
keyword argument `rate=samplerate()`.
"""
function duration(x;rate=samplerate(x))
  uconvert(s,nsamples(x) / inHz(rate))
end

rtype{R}(x::Sound{R}) = R
Base.length(x::Sound) = length(x.data)

"""
    asstereo(x)

Returns a stereo version of a sound (wether it is stereo or monaural).
"""
asstereo(x::Sound{R,T,1}) where {R,T} = leftright(x,x)
asstereo(x::Sound{R,T,2}) where {R,T} = x

"""
    asmono(x)

Returns a monaural version of a sound (whether it is stereo or manaural).
"""
asmono(x::Sound{R,T,1}) where {R,T} = x
asmono(x::Sound{R,T,2}) where {R,T} = mix(left(x),right(x))

"""
    ismono(x)

True if the sound is monaural.
"""
ismono(x::MonoSound) = true
ismono(x::StereoSound) = false

"""
    isstereo

True if the sound is stereo.
"""
isstereo(x::Sound) = !ismono(x)

"""
    xs = promote_sounds(xs)

Given a series of sounds, potentially with differing sample rates, bit rates
and channels, promote all of them to the highest fidelity.
"""
function promote_sounds(xs::Sound...)
  R = maximum(rtype.(xs))
  T = promote_type(map(eltype,xs)...)
  C = maximum(nchannels.(xs))

  map(xs) do x
    convert(Sound{R,T,C},x)
  end
end
promote_sounds(xs::Sound{R,T,C,N}...) where {R,T,C,N} = xs

function Base.vcat(xs::Sound...)
  ys = promote_sounds(xs...)
  R = rtype(ys[1])
  C = nchannels(ys[1])
  Sound(R,C,vcat(map(x -> x.data,ys)...))
end

function Base.:(*)(x::Number,y::Sound)
  z = similar(y)
  z .= x .* y
end

function Base.:(*)(y::Sound,x::Number)
  z = similar(y)
  z .= x .* y
end

"""
    duration(x)

Get the duration of the given sound in seconds.
"""
duration(x::Sound{R}) where R = uconvert(s,nsamples(x) / (R*Hz))

"""
    nchannels(sound)

Return the number of channels (1 for mono, 2 for stereo) in this sound.
"""
nchannels(x::Sound{R,T,C,N}) where {R,T,C,N} = C

"""
    nsamples(sound)

Returns the number of samples in the sound.

The number of samples is not always the same as the `length` of the sound.
Stereo sounds have a length of 2 x nsamples(sound).
"""
nsamples(x::Sound) = size(x.data,1)

"""
    left(sound)

Extract the left channel of a sound. For monaural sounds, `left` and `right`
return the same value.
"""
left(sound::Sound) = sound[:left]
left(sound::AxisArray) =
    size(data,2) == 1 ? sound : sound[Axis{:channel}(:left)]

"""
    right(sound)

Extract the right channel of a sound. For monaural sounds, `left` and `right`
return the same value.
"""
right(sound::Sound) = sound[:right]
right(sound::AxisArray) =
    size(data,2) == 1 ? sound : sound[Axis{:channel}(:right)]

# adapted from:
# https://github.com/JuliaAudio/SampledSignals.jl/blob/0a31806c3f7d382c9aa6db901a83e1edbfac62df/src/SampleBuf.jl#L109-L139
rounded_time(x,rate::Quantity) = rounded_time(x,floor(Int,ustrip(inHz(rate))))
rounded_time(x,rate::Int) = round(ustrip(inseconds(x,rate)),floor(Int,log(10,rate)))*s

function Base.show(io::IO, x::Sound{R,T,N}) where {R,T,N}
  seconds = rounded_time(duration(x),R)
  typ = if eltype(x) == Q0f15
    "16 bit PCM"
  elseif eltype(x) <: AbstractFloat
    "$(sizeof(eltype(x))*8) bit floating-point"
  else
    eltype(x)
  end

  channel = size(x.data,2) == 1 ? "mono" : "stereo"

  println(io, "$seconds $typ $channel sound")
  print(io, "Sampled at $(R*Hz)")
  nsamples(x) > 0 && showchannels(io, x)
end
Base.show(io::IO, ::MIME"text/plain", x::Sound) = show(io,x)

const ticks = ['_','▁','▂','▃','▄','▅','▆','▇']
function showchannels(io::IO, x::Sound, widthchars=80)
  # number of samples per block
  blockwidth = round(Int, nsamples(x)/widthchars, RoundUp)
  nblocks = round(Int, nsamples(x)/blockwidth, RoundUp)
  blocks = Array{Char}(nblocks, nchannels(x))
  for blk in 1:nblocks
    i = (blk-1)*blockwidth + 1
    n = min(blockwidth, nsamples(x)-i+1)
    peaks = sqrt.(mean(float(x.data[(1:n)+i-1,:]).^2,1))
    # clamp to -60dB, 0dB
    peaks = clamp.(20log10.(peaks), -60.0, 0.0)
    idxs = trunc.(Int, (peaks+60)/60 * (length(ticks)-1)) + 1
    blocks[blk, :] = ticks[idxs]
  end
  for ch in 1:nchannels(x)
    println(io)
    print(io, convert(String, blocks[:, ch]))
  end
end

########################################
# AbstractArray interface:

Base.size(x::Sound) = size(x.data)
Base.IndexStyle(::Type{Sound}) = IndexCartesian()

@inline function getindex(x::Sound,ixs::Int...)
  @boundscheck checkbounds(x.data,ixs...)
  @inbounds return getindex(x.data,ixs...)
end

@inline function setindex!(x::Sound,v,ixs::Int...)
  @boundscheck checkbounds(x.data,ixs...)
  @inbounds return setindex!(x.data,v,ixs...)
end

# special casing of single sample of a stereo sound (we need to represent
# this with time as dim 1 and channel as dim 2, while a normal array
# would return a vector.)
@inline function getindex(x::StereoSound{R,T},i::Int,js::Union{Colon,Range}) where {R,T}
  @boundscheck checkbounds(x.data,i,js)
  @inbounds return Sound(R,2,getindex(x.data,i:i,js))
end

############################################################
# custom indexing:

########################################
# indexing by :left and :right

@inline @Base.propagate_inbounds getindex(x::Sound,js::Symbol) =
  getindex(x,:,js)
@inline @Base.propagate_inbounds function getindex(x::Sound,ixs,js::Symbol)
  if js == :left
    getindex(x,ixs,1)
  elseif js == :right
    if nchannels(x) == 1
      getindex(x,ixs,1)
    else
      getindex(x,ixs,2)
    end
  else
    throw(BoundsError(x,js))
  end
end

@inline @Base.propagate_inbounds setindex!(x::Sound,vals,js::Symbol) =
  getindex(x,vals,:,js)
@inline @Base.propagate_inbounds function setindex!(x::Sound,vals,ixs,js::Symbol)
  if js == :left
    setindex!(x,vals,ixs,1)
  elseif js == :right
    if nchannels(x) == 1
      getindex!(x,vals,ixs,1)
    else
      getindex!(x,vals,ixs,2)
    end
  else
    throw(BoundsError(x,js))
  end
end

@inline function setindex!(x::Sound,i::Int,ixs::Union{AbstractVector,Colon})
  @boundscheck checkbounds(x.data,ixs)
  getindex(x.data,i,ixs)
end

########################################
# indexing by time intervals (e.g. x[1s .. 3s])

struct EndSecs; end
const ends = EndSecs()

struct ClosedIntervalEnd{N}
  from::Quantity{N}
end
Base.minimum(x::ClosedIntervalEnd) = x.from

IntervalSets.:(..)(x::Time,::EndSecs) = ClosedIntervalEnd(x)
IntervalSets.:(..)(x::SampleQuant,::EndSecs) = ClosedIntervalEnd(x)
IntervalSets.:(..)(x,::EndSecs) = error("Unexpected quantity $x in interval.")

function checktime(time)
  if ustrip(time) < 0
    throw(BoundsError("Unexpected negative time."))
  end
end

const Index = Union{Integer,AbstractVector,Colon}
const IntervalType = Union{ClosedInterval,ClosedIntervalEnd}

function asrange(x::Sound{R},ixs::ClosedInterval) where R
  checktime(minimum(ixs))
  from = max(1,insamples(minimum(ixs),R*Hz)+1)
  to = insamples(maximum(ixs),R*Hz)
  checkbounds(x.data,from,:)
  checkbounds(x.data,to,:)
  from:to
end

function asrange(x::Sound{R},ixs::ClosedIntervalEnd) where R
  checktime(minimum(ixs))
  from = max(1,insamples(minimum(ixs),R*Hz)+1)
  checkbounds(x.data,from,:)
  from:nsamples(x)
end

getindex(x::MonoSound,interval::IntervalType) = getindex(x,asrange(x,interval))
getindex(x::StereoSound,interval::IntervalType) = getindex(x,asrange(x,interval),:)
getindex(x::Sound,interval::IntervalType,js::Index) =
  getindex(x,asrange(x,interval),js)

setindex!(x::MonoSound,vals::AbstractArray,interval::IntervalType) =
  setindex!(x,vals,asrange(x,interval))
setindex!(x::StereoSound,vals::AbstractArray,interval::IntervalType) =
  setindex!(x,vals,asrange(x,interval),:)
setindex!(x::Sound,vals::AbstractArray,interval::IntervalType,js::Index) =
  setindex!(x,vals,asrange(x,interval),js)

########################################

function Base.similar(x::Sound{R,T,C},::Type{S},
                      dims::Tuple{Vararg{Int64,N}}) where {R,T,C,S,N}
  C2 = length(dims) >= 2 ? dims[2] : 1
  Sound(R,C2,similar(x.data,S,dims))
end

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
