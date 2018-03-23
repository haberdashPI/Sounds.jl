using Sounds
using Base.Test

x = leftright(tone(1kHz,1s) |> ramp,tone(1kHz,1s) |> ramp)
rng() = MersenneTwister(1983)
atfreq(spect,freq) =
  spect[end - floor(Int,(end>>1) * freq / (samplerate()/2))]


show_str = "1.0 s Float64 stereo sound
Sampled at 44100 Hz
▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆
▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆"

mono_x = asmono(x)

@testset "Unit Conversions" begin
  @test_throws ErrorException inframes(0.5frames,samplerate())
  @test inframes(1s,44.1kHz) == 44100
  @test inseconds(50ms) == s*1//20
  @test inseconds(1s,samplerate()) == 1s
  @test_throws ErrorException inseconds(2frames)
end

@testset "Sound Indexing" begin
  @test isapprox(duration(x[0s .. 0.5s,:]),0.5s; atol = 2/samplerate(x))
  @test isapprox(duration(x[0.5s .. ends,:]),0.5s; atol = 2/samplerate(x))

  @test_throws ErrorException 5Hz .. ends
  @test x[:left][:right] == x[:left][:left]
  @test (mono_x[0s .. 0.5s] = 0) == 0
  @test all((mono_x[:left] = mono_x[:right]) .== mono_x)
  @test all((mono_x[:right] = mono_x[:left]) .== mono_x)
  @test left(x) == x[:left]
  @test right(x) == x[:right]
  @test nframes(x[1,:]) == 1
  @test nframes(x[:left][1,:]) == 1
  @test ismono(x[0s .. 0.5s,:left])
  @test isstereo(x[0s .. 0.5s])
  @test x[:left][0s .. 0.5s] == x[0s .. 0.5s,:left]
  @test x[:right][0s .. 0.5s] == x[0s .. 0.5s,:right]
  @test x[:,:left][0s .. 0.5s] == x[0s .. 0.5s,:left]
  @test x[:,:left] == x[:,:right]
  @test x[0.5s .. 0.75s] == x[0.5s .. 0.75s,:]
  @test x[0.5s .. ends] == x[0.5s .. ends,:]
  mylen = nframes(x[0.1s .. 0.6s])
  newx = copy(x)
  @test (x[:,:left] = x[:,:right]) == x[:,:left]
  @test (x[:,:right] = x[:,:left]) == x[:,:right]
  @test (newx[0.1s .. 0.6s] = x[50:(50+mylen-1),:]) == x[50:(50+mylen-1),:]
  @test (newx[0.1s .. 0.6s,:] = x[50:(50+mylen-1),:]) == x[50:(50+mylen-1),:]
  myend = (0.1s + duration(x[0.5s .. ends]))
  @test (newx[0.5s .. ends] = x[0.1s .. myend]) == x[0.1s .. myend]
  @test (newx[0.5s .. ends,:] = x[0.1s .. myend,:]) == x[0.1s .. myend,:]
  @test (newx[0.1s .. 0.6s,:] = x[0.2s .. 0.700005s,:]) ==
    x[0.2s .. 0.700005s,:]

  @test x[0s .. 22050frames,:] == x[0s .. 0.5s,:]
  @test x[22050frames .. 44100frames,:] == x[0.5s .. 1s,:]
  @test x[22050frames .. 1s,:] == x[0.5s .. 1s,:]
  @test x[22050frames .. ends,:] == x[0.5s .. ends,:]
  @test x[0.5s .. 1s,:] == (x[0s .. 22050frames,:] = x[0.5s .. 1s,:])
  @test x[0.5s .. ends,:] == (x[22050frames .. ends,:] = x[0.5s .. ends,:])

  @test x[22050frames .. 44100frames] == x[0.5s .. 1s]
  @test x[22050frames .. 1s] == x[0.5s .. 1s]
  @test x[22050frames .. ends] == x[0.5s .. ends]
  @test x[0.5s .. 1s] == (x[0s .. 22050frames] = x[0.5s .. 1s])
  @test x[0.5s .. ends] == (x[22050frames .. ends] = x[0.5s .. ends])

  @test_throws BoundsError x[0.5s .. 2s,:]
  @test_throws BoundsError x[-0.5s .. 0.5s,:]
  @test_throws BoundsError x[-0.5s .. ends,:]
  @test_throws BoundsError x[:,:doodle]
  @test_throws BoundsError x[0.5s .. 2s]
  @test_throws BoundsError x[-0.5s .. 0.5s]
  @test_throws BoundsError x[-0.5s .. ends]
  @test_throws BoundsError x[0.5s .. 2s,:] = 1:10
  @test_throws BoundsError x[-0.5s .. 0.5s,:] = 1:10
  @test_throws BoundsError x[-0.5s .. ends,:] = 1:10
  @test_throws BoundsError x[:,:doodle] = 1:10
  @test_throws BoundsError x[0.5s .. 2s] = 1:10
  @test_throws BoundsError x[-0.5s .. 0.5s] = 1:10
  @test_throws BoundsError x[-0.5s .. ends] = 1:10
  @test_throws DimensionMismatch x[0.5s .. 0.6s,:] = 1:10
  @test_throws DimensionMismatch x[0.2s .. 0.5s,:] = 1:10
  @test_throws DimensionMismatch x[0.2s .. ends,:] = 1:10
  @test_throws DimensionMismatch x[0.5s .. 0.6s] = 1:10
  @test_throws DimensionMismatch x[0.5s .. 0.6s] = 1:10
  @test_throws DimensionMismatch x[0.5s .. ends] = 1:10

  @test nframes(x[0s .. 0.5s,:]) + nframes(x[0.5s .. ends,:]) == nframes(x)
  strbuff = IOBuffer()
  show(strbuff,x)
  @test show_str == String(strbuff)
end

@testset "Sampling Rate Setup" begin
  set_default_samplerate!(1kHz)
  @test_warn "Using default sample rate" samplerate()
  @test samplerate() == 1kHz
  set_default_samplerate!(44.1kHz)
  @test samplerate() == 44.1kHz
end

@inline same(x,y) = isapprox(x,y,rtol=1e-6)

@testset "Sound Conversion" begin
  @test Sound(x) === x
  @test Sound(x,rate=22.1kHz) !== x
  @test Sound(Array(x)) == x
  @test all(Array(asmono(x)) .== asmono(x))
  @test ismono(convert(Sound{44100,Float64,1,1},x))
  @test ismono(convert(Sound{44100,Float64,1,1},asmono(x)[:,:]))
  @test_throws ErrorException convert(Sound{44100,Float64,1,3},x)
  @test_warn "reduced the sample rate" resample(x,22.05kHz)
  @test resample(x,samplerate(x)) === x
  @test duration(Array(x)) == duration(x)
  @test asstereo(x) === x
  @test asmono(mono_x) === mono_x
end

@testset "Function Currying" begin
  @test isa(mix(x),Function)
  @test isa(envelope(x),Function)
  @test isa(bandpass(200Hz,400Hz),Function)
  @test isa(lowpass(200Hz),Function)
  @test isa(highpass(200Hz),Function)
  @test isa(ramp(10ms),Function)
  @test isa(rampon(10ms),Function)
  @test isa(rampoff(10ms),Function)
  @test isa(fadeto(x),Function)
  @test isa(amplify(20dB),Function)
end

@testset "Sound Construction" begin
  @test isa(leftright(x[:left],resample(x[:right],22.05kHz)),Sound)
  @test samplerate(mix(Sound(zeros(10)),Sound(zeros(10);rate=22050Hz))) ==
    44100Hz
  @test samplerate(envelope(Sound(zeros(10)),Sound(zeros(10);rate=22050Hz))) ==
    44100Hz
  @test samplerate([Sound(zeros(10)); Sound(zeros(10);rate=22050Hz)]) ==
    44100Hz
  @test nchannels([silence(200frames);x]) == 2
  @test eltype(Sound(t -> zeros(length(t)),200frames)) == Float64
  @test eltype([Sound(zeros(Float32,200)); silence(200frames)]) ==
    Float64
  @test nframes(tone(1kHz,1s)) ==
    ustrip(samplerate(tone(1kHz,1s)))
  @test nframes(leftright(tone(1kHz,1s),tone(1kHz,1s))) ==
    ustrip(samplerate(tone(1kHz,1s)))
  @test nframes(ramp(tone(1kHz,1s))) == nframes(tone(1kHz,1s))
  @test [x[0s .. 0.5s]; x[0.5s .. ends]] == x
  @test [x[0s .. 0.5s]; x[0.5s .. ends,:left]] == x
  @test all(dc_offset(1s) .== 1)
  @test same(Sound("sounds/tone.wav"),x)
  @test same(Sound("sounds/two_tone.wav"),
             [tone(1kHz,100ms);silence(800ms);tone(1kHz,100ms)])
  a,b = tone(1kHz,200ms),tone(2kHz,200ms)
  @test [Sound(zeros(10)); Sound(zeros(Float32,10))[:,:]] ==
           [Sound(zeros(10,1)); Sound(zeros(10,1))]
  @test leftright(a,b)[:,:left] == a
  @test leftright(a,b)[:,:right] == b
  @test size([tone(1kHz,0.2s); tone(2kHz,0.2s)],2) == 1
  @test [tone(1kHz,0.2s); leftright(tone(1.5kHz,0.2s),tone(0.5kHz,0.2s))] ==
    [leftright(tone(1kHz,0.2s),   tone(1kHz,0.2s));
     leftright(tone(1.5kHz,0.2s), tone(0.5kHz,0.2s))]
  @test_throws ErrorException tone(1kHz,50ms) |> ramp(100ms)
  @test_throws ErrorException tone(1kHz,50ms) |> rampon(100ms)
  @test_throws ErrorException tone(1kHz,50ms) |> rampoff(100ms)

  @test_throws AssertionError Sound(t -> fill(0,size(t)),10ms)

  bandstop_freq = noise(1s) |> bandstop(0.5kHz,1.5kHz) |> fft
  @test abs(atfreq(bandstop_freq,250Hz)) > abs(atfreq(bandstop_freq,1kHz))

  bandpass_freq = noise(1s) |> bandpass(0.5kHz,1.5kHz) |> fft
  @test abs(atfreq(bandpass_freq,250Hz)) < abs(atfreq(bandpass_freq,1kHz))

  lowpass_freq = noise(1s) |> lowpass(0.5kHz) |> fft
  @test abs(atfreq(lowpass_freq,250Hz)) > abs(atfreq(lowpass_freq,1kHz))

  highpass_freq = noise(1s) |> highpass(0.5kHz) |> fft
  @test abs(atfreq(highpass_freq,250Hz)) < abs(atfreq(highpass_freq,1kHz))

  @test all(0.5x .≈ x/2)

  # NOTE: these wav files were vetted: I examined them in Audacity to ensure
  # these calls resulted in appropriate output, visually, according to time
  # frequency and time amplitude plots. Small changes to implementation may
  # require that the sounds be regenerated, at which point the new version
  # should be visually inspected to ensure that the output is reasoanble.
  @test same(Sound("sounds/rampon.wav"),tone(1kHz,1s) |> rampon)
  @test same(Sound("sounds/rampoff.wav"),tone(1kHz,1s) |> rampoff)
  @test same(Sound("sounds/fadeto.wav"),
             tone(1kHz,0.5s) |> fadeto(tone(2kHz,0.5s)))
  @test fadeto(leftright(tone(1kHz,100ms),tone(1.5kHz,100ms)),
               tone(2kHz,100ms)) != 0
  @test same(Sound("sounds/noise.wav"),noise(1s,rng=rng()))
  @test same(Sound("sounds/bandpass.wav"),
             noise(1s,rng=rng()) |> bandpass(400Hz,800Hz))
  @test same(Sound("sounds/complex.wav"),
             harmonic_complex(200Hz,0:5,ones(6),1s) |> normpower |>
             amplify(-20dB))
  normed = collect(1:10) |> normpower
  @test sqrt(mean(normed.^2)) ≈ 1
end

# tests conditional on presence of AxisArray and/or SampledSignals
# @testset "Sound Interop" begin
#   @test AxisArray(x)[Axis{:channel}(:left)] == x[:left]
#   @test samplerate(AxisArray(x)) == 44100Hz
#   @test SampleBuf(x) == x
#   @test samplerate(SampleBuf(x)) == 44100.0
#   @test samplerate(Sound(AxisArray(linspace(0,1,100),
#                                    Axis{:time}(linspace(0,1,100)*s)))) == 98Hz
# end
