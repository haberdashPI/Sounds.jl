using Unitful
import Unitful: ms, s, kHz, Hz
export ms, s, kHz, Hz, samples, uconvert, ustrip, inseconds, inHz, insamples

const TimeDim = Unitful.Dimensions{(Unitful.Dimension{:Time}(1//1),)}
const FreqDim = Unitful.Dimensions{(Unitful.Dimension{:Time}(-1//1),)}
const Time{N} = Quantity{N,TimeDim}
const Freq{N} = Quantity{N,FreqDim}

@dimension 𝐒 "𝐒" Sample
@refunit samples "samples" Samples 𝐒 false
const SampDim = Unitful.Dimensions{(Unitful.Dimension{:Sample}(1//1),)}
const SampleQuant{N} = Quantity{N,SampDim}

insamples{N <: Integer}(time::SampleQuant{N},rate) = ustrip(time)
insamples{N}(time::SampleQuant{N},rate) = error("Cannot use non-integer samples.")
function insamples(time,rate)
  r = inHz(rate)
  floor(Int,ustrip(inseconds(time,r)*r))
end
function insamples{N,M}(time::Time{N},rate::Freq{M})
  floor(Int,ustrip(uconvert(s,time)*uconvert(Hz,rate)))
end

inHz(x::Quantity) = uconvert(Hz,x)
inHz(typ::Type{N},x) where {N <: Number} = floor(N,ustrip(inHz(x)))*Hz
inHz(typ::Type{N},x::N) where {N <: Number} = inHz(x)
function inHz(x::Number)
  warn("Unitless value, assuming Hz. Append Hz or kHz to avoid this warning",
       " (e.g. 1kHz instead of 1).",
       bt=backtrace(),once=true,key=typeof(x))
  x*Hz
end

inseconds(x::SampleQuant{N},R) where N = (ustrip(x) / R)*s
inseconds(x::Time) = uconvert(s,x)
inseconds(x::Quantity,R) = uconvert(s,x)
inseconds(x::Number,R) = inseconds(x)
inseconds(x::Quantity) = error("Expected second argument, specifying sample rate.")
function inseconds(x::Number)
  warn("Unitless value, assuming seconds. Append s, ms or samples to avoid",
       " this warning (e.g. 500ms instead of 500)",
       bt=backtrace(),once=true,key=typeof(x))
  x*s
end
