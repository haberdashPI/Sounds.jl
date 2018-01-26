module Sounds

using Lazy: @>>, @>, @_
using Unitful
import AxisArrays: AxisArray
import SampledSignals: SampleBuf

export @>>, @>, @_

include(joinpath(@__DIR__,"units.jl"))
include(joinpath(@__DIR__,"sound.jl"))
include(joinpath(@__DIR__,"samplerate.jl"))
include(joinpath(@__DIR__,"audible.jl"))

const localunits = Unitful.basefactors
const localpromotion = Unitful.promotion
function __init__()
  merge!(Unitful.basefactors,localunits)
  merge!(Unitful.promotion, localpromotion)
end

end
