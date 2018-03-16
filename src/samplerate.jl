@require SampledSignals begin
  import SampledSignals: samplerate, nchannels
end

const default_sample_rate = fill(44100.0Hz)

"""
    samplerate()

Return the current default sampling rate in units of Hz when constructing
sounds. Also throws a warning since relying on implicit default values can be
dangerous. Defaults to 44100 Hz.

"""
function samplerate()
  warn("Using default sample rate of $(default_sample_rate[])",
       once=true,key=object_id(default_sample_rate[]),
       bt=backtrace())
  default_sample_rate[]
end

"""
    samplerate(::Array)

Yields the same result as `samplerate()`.
"""
samplerate(x::Array) = samplerate()

@require AxisArrays begin
  using AxisArrays
  """
        samplerate(::AxisArray)

    Assuming there is a `:time` axis for this axis array with regular interval
    time samples, returns the sampling rate of the signal in units of Hz.
    """
  samplerate(x::AxisArray) = samplerate_r(axisvalues(axes(x,Axis{:time}))[1])
  samplerate_r(x::Range) = 1/step(x)
  samplerate_r(x) =
    error("The `:time` axis must be defined by a `Range` for the samplerate to "*
          "be well defined.")
end

"""
    samplerate(::Sound)

Report the sampling rate of the sound in units of Hz.
"""
samplerate{R}(x::Sound{R}) = R*Hz

"""
    set_default_samplerate!(rate)

Changes the sampling rate returned by `samplerate()`.
"""
set_default_samplerate!(rate) = default_sample_rate[] = inHz(rate)
