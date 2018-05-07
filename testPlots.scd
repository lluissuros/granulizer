//imagine cicyle = 1s

(
//45.degrad
var maxPhase = 180;
var items = 3;
var

a = {[
	SinOsc.ar(1, 0.degrad).abs,
	SinOsc.ar(1, 60.degrad).abs,
	SinOsc.ar(1, 120.degrad).abs
]}.plot(1);
a.superpose = true;
a.refresh;

)

[1,2,3,4,4,5,5,5,5][0..1]

//sineFill (size, amplitudes, phases)
Wavetable.sineFill(512, 1.0/[1]).asArray[0..513].plot;
// take different points as phase, for example:
Wavetable.sineFill(512, 1.0/[1]).asArray.select({|el| el>0}).plot

(
var sine = Wavetable.sineFill(512, 1.0/[1]).asArray[0..800].abs.plot;
var soundsFake = ['a','a2','4a','kjfgha'];
var numOfSounds = soundsFake.size;
var phase = (sine.size/numOfSounds).floor;

var testProb = soundsFake.collect({ |el, i|
	sine.at(i*phase).abs.postln;
});

var soundToPlay = soundsFake.wchoose(testProb.normalizeSum);

	"probs : " .postln;
	testProb.do {|prob|
		prob.postln;
	};

"".postln;
"soundToPlay".postln;
soundToPlay.postln;

)

Env.new([0.001, 0.001, 1, 1, 0.001], [0.25, 0.25, 0.25, 0.25], '\exp' ).asSignal.asArray.plot;
[1,2,3,2,1].plot


//"https://composerprogrammer.com/teaching/supercollider/sctutorial/9.1 Algorithmic Strategies.html"

gauss(0.0,1.0) //famous bell-shaped Gaussian, normal distribution; has two parameters, mean and standard deviation. Most output values are within three standard deviations each side of the mean
Array.fill(1000,{gauss(0.0,1.0)}).sort.plot //see this visually

gauss(1.0,0.1) //mean 1.0, most output values within 0.3 (3*0.1) either side, so 0.7 to 1.3

[1,2,3,4].normalizeSum.sum
[60,62,64,67].wchoose([0.5, 0.25, 0.2, 0.05]) //the first array is the array of options; the second is the array of weights

Env.sine(1, 1).plot;

(
{
e = Env.sine(10, 1).asStream;
inf.do({
    e.next.postln;
    0.01.wait;
})}.fork
)


