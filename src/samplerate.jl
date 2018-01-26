import SampledSignals: samplerate

const default_sample_rate = fill(44100.0Hz)

"""
    samplerate()

Return the current default sampling rate in units of Hz when construction
sounds. Also throws a warning to avoid pitfalls with using a global
value. Defaults to 44100 Hz.
"""
function samplerate()
  warn("Using default sample rate of $(default_sample_rate[])")
  default_sample_rate[]
end

"""
    samplerate(::Array)

Yields the same result as `samplerate()`.
"""
samplerate(x::Array) = samplerate()

"""
    samplerate(::AxisArray)

Assuming there is a `:time` axis for this axis array with regular interval
time samples, returns the sampling rate of the signal in units of Hz.
"""
samplerate(x::AxisArray) = samplerate_r(axis(x,Axis{:time}))
samplerate_r(x::Range) = 1/step(x) * Hz
samplerate_r(x) =
  error("AxisArray must be defined by a range for the samplerate to be defined.")


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
