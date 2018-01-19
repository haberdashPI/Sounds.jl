module Sounds

using Lazy: @>>, @>, @_
using Unitful
using SampledSignals
using AxisArrays

export @>>, @>, @_

include(joinpath(@__DIR__,"units.jl"))
include(joinpath(@__DIR__,"samplerate.jl"))
include(joinpath(@__DIR__,"sound.jl"))
include(joinpath(@__DIR__,"audio.jl"))

const localunits = Unitful.basefactors
const localpromotion = Unitful.promotion
function __init__()
  merge!(Unitful.basefactors,localunits)
  merge!(Unitful.promotion, localpromotion)
end

end
