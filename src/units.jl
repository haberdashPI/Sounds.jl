using Unitful
import Unitful: ms, s, kHz, Hz, dB
export dB, ms, s, kHz, Hz, frames, uconvert, ustrip, inseconds, inHz, inframes

const TimeDim = Unitful.Dimensions{(Unitful.Dimension{:Time}(1//1),)}
const FreqDim = Unitful.Dimensions{(Unitful.Dimension{:Time}(-1//1),)}
const Time{N} = Quantity{N,TimeDim}
const Freq{N} = Quantity{N,FreqDim}

@dimension 𝐅r "Fr" Frame
@refunit frames "frames" Frames 𝐅r false
const FrameDim = Unitful.Dimensions{(Unitful.Dimension{:Frame}(1//1),)}
const FrameQuant{N} = Quantity{N,FrameDim}

"""
    inframes(quantity,rate)

Translate the given quantity (usually a time) to a sample index, given
a particualr samplerate.

# Example

> inframes(1s,44100Hz)
44100

"""
inframes{N <: Integer}(time::FrameQuant{N},rate) = ustrip(time)
inframes{N}(time::FrameQuant{N},rate) =
  error("Cannot use non-integer frames.")
function inframes(time,rate)
  r = inHz(rate)
  floor(Int,ustrip(inseconds(time,r)*r))
end
function inframes{N,M}(time::Time{N},rate::Freq{M})
  floor(Int,ustrip(uconvert(s,time)*uconvert(Hz,rate)))
end

"""
    inHz(quantity)

Translate a particular quantity (usually a frequency) to a value in Hz.

# Example

> inHz(1.0kHz)
1000.0 Hz

"""
inHz(x::Quantity) = uconvert(Hz,x)
inHz(typ::Type{N},x::Q) where {N <: Number,Q <: Quantity} =
  floor(N,ustrip(inHz(x)))*Hz
inHz(typ::Type{N},x::N) where {N <: Number} = inHz(x)

"""
   inseconds(quantity)

Translate a particular quantity (usually a time) to a value in seconds.

# Example
> inseconds(50.0ms)
0.05 s

"""
inseconds(x::FrameQuant,R) = (ustrip(x) / R)*s
inseconds(x::Time) = uconvert(s,x)
inseconds(x::Quantity,R) = uconvert(s,x)
inseconds(x::Number,R) = inseconds(x)
inseconds(x::FrameQuant) =
  error("Expected second argument, specifying sample rate.")
