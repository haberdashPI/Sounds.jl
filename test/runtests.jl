using Sounds
using AxisArrays
using SampledSignals
using Base.Test

x = leftright(ramp(tone(1kHz,1s)),ramp(tone(1kHz,1s)))
rng() = MersenneTwister(1983)

show_str = "1.0 s 64 bit floating-point stereo sound
Sampled at 44100 Hz
▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆
▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆"


@testset "Sound Indexing" begin
  @test isapprox(duration(x[0s .. 0.5s,:]),0.5s; atol = 2/samplerate(x))
  @test isapprox(duration(x[0.5s .. ends,:]),0.5s; atol = 2/samplerate(x))

  @test x[:left][:right] == x[:left][:left]
  @test nsamples(x[1,:]) == 1
  @test ismono(x[0s .. 0.5s,:left])
  @test isstereo(x[0s .. 0.5s])
  @test x[:left][0s .. 0.5s] == x[0s .. 0.5s,:left]
  @test x[:right][0s .. 0.5s] == x[0s .. 0.5s,:right]
  @test x[:,:left][0s .. 0.5s] == x[0s .. 0.5s,:left]
  @test x[:,:left] == x[:,:right]
  @test x[0.5s .. 0.75s] == x[0.5s .. 0.75s,:]
  @test x[0.5s .. ends] == x[0.5s .. ends,:]
  mylen = nsamples(x[0.1s .. 0.6s])
  newx = copy(x)
  @test (newx[0.1s .. 0.6s] = x[50:(50+mylen-1),:]) == x[50:(50+mylen-1),:]
  @test (newx[0.1s .. 0.6s,:] = x[50:(50+mylen-1),:]) == x[50:(50+mylen-1),:]
  myend = (0.1s + duration(x[0.5s .. ends]))
  @test (newx[0.5s .. ends] = x[0.1s .. myend]) == x[0.1s .. myend]
  @test (newx[0.5s .. ends,:] = x[0.1s .. myend,:]) == x[0.1s .. myend,:]
  @test (newx[0.1s .. 0.6s,:] = x[0.2s .. 0.700005s,:]) == x[0.2s .. 0.700005s,:]

  @test x[0s .. 22050samples,:] == x[0s .. 0.5s,:]
  @test x[22050samples .. 44100samples,:] == x[0.5s .. 1s,:]
  @test x[22050samples .. 1s,:] == x[0.5s .. 1s,:]
  @test x[22050samples .. ends,:] == x[0.5s .. ends,:]
  @test x[0.5s .. 1s,:] == (x[0s .. 22050samples,:] = x[0.5s .. 1s,:])
  @test x[0.5s .. ends,:] == (x[22050samples .. ends,:] = x[0.5s .. ends,:])

  @test x[22050samples .. 44100samples] == x[0.5s .. 1s]
  @test x[22050samples .. 1s] == x[0.5s .. 1s]
  @test x[22050samples .. ends] == x[0.5s .. ends]
  @test x[0.5s .. 1s] == (x[0s .. 22050samples] = x[0.5s .. 1s])
  @test x[0.5s .. ends] == (x[22050samples .. ends] = x[0.5s .. ends])

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

  @test nsamples(x[0s .. 0.5s,:]) + nsamples(x[0.5s .. ends,:]) == nsamples(x)
  strbuff = IOBuffer()
  show(strbuff,x)
  @test show_str == String(strbuff)
end

@inline same(x,y) = isapprox(x,y,rtol=1e-6)

@testset "Sound Construction" begin
  @test samplerate([Sound(zeros(10)); Sound(zeros(10);rate=22050Hz)]) ==
    44100Hz
  @test nchannels([silence(200samples);x]) == 2
  @test eltype(Sound(t -> zeros(t),200samples)) == Float64
  @test eltype([Sound(zeros(Float32,200)); silence(200samples)]) ==
    Float64
  @test nsamples(tone(1kHz,1s)) ==
    ustrip(samplerate(tone(1kHz,1s)))
  @test nsamples(leftright(tone(1kHz,1s),tone(1kHz,1s))) ==
    ustrip(samplerate(tone(1kHz,1s)))
  @test nsamples(ramp(tone(1kHz,1s))) == nsamples(tone(1kHz,1s))
  @test [x[0s .. 0.5s]; x[0.5s .. ends]] == x
  @test [x[0s .. 0.5s]; x[0.5s .. ends,:left]] == x
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
  @test_throws ErrorException ramp(tone(1kHz,50ms),100ms)
  @test_throws AssertionError Sound(t -> fill(0,size(t)),10ms)
  @test same(Sound("sounds/rampon.wav"),rampon(tone(1kHz,1s)))
  @test same(Sound("sounds/rampoff.wav"),rampoff(tone(1kHz,1s)))
  @test same(Sound("sounds/fadeto.wav"),
             fadeto(tone(1kHz,0.5s),tone(2kHz,0.5s)))
  @test fadeto(leftright(tone(1kHz,100ms),tone(1.5kHz,100ms)),
               tone(2kHz,100ms)) != 0
  @test same(Sound("sounds/noise.wav"),noise(1s,rng=rng()))
  @test same(Sound("sounds/bandpass.wav"),
             @> noise(1s,rng=rng()) bandpass(400Hz,800Hz))
  @test same(Sound("sounds/complex.wav"),
             @>(harmonic_complex(200Hz,0:5,ones(6),1s),normalize,amplify(-20)))
end

@testset "Sound Interop" begin
  @test AxisArray(x)[Axis{:channel}(:left)] == x[:left]
  @test samplerate(AxisArray(x)) == 44100Hz
  @test SampleBuf(x) == x
  @test samplerate(SampleBuf(x)) == 44100.0
  @test samplerate(Sound(AxisArray(linspace(0,1,100),
                                   Axis{:time}(linspace(0,1,100)*s)))) == 98Hz
end

# TODO: add tests for interop with SampleBuf and AxisArray.
