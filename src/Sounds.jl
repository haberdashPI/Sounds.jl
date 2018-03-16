module Sounds

using Unitful
using Requires

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

@require PortAudio begin
  import PortAudio
  import SampledSignals
  export play

  const portaudio = PortAudio.PortAudioStream()
  Base.write(io::PortAudio.PortAudioStream,x::Sound) =
    write(io,SampledSignals.SampleBuf(x))
  play(x::Sound) = write(portaudio,x)
  atexit() do
    sleep(0.1)
    close(portaudio)
  end
end

end
