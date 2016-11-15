
/*"http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/quot-exception-in-real-time-alloc-failed-quot-td5920409.html"*/
(
s = Server.internal;
s.boot;
o = Server.internal.options;
o.memSize = 2 ** 19;
p = ProxySpace.push(s);
p.fadeTime = 5;
)


//this is IMPORTANT
(
s= Server.local;
s.options.numOutputBusChannels = 4;
s.boot;
)

//TEST

	SynthDef( \nicepoc, { |out=0,freq=440,amp=0.1,dur=0.3|
		Out.ar( out, SinOsc.ar( freq, mul: amp )*EnvGen.kr( Env.perc(0.05,1), timeScale: dur, doneAction:2 ) )
	}).add;
// multiple mono:
// the melody gets played on both channels, the second note in the pattern differs,
// so when listening to it, the space "spreads" out
(
p = Pbind(
     \degree, Pseq([0 ,3, 5, 6, 7],inf),
	\out, Pseq([0,1,2,3],4),
     \dur, 0.1,
     \instrument, \nicepoc
).play;
)


//TEST2
(
SynthDef("help-Pan4", {
    Out.ar(0, Pan4.ar(PinkNoise.ar, FSinOsc.kr(2), FSinOsc.kr(1.2), 0.3))
}).play;
)

play({ Pan4.ar(PinkNoise.ar, -1,  0, 0.3) }); // left pair
play({ Pan4.ar(PinkNoise.ar,  1,  0, 0.3) }); // right pair
play({ Pan4.ar(PinkNoise.ar,  0, -1, 0.3) }); // back pair
play({ Pan4.ar(PinkNoise.ar,  0,  1, 0.3) }); // front pair

play({ Pan4.ar(PinkNoise.ar,  0,  0, 0.3) }); // center