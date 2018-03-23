var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Introduction",
    "title": "Introduction",
    "category": "page",
    "text": "Sounds is a Julia package that aims to provide a clean interface for generating and manipulating sounds.To install it, you can run the following command in julia:Pkg.add(\"https://github.com/haberdashPI/Sounds.jl\")Creating sounds is generally a matter of calling a sound generation function, and then manipulating that sound with a series of |> pipes, like so:using Sounds\n\n# create a pure tone 20 dB below a power 1 signal\nsound1 = tone(1kHz,5s) |> normpower |> amplify(-20dB)\n\n# load a sound from a file, matching the power to that of sound1\nsound2 = Sound(\"mysound.wav\") |> normpower |> amplify(-20dB)\n\n# create a 1kHz sawtooth wave \nsound3 = Sound(t -> 1000t .% 1,2s) |> normpower |> amplify(-20dB)\n\n# create a 5Hz amplitude modulated noise\nsound4 = noise(2s) |> envelope(tone(5Hz,2s)) |> normpower |> amplify(-20dB)See the manual for details."
},

{
    "location": "manual/#",
    "page": "Manual",
    "title": "Manual",
    "category": "page",
    "text": "Sounds is a package that aims to provide a clean interface for generating and manipulating sounds."
},

{
    "location": "manual/#Sound-generation-1",
    "page": "Manual",
    "title": "Sound generation",
    "category": "section",
    "text": "There are four ways to create sounds: loading a file, using sound primitives, passing a function to Sound and converting an aribtrary AbstractArray into a sound."
},

{
    "location": "manual/#Loading-a-file-1",
    "page": "Manual",
    "title": "Loading a file",
    "category": "section",
    "text": "You can create sounds from files by passing a string or IO object to Sound, like so:x = Sound(\"mysound_file.wav\")"
},

{
    "location": "manual/#Sound-Primitives-1",
    "page": "Manual",
    "title": "Sound Primitives",
    "category": "section",
    "text": "There are several primitives you can use to generate simple sounds. They are tone (to create a sinusoidal tone), noise (to generate white noise), silence (for a silent period) and harmonic_complex (to create multiple pure tones with integer frequency ratios)."
},

{
    "location": "manual/#Using-Sound-1",
    "page": "Manual",
    "title": "Using Sound",
    "category": "section",
    "text": "You can pass a function and a duration to Sound to define an aribtrary sound. The function will recieve a Range of Float64 values representing the time in seconds. For example, you can create 1kHz sawtooth wave like so:x = Sound(t -> 1000t .% 1,2s)As shown above, unitful values are not employed within the fucntion (t is a range of Float64 values not Quantity{Float64} values). A few helper functions are available to simplify the use of unitful values if you want to write your own custom functions that produce sounds. They are inHz, inseconds and inframes; they make sure the inputed unitful values are in a cannoncial form of Hertz, seconds or frames, respectively. Once in this form you can use Unitful.jl\'s ustrip function to remove the units. For example, you could define a sawtooth function as follows:sawtooth(freq,length) = Sound(t -> ustrip(inHz(freq)).*t .% 1,length)All of the sound primitives defined in this package employ a similar strategy, passing some function of t to Sound."
},

{
    "location": "manual/#Using-Arrays-1",
    "page": "Manual",
    "title": "Using Arrays",
    "category": "section",
    "text": "Any aribtrary AbstractArray can be turned into a sound. You just need to specify the sampling rate the sound is represented at, like so:# creates a 1 second noise\nx = rand(44100)\nSound(x,rate=44.1kHz)"
},

{
    "location": "manual/#Sound-manipulation-1",
    "page": "Manual",
    "title": "Sound manipulation",
    "category": "section",
    "text": "Once you have created some sounds they can be combined and manipulated to generate more interesting sounds. You can filter sounds (bandpass, bandstop, lowpass, highpass and lowpass), mix them together (mix) and set an appropriate decibel level (normpower and amplify). You can also manipulate the envelope of the sound (ramp, rampon, rampoff, fadeto, dc_offset and envelope).Where appropriate, these manipulation functions employ currying.As an example of this currying, the folloiwng code creates a 1 kHz tone for 1 second inside of a noise. The noise has notch from 0.5 to 1.5 kHz. The SNR of tone to the noise is 5 dB.SNR = 5dB\nmytone = tone(1kHz,1s) |> ramp |> normpower |> amplify(-20dB + SNR)\nmynoise = noise(1s) |> bandstop(0.5kHz,1.5kHz) |> normpower |>\n  amplify(-20dB)\nscene = mix(mytone,mynoise)Equivalently, if you do not want to take advantage of function currying, you could write this without using julia\'s |> operator, as follows:SNR = 5dB\nmysound = tone(1kHz,1s)\nmysound = ramp(mysound)\nmysound = normpower(mysound)\nmysound = amplify(mysound,-20dB + SNR)\n\nmynoise = noise(1s)\nmynoise = bandstop(mynoise,0.5kHz,1.5kHz)\nmynoise = normpower(mysound)\nmynoise = amplify(mynoise,-20dB)\n\nscene = mix(mysound,mynoise)"
},

{
    "location": "manual/#Sounds-are-arrays-1",
    "page": "Manual",
    "title": "Sounds are arrays",
    "category": "section",
    "text": "Because sounds are just an AbstractArray of real numbers they can be manipulated much like any array can. The amplitudes of a sound are represented as real numbers between -1 and 1 in sequence at a sampling rate specific to the sound\'s type. Furthermore, sounds use similar semantics to AxisArrays, and so they have some additional support for indexing with time units and :left and :right channels. For instance, to get the first 5 seconds of a sound you can do the following.mytone = tone(1kHz,10s)\nmytone[0s .. 5s]To represent the end of a sound using this special unitful indexing, you can use ends. For instance, to get the last 3 seconds of mysound you can do the following.mytone[7s .. ends]In addition to the normal time units available from untiful, a frames unit has been defined, which can be safely mixed with time units, like so:mytone[0.1s .. 1000frames]We can also concatenate multiple sounds, to play them in sequence. The following creates two tones in sequence, with a 100 ms gap between them.interval = [tone(400Hz,50ms); silence(100ms); tone(400Hz * 2^(5/12),50ms)]"
},

{
    "location": "manual/#Sounds-as-plain-arrays-1",
    "page": "Manual",
    "title": "Sounds as plain arrays",
    "category": "section",
    "text": "To represent a sound as a standard array (without copying any data), you may call its Array constructor.a = Array(mysound)"
},

{
    "location": "manual/#Stereo-Sounds-1",
    "page": "Manual",
    "title": "Stereo Sounds",
    "category": "section",
    "text": "You can create stereo sounds with leftright, and reference the left and right channel using :left or :right, like so.stereo_sound = leftright(tone(1kHz,2s),tone(2kHz,2s))\nleft_channel = stereo_sound[:left]\nright_channel = stereo_sound[:right]This can be combined with the time indices to a get a part of a channel.stereo_sound = leftright(tone(1kHz,2s),tone(2kHz,2s))\nx = stereo_sound[0.5s .. 1s,:left]Stereo sounds can be safely referenced without the second index:stereo_sound[0.5s .. 1s]"
},

{
    "location": "manual/#Sound-manipulation-is-forgiving-1",
    "page": "Manual",
    "title": "Sound manipulation is forgiving",
    "category": "section",
    "text": "You can concatenate stereo and monaural sounds, and you can mix sounds of different lengths, and the \"right thing\" will happen.# the two sounds are mixed over one another\n# resutling in a single 2s sound\nx = mix(tone(1kHz,1s),tone(2kHz,2s)) \n\n# the two sounds are played one after another, in stereo.\ny = [leftright(tone(1kHz,1s),tone(2kHz,1s)); tone(3kHz,1s)]This also works for sounds of different sampling or bit rates: the sounds will first be promoted to the highest fidelity representation (highest sampling rate and highest bit rate).julia> x = noise(1s,rate=22.05kHz)\n1.0 s 64 bit floating-point mono sound\nSampled at 22050 Hz\n▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆\n\njulia> y = noise(1s,rate=44.1kHz)\n1.0 s 64 bit floating-point mono sound\nSampled at 44100 Hz\n▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆\n\njulia> [x; y]\n2.0 s 64 bit floating-point mono sound\nSampled at 44100 Hz\n▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆\n"
},

{
    "location": "manual/#Using-Sounds-1",
    "page": "Manual",
    "title": "Using Sounds",
    "category": "section",
    "text": "Once you\'ve created a sound you can use save it, or use PortAudio.jl to play it.sound1 = tone(1kHz,5s) |> normpower |> amplify(-20dB)\nsave(\"puretone.wav\",sound1)\n\nusing PortAudio\nplay(sound1)The function play is defined in Sounds and automatically initializes and closes a PortAudioStream object for you. You could equivalently call the following code.playback = PortAudioStream()\nwrite(playback,sound1)\n\n# do some other stuff....\n\n# ...before you close your julia session:\nclose(playback)"
},

{
    "location": "reference/#",
    "page": "Reference",
    "title": "Reference",
    "category": "page",
    "text": ""
},

{
    "location": "reference/#Sounds.Sound",
    "page": "Reference",
    "title": "Sounds.Sound",
    "category": "type",
    "text": "Sound(x::AbstractArray;[rate=samplerate(x)])\n\nCreates a sound object from an array.\n\nAssumes 1 is the loudest and -1 the softest. The array should be 1d for mono signals, or an array of size (N,2) for stereo sounds. If samplerate is defined for this type of array, it will be used. Otherewise the default sampling rate is used.\n\n\n\nSound(file)\n\nLoad a specified file as a Sound object.\n\n\n\nSound(fn,len;asseconds=true,rate=samplerate(),offset=0s)\n\nCreates monaural sound where fn(t) returns the amplitudes for a given Range of time points (in seconds as a Float64). The function fn(t) should return values ranging between -1 and 1 as an iterable object, and should be just as long as t.\n\nIf asseconds is false, fn(i) returns the amplitudes for a given Range of sample indices (rather than time points).\n\nIf offset is specified, return the section of the sound starting from offset (rather than starting from 0 seconds).\n\n\n\n"
},

{
    "location": "reference/#Sounds.tone",
    "page": "Reference",
    "title": "Sounds.tone",
    "category": "function",
    "text": "tone(freq,length;[rate=samplerate()],[phase=0])\n\nCreates a pure tone of the given frequency and length (in seconds).\n\n\n\n"
},

{
    "location": "reference/#Sounds.noise",
    "page": "Reference",
    "title": "Sounds.noise",
    "category": "function",
    "text": "noise(length;[rate=samplerate()],[rng=RandomDevice()])\n\nCreates a period of white noise of the given length (in seconds).\n\n\n\n"
},

{
    "location": "reference/#Sounds.silence",
    "page": "Reference",
    "title": "Sounds.silence",
    "category": "function",
    "text": "silence(length;[rate=samplerate()])\n\nCreates period of silence of the given length (in seconds).\n\n\n\n"
},

{
    "location": "reference/#Sounds.harmonic_complex",
    "page": "Reference",
    "title": "Sounds.harmonic_complex",
    "category": "function",
    "text": "harmonic_complex(f0,harmonics,amps,length,\n                 [rate=samplerate()],[phases=zeros(length(harmonics))])\n\nCreates a harmonic complex of the given length, with the specified harmonics at the given amplitudes. This implementation is somewhat superior to simply summing a number of pure tones generated using tone, because it avoids beating in the sound that may occur due floating point errors.\n\n\n\n"
},

{
    "location": "reference/#Sounds.irn",
    "page": "Reference",
    "title": "Sounds.irn",
    "category": "function",
    "text": "irn(n,freq,length;[g=1],[rate=samplerate()],[rng=Base.GLOBAL_RNG])\n\nCreates an iterated ripple y_n(t) for a noise y_0(t) according to the following formula.\n\ny_n(t) = y_n-1(t) + gy_n-1(t-1freq)\n\n\n\n"
},

{
    "location": "reference/#Sounds.inHz",
    "page": "Reference",
    "title": "Sounds.inHz",
    "category": "function",
    "text": "inHz(quantity)\n\nTranslate a particular quantity (usually a frequency) to a value in Hz.\n\nExample\n\ninHz(1.0kHz)\n\n1000.0 Hz\n\n\n\n"
},

{
    "location": "reference/#Sounds.inframes",
    "page": "Reference",
    "title": "Sounds.inframes",
    "category": "function",
    "text": "inframes(quantity,rate)\n\nTranslate the given quantity (usually a time) to a sample index, given a particualr samplerate.\n\nExample\n\ninframes(1s,44100Hz)\n\n44100\n\n\n\n"
},

{
    "location": "reference/#Sounds.inseconds",
    "page": "Reference",
    "title": "Sounds.inseconds",
    "category": "function",
    "text": "inseconds(quantity)\n\nTranslate a particular quantity (usually a time) to a value in seconds.\n\nExample\n\ninseconds(50.0ms)\n\n0.05 s\n\n\n\n"
},

{
    "location": "reference/#Sound-Construction-1",
    "page": "Reference",
    "title": "Sound Construction",
    "category": "section",
    "text": "Sound\ntone\nnoise\nsilence\nharmonic_complex\nirn\ninHz\ninframes\ninseconds"
},

{
    "location": "reference/#Sounds.samplerate",
    "page": "Reference",
    "title": "Sounds.samplerate",
    "category": "function",
    "text": "samplerate()\n\nReturn the current default sampling rate in units of Hz when constructing sounds. Also throws a warning since relying on implicit default values can be dangerous. Defaults to 44100 Hz.\n\n\n\nsamplerate(::Array)\n\nYields the same result as samplerate().\n\n\n\nsamplerate(::Sound)\n\nReport the sampling rate of the sound in units of Hz.\n\n\n\n"
},

{
    "location": "reference/#Sounds.set_default_samplerate!",
    "page": "Reference",
    "title": "Sounds.set_default_samplerate!",
    "category": "function",
    "text": "set_default_samplerate!(rate)\n\nChanges the sampling rate returned by samplerate().\n\n\n\n"
},

{
    "location": "reference/#Sounds.nchannels-Tuple{Sounds.Sound}",
    "page": "Reference",
    "title": "Sounds.nchannels",
    "category": "method",
    "text": "nchannels(sound)\n\nReturn the number of channels (1 for mono, 2 for stereo) in this sound.\n\n\n\n"
},

{
    "location": "reference/#Sounds.nframes-Tuple{Sounds.Sound}",
    "page": "Reference",
    "title": "Sounds.nframes",
    "category": "method",
    "text": "nframes(sound)\n\nReturns the number of samples in the sound.\n\nThe number of samples is not always the same as the length of the sound. Stereo sounds have a length of 2 x nframes(sound).\n\n\n\n"
},

{
    "location": "reference/#Sounds.duration",
    "page": "Reference",
    "title": "Sounds.duration",
    "category": "function",
    "text": "duration(x;rate=samplerate(x))\n\nReturns the duration of the sound.\n\nThe rate keyword is only avaiable for generic array-like objects. It is an error to pass a different rate to this function for a Sound\n\n\n\n"
},

{
    "location": "reference/#Sounds.left",
    "page": "Reference",
    "title": "Sounds.left",
    "category": "function",
    "text": "left(sound)\n\nExtract the left channel of a sound. For monaural sounds, left and right return the same value.\n\n\n\n"
},

{
    "location": "reference/#Sounds.right",
    "page": "Reference",
    "title": "Sounds.right",
    "category": "function",
    "text": "right(sound)\n\nExtract the right channel of a sound. For monaural sounds, left and right return the same value.\n\n\n\n"
},

{
    "location": "reference/#Sounds.ismono",
    "page": "Reference",
    "title": "Sounds.ismono",
    "category": "function",
    "text": "ismono(x)\n\nTrue if the sound is monaural.\n\n\n\n"
},

{
    "location": "reference/#Sounds.isstereo",
    "page": "Reference",
    "title": "Sounds.isstereo",
    "category": "function",
    "text": "isstereo\n\nTrue if the sound is stereo.\n\n\n\n"
},

{
    "location": "reference/#Sounds.asmono",
    "page": "Reference",
    "title": "Sounds.asmono",
    "category": "function",
    "text": "asmono(x)\n\nReturns a monaural version of a sound (whether it is stereo or monaural).\n\n\n\n"
},

{
    "location": "reference/#Sounds.asstereo",
    "page": "Reference",
    "title": "Sounds.asstereo",
    "category": "function",
    "text": "asstereo(x)\n\nReturns a stereo version of a sound (wether it is stereo or monaural).\n\n\n\n"
},

{
    "location": "reference/#Interface-1",
    "page": "Reference",
    "title": "Interface",
    "category": "section",
    "text": "samplerate\nset_default_samplerate!\nnchannels(::Sounds.Sound)\nnframes(::Sounds.Sound)\nduration\nleft\nright\nismono\nisstereo\nasmono\nasstereo"
},

{
    "location": "reference/#Sounds.highpass",
    "page": "Reference",
    "title": "Sounds.highpass",
    "category": "function",
    "text": "highpass([x],high,[order=5])\n\nHigh-pass filter the sound at the specified frequency.\n\nFiltering uses a butterworth filter of the given order.\n\nWith one positional argument this returns a function f(x) that calls highpass(x,high;order=order)\n\n\n\n"
},

{
    "location": "reference/#Sounds.lowpass",
    "page": "Reference",
    "title": "Sounds.lowpass",
    "category": "function",
    "text": "lowpass([x],low,[order=5])\n\nLow-pass filter the sound at the specified frequency.\n\nFiltering uses a butterworth filter of the given order.\n\nWith one positional argument this returns a function f(x) that calls lowpass(x,low;order=order)\n\n\n\n"
},

{
    "location": "reference/#Sounds.bandpass",
    "page": "Reference",
    "title": "Sounds.bandpass",
    "category": "function",
    "text": "bandpass([x],low,high;[order=5])\n\nBand-pass filter the sound at the specified frequencies.\n\nFiltering uses a butterworth filter of the given order.\n\nWith two positional arguments this returns a function f(x) that calls bandpass(x,low,hight;order=order)\n\n\n\n"
},

{
    "location": "reference/#Sounds.bandstop",
    "page": "Reference",
    "title": "Sounds.bandstop",
    "category": "function",
    "text": "bandstop([x],low,high,[order=5])\n\nBand-stop filter of the sound at the specified frequencies.\n\nFiltering uses a butterworth filter of the given order.\n\nWith two positional arguments this returns a function f(x) that calls bandstop(x,low,hight;order=order)\n\n\n\n"
},

{
    "location": "reference/#Sounds.ramp",
    "page": "Reference",
    "title": "Sounds.ramp",
    "category": "function",
    "text": "ramp([sound],[length=5ms])\n\nApplies a half cosine ramp to start and end of the sound.\n\nRamps prevent clicks at the start and end of sounds.\n\nWhen there is no sound argument, this returns a function f(x) that ramp(x,length)\n\n\n\n"
},

{
    "location": "reference/#Sounds.rampon",
    "page": "Reference",
    "title": "Sounds.rampon",
    "category": "function",
    "text": "rampon([sound],[length=5ms])\n\nApplies a half consine ramp to start of the sound.\n\nWhen passed no sound argument, this returns a function f(x) which calls rampon(x,length)\n\n\n\n"
},

{
    "location": "reference/#Sounds.rampoff",
    "page": "Reference",
    "title": "Sounds.rampoff",
    "category": "function",
    "text": "rampoff([sound],[length=5ms])\n\nApplies a half consine ramp to the end of the sound.\n\nWhen passed no sound argument, this returns a function f(x) which calls rampoff(x,length)\n\n\n\n"
},

{
    "location": "reference/#Sounds.fadeto",
    "page": "Reference",
    "title": "Sounds.fadeto",
    "category": "function",
    "text": "fadeto([a],[b],[transition=50ms])\n\nA smooth transition from a to b, overlapping the end of one with the start of the other by transition.\n\nWhen passed a single sound, a, this returns a function f(b) that calls fadeto(a,b,transition).\n\n\n\n"
},

{
    "location": "reference/#Sounds.amplify",
    "page": "Reference",
    "title": "Sounds.amplify",
    "category": "function",
    "text": "amplify([x],ratio)\n\nAmplify (positive) or attenuate (negative) the sound by a given ratio, typically specified in decibels (e.g. amplify(x,10dB)).\n\nNote: you can also directly multiply by a factor, e.g. x * 10dB, which has the same effect as this function.\n\nWith one positional argument, ratio, this returns a function f(x) which calls amplify(x,ratio).\n\n\n\n"
},

{
    "location": "reference/#Sounds.normpower",
    "page": "Reference",
    "title": "Sounds.normpower",
    "category": "function",
    "text": "normpower(x)\n\nNormalize the sound so it has a power of 1.\n\n\n\n"
},

{
    "location": "reference/#Sounds.mix",
    "page": "Reference",
    "title": "Sounds.mix",
    "category": "function",
    "text": "mix(x,...)\n\nAdd several sounds together so that they play at the same time.\n\nUnlike normal addition, this acts as if each sound is padded with zeros at the end so that the lengths of all sounds match.\n\nWith one argument x, this returns a function f(y) that calls mix(x,y)\n\n\n\n"
},

{
    "location": "reference/#Sounds.envelope",
    "page": "Reference",
    "title": "Sounds.envelope",
    "category": "function",
    "text": "envelope([x],y)\n\nMutliply several sounds together. Typically used to apply an amplitude envelope x to sound y.\n\nUnlike normal multiplication, this acts as if each sound is padded with ones at the end so that the lengths of all sounds match.\n\nWith one argument x, this returns a function f(y) that calls envelope(x,y)\n\n\n\n"
},

{
    "location": "reference/#Sounds.dc_offset",
    "page": "Reference",
    "title": "Sounds.dc_offset",
    "category": "function",
    "text": "dc_offset(length;[rate=44100Hz])\n\nCreates a DC offset of unit value.\n\nIn other words, this just returns samples all with the value 1: silence is to zeros just as dc_offset is to ones.\n\nThough this technically constructs a sound it is normally only used in combination with envelope, because it produces no audible sound. For example, it could be used to transition from a unmodulated to an amplitude modulated noise:\n\nenv = dc_offset(2s) |> fadeto(tone(8Hz,2s)) |> ramp(250ms)\nsound = noise(duration(env)) |> envelope(env) |> normpower\n\n\n\n"
},

{
    "location": "reference/#Sounds.leftright",
    "page": "Reference",
    "title": "Sounds.leftright",
    "category": "function",
    "text": "leftright(left,right)\n\nCreate a stereo sound from two monaural sounds.\n\n\n\n"
},

{
    "location": "reference/#DSP.Filters.resample-Tuple{Sounds.Sound,Unitful.Quantity}",
    "page": "Reference",
    "title": "DSP.Filters.resample",
    "category": "method",
    "text": "resample(x::Sound,new_rate;warn=true)\n\nReturns a new sound representing x at the given sampling rate (in Hertz).\n\nIf you reduce the sampling rate, you will loose all frequencies in x that are above new_rate/2. Reducing the sampling rate will produce a warning unless warn is false.\n\n\n\n"
},

{
    "location": "reference/#Sound-Manipulation-1",
    "page": "Reference",
    "title": "Sound Manipulation",
    "category": "section",
    "text": "highpass\nlowpass\nbandpass\nbandstop\nramp\nrampon\nrampoff\nfadeto\namplify\nnormpower\nmix\nenvelope\ndc_offset\nleftright\nDSP.Filters.resample(::Sounds.Sound,::Quantity)"
},

]}
