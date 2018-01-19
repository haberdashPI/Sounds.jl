using FixedPointNumbers
using FileIO
using Lazy: @>, @>>
using IntervalSets
using SampledSignals

import FileIO: save
import DSP: resample
import LibSndFile

import Base: setindex!, getindex, size, similar

import Distributions: nsamples

export sound, playable, duration, nchannels, nsamples, save, samplerate, length,
  samples, vcat, leftright, similar, left, right, resample,
  audiofn, .., ends, data

struct Sound{R,T,N} <: AbstractArray{T,N}
  data::Array{T,N}
  """
      Sound(x::Array;[rate=samplerate()])

  Creates a sound object from an arbitrary array.

  Assumes 1 is the loudest and -1 the softest. The array should be 1d for mono
  signals, or an array of size (N,2) for stereo sounds.
  """
  function Sound{T,N}(x::Array{T,N};rate=samplerate()) where {T <: Number,N}
    if N ∉ [1,2]
      error("Array must have 1 or 2 dimensions to be converted to a sound.")
    end

    R = ustrip(inHz(rate))
    new{R,T,N}(x)
  end
end
convert(::Type{Sound{R,T,N}},x) where {R,T,N} =
  Sound{R,T,N}(convert(Array{T,N},x))
function convert(::Type{Sound{R,T,N}},x::Sound{R,S,N}) where {R,T,S,N}
  Sound{R,T,N}(convert(Array{T,N},x.data))
end
function convert{R,Q,T,S}(::Type{Sound{R,T}},x::Sound{Q,S})
  error("Cannot convert a sound with sampling rate $(Q*Hz) to a sound with ",
        "sampling rate $(R*Hz). Use `resample` to change the sampling rate.")
end

function Base.Array(x::Sound{R,T,N}) where {R,T,N}
  x.data
end

"""
    Sound(file)

Load a specified file as a `Sound` object.
"""
Sound(file::File) = Sound(load(file))
Sound(file::String) = Sound(load(file))
Sound(stream::IOStream) = Sound(load(stream))

save(file::Union{AbstractString,IO},sound::Sound) = save(file,SampleBuf(sound))

SampledSignals.SampleBuf(x::Sound) =
  SampledSignals.SampleBuf(x.data,float(samplerate(x)))
function AxisArrays.AxisArray(x::Sound)
  time_axis = Axis{:time}(((1:nsamples(x))-1)/samplerate(x))
  ismono(x) ? AxisArray(x,time_axis) :
    AxisArray(x,time_axis,Axis{:channel}([:left,:right]))
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
length(x::Sound) = length(x.data)

"""
    asstereo(x)

Returns a stereo version of a sound (wether it is stereo or monaural).
"""
asstereo(x::Sound{R,T,1}) where {R,T} = hcat(x.data,x.data)
asstereo(x::Sound{R,T,2}) where {R,T} =
  size(x,2) == 1 ? hcat(x.data,x.data) : x.data

"""
    asmono(x)

Returns a monaural version of a sound (whether it is stereo or manaural).
"""
asmono(x::Sound{R,T,1}) where {R,T} = x.data
asmono(x::Sound{R,T,2}) where {R,T} =
  size(x,2) == 1 ? squeeze(x,2) : squeeze(mix(x[:left],x[:right]),2)

"""
    ismono(x)

True if the sound is monaural.
"""
ismono(x::Sound{R,T,1}) where {R,T} = true
ismono(x::Sound{R,T,2}) where {R,T} = nchannels(x) == 1

"""
    isstereo

True if the sound is stereo.
"""
isstereo(x::Sound) = !ismono(x)

vcat(xs::Sound...) = error("Sample rates differ, fix with `resample`.")
function vcat(xs::Sound{R}...) where R
  T = promote_type(map(eltype,xs)...)
  vcat((map(el -> convert(T,el),x) for x in xs)...)
end
vcat(xs::Sound{R,T,1}...) where {R,T} =
    Sound{R,T,1}(vcat(map(x -> x.data,xs)...))
function vcat(xs::Sound{R,T}...) where {R,T}
  if any(!ismono,xs)
    Sound{R,T,2}(vcat(map(asstereo,xs)...))
  else
    Sound{R,T,1}(vcat(map(asmono,xs)...))
  end
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
nchannels(x::Sound) = size(x.data,2)

"""
    nsamples(sound)

Returns the number of samples in the sound.

The number of samples is not always the same as the `length` of the sound.
Stereo sounds have a length of 2 x nsamples(sound).
"""
nsamples(x::Sound) = size(x.data,1)
size(x::Sound) = size(x.data)
Base.IndexStyle(::Type{Sound}) = IndexCartesian()

"""
    left(sound)

Extract the left channel of a sound. For monaural sounds, `left` and `right`
return the same value.
"""
left(sound) = size(sound,2) == 1 ? sound : sound[:,1]
left(sound::AxisArray) =
    size(data,2) == 1 ? sound : sound[Axis{:channel}(:left)]

"""
    right(sound)

Extract the right channel of a sound. For monaural sounds, `left` and `right`
return the same value.
"""
right(sound) = size(sound,2) == 1 ? sound : sound[:,2]
right(sound::AxisArray) =
    size(data,2) == 1 ? sound : sound[Axis{:channel}(:right)]

# adapted from:
# https://github.com/JuliaAudio/SampledSignals.jl/blob/0a31806c3f7d382c9aa6db901a83e1edbfac62df/src/SampleBuf.jl#L109-L139
rounded_time(x,R) = round(ustrip(inseconds(x,R)),ceil(Int,log(10,R)))*s
function show(io::IO, x::Sound{R}) where R
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
show(io::IO, ::MIME"text/plain", x::Sound) = show(io,x)

const ticks = ['_','▁','▂','▃','▄','▅','▆','▇']
function showchannels(io::IO, x::Sound, widthchars=80)
  # number of samples per block
  blockwidth = round(Int, nsamples(x)/widthchars, RoundUp)
  nblocks = round(Int, nsamples(x)/blockwidth, RoundUp)
  blocks = Array{Char}(nblocks, nchannels(x))
  for blk in 1:nblocks
    i = (blk-1)*blockwidth + 1
    n = min(blockwidth, nsamples(x)-i+1)
    peaks = sqrt.(mean(float(x[(1:n)+i-1,:]).^2,1))
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


@inline function Base.getindex(x::Sound,i::Int)
  @boundscheck checkbounds(x.data,i)
  @inbounds return x.data[i]
end

@inline function Base.setindex!{R,T,S}(x::Sound{R,T},v::S,i::Int)
  @boundscheck checkbounds(x.data,i)
  @inbounds return x.data[i] = convert(T,v)
end


@inline function Base.getindex(x::Sound,i::Int,j::Int)
  @boundscheck checkbounds(x.data,i,j)
  @inbounds return x.data[i,j]
end

@inline function setindex!{R,T,S}(x::Sound{R,T},v::S,i::Int,j::Int)
  @boundscheck checkbounds(x.data,i,j)
  @inbounds return x.data[i,j] = convert(T,v)
end

struct EndSecs; end
const ends = EndSecs()

struct ClosedIntervalEnd{N}
  from::Quantity{N}
end
minimum(x::ClosedIntervalEnd) = x.from

IntervalSets.:(..)(x::Time,::EndSecs) = ClosedIntervalEnd(x)
IntervalSets.:(..)(x::SampleQuant,::EndSecs) = ClosedIntervalEnd(x)
IntervalSets.:(..)(x,::EndSecs) = error("Unexpected quantity $x in interval.")

function checktime(time)
  if ustrip(time) < 0
    throw(BoundsError("Unexpected negative time."))
  end
end

function getindex(x::Sound,js::Symbol)
  if js == :left || (js == :right && size(x,2) == 1)
    getindex(x,:,1)
  elseif js == :right
    getindex(x,:,2)
  else
    throw(BoundsError(x,js))
  end
end

@inline @Base.propagate_inbounds function getindex(x::Sound,ixs,js::Symbol)
  if js == :left || (js == :right && size(x,2) == 1)
    getindex(x,ixs,1)
  elseif js == :right
    getindex(x,ixs,2)
  else
    throw(BoundsError(x,js))
  end
end
@inline @Base.propagate_inbounds function setindex!(x::Sound,vals,ixs,js::Symbol)
  if js == :left || (js == :right && size(x,2) == 1)
    setindex!(x,vals,ixs,1)
  elseif js == :right
    setindex!(x,vals,ixs,2)
  else
    throw(BoundsError(x,js))
  end
end

########################################
# getindex
const Index = Union{Integer,Range,AbstractVector,Colon}
@inline function getindex(x::Sound{R,T},
                          ixs::ClosedIntervalEnd,js::I) where {R,T,I <: Index}
  @boundscheck checktime(minimum(ixs))
  from = max(1,insamples(minimum(ixs),R*Hz))
  @boundscheck checkbounds(x.data,from,js)
  @inbounds return Sound{R,T,2}(x.data[from:end,js])
end

@inline function
    getindex(x::Sound{R,T,N},
             ixs::ClosedInterval{TM},js::I) where {R,T,I <: Index,N,TM <: Quantity}
  @boundscheck checktime(minimum(ixs))
  from = max(1,insamples(minimum(ixs),R*Hz))
  to = insamples(maximum(ixs),R*Hz)-1
  @boundscheck checkbounds(x.data,from:to,js)
  @inbounds result = x.data[from:to,js]
  return Sound{R,T,ndims(result)}(result)
end

@inline function getindex(x::Sound{R,T},ixs::ClosedIntervalEnd) where {R,T}
  @boundscheck checktime(minimum(ixs))
  from = max(1,insamples(minimum(ixs),R*Hz))
  if size(x,2) == 1
    @boundscheck checkbounds(x.data,from)
    @inbounds return Sound{R,T,1}(x.data[from:end])
  else
    @boundscheck checkbounds(x.data,from,:)
    @inbounds return Sound{R,T,2}(x.data[from:end,:])
  end
end

@inline function getindex(x::Sound{R,T},
                          ixs::ClosedInterval{TM}) where {R,T,TM <: Quantity}
  @boundscheck checktime(minimum(ixs))
  from = max(1,insamples(minimum(ixs),R*Hz))
  to = insamples(maximum(ixs),R*Hz)-1
  if size(x,2) == 1
    @boundscheck checkbounds(x.data,from)
    @boundscheck checkbounds(x.data,to)
    @inbounds return Sound{R,T,1}(x.data[from:to])
  else
    @boundscheck checkbounds(x.data,from,:)
    @boundscheck checkbounds(x.data,to,:)
    @inbounds return Sound{R,T,2}(x.data[from:to,:])
  end
end

########################################
# setindex

@inline function setindex!{R,T,I}(
  x::Sound{R,T},vals::AbstractArray,ixs::ClosedIntervalEnd,js::I)
  @boundscheck checktime(minimum(ixs))
  from = max(1,insamples(minimum(ixs),R*Hz))
  @boundscheck checkbounds(x.data,from,js)
  @inbounds x.data[from:end,js] = vals
  vals
end

@inline function setindex!(
  x::Sound{R,T},vals::AbstractArray,
  ixs::ClosedInterval{TM},js::I) where {R,T,I,TM <: Quantity}
  @boundscheck checktime(minimum(ixs))
  from = max(1,insamples(minimum(ixs),R*Hz))
  to = insamples(maximum(ixs),R*Hz)-1
  @boundscheck checkbounds(x.data,from,js)
  @boundscheck checkbounds(x.data,to,js)
  @inbounds x.data[from:to,js] = vals
  vals
end

@inline function setindex!{R,T}(
  x::Sound{R,T},vals::AbstractArray,ixs::ClosedIntervalEnd)
    @boundscheck checktime(minimum(ixs))
    from = max(1,insamples(minimum(ixs),R*Hz))
    if size(x,2) == 1
      @boundscheck checkbounds(x.data,from)
      @inbounds x.data[from:end] = vals
    else
      @boundscheck checkbounds(x.data,from,:)
      @inbounds x.data[from:end,:] = vals
    end
    vals

end

@inline function setindex!(
    x::Sound{R,T},vals::AbstractArray,
    ixs::ClosedInterval{TM}) where {R,T,TM <: Quantity}
  @boundscheck checktime(minimum(ixs))
  from = max(1,insamples(minimum(ixs),R*Hz))
  to = insamples(maximum(ixs),R*Hz)-1
  if size(x,2) == 1
    @boundscheck checkbounds(x.data,from:to)
    @inbounds x.data[from:to] = vals
  else
    @boundscheck checkbounds(x.data,from:to,:)
    @inbounds x.data[from:to,:] = vals
  end
  vals
end

function similar(x::Sound{R,T,N},::Type{S},dims::NTuple{M,Int}) where {R,T,S,N,M}
  if M ∉ [1,2] || (M == 2 && dims[2] ∉ [1,2])
    warn("Sounds must have 1 or 2 dimensions and 1 or 2 channels."*
         "Sounds cannot be created from any other array dimensions.")
    similar(x.data,S,dims)
  else
    Sound{R,S,M}(similar(x.data,S,dims))
  end
end
