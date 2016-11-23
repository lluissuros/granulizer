(
SynthDef( \nicepoc, { |out=0,freq=440,amp=0.0125,dur=0.3|
		Out.ar( out, SinOsc.ar( freq, mul: amp )*EnvGen.kr( Env.perc(0.05,1), timeScale: dur, doneAction:2))
}).add;
)





(
p = Pbind(
     \degree, Pseq([0 ,3, 5, 6, 7],inf),
	\out, Pseq([0,1,2,3],80),
	\dur, Pgeom(0.5,0.95,100),
     \instrument, \nicepoc
).play;
)

(
p = Pbind(
     \degree, Pshuf([0 ,3, 5, 6, 7],inf),
	\out, Pseq([0,1,2,3],80),
	\dur, Pgeom(0.5,0.95,100),
     \instrument, \nicepoc
).play;
)

(
p = Pbind(
     \degree, Pseq([0 ,3, 5, 6, 7],inf),
	\octave, Pseq([2,3,4,5,6],inf),
	\out, Pseq([0,1,2,3],80),
	\dur, Pgeom(0.5,0.95,200),
     \instrument, \nicepoc
).play;
)

(
p = Pbind(
     \degree, Pshuf([0 ,3, 5, 6, 7],inf),
	\octave, Pshuf([9,8,7,6,5,4,3,2,1],inf),
	\out, Pseq([0,1,2,3],80),
	\dur, Pgeom(0.5,0.95,200),
     \instrument, \nicepoc
).play;
)