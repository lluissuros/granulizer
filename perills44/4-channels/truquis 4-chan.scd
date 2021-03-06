/*Pan4*/

//Helium background : https://www.youtube.com/watch?v=TBMU_OewAbQ

(
//init synths and patterns
SynthDef( \sine, { |out=0,freq=440,amp=1,dur=0.3, atk=0.05, rel=1|

	var sig = SinOsc.ar( freq, mul: (0.5));
	var env = EnvGen.kr( Env.perc(atk,rel), timeScale: dur, doneAction:2);
	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;

~geom1 = Array.geom(2000,0.5,0.995).mirror;
~geom2_scr = Array.geom(2000,0.125,0.995).scramble;
)






//--------------------------------------------------------
//-------------------------Play---------------------------
//--------------------------------------------------------
Scale.directory



(
Pbindef(\sinMulti,
	\instrument, \sine,
	\scale, Scale.kumoi.tuning_(\just),
	\octave, Pseq([5],inf),
	\degree, Pn(Pshuf([0 ,3, 5, 6, 7],8),inf),
	\out, Pseq([0,1,2,3]+2,inf),
	\dur, Pseq(~geom1, 1),
);
)

Pbindef(\sinMulti).play
Pbindef(\sinMulti).stop





Pbindef(\sinMulti, \scale, Scale.kumoi.tuning_(\just))
Pbindef(\sinMulti, \scale, Scale.spanish.tuning_(\just))
Pbindef(\sinMulti, \scale, Scale.nikriz.tuning_(\just))
Pbindef(\sinMulti, \scale, Scale.purvi.tuning_(\just))
Pbindef(\sinMulti, \degree, Pn(Pshuf([0 ,3, 5, 6, 7,\rest, \rest]-1, 32),inf))
Pbindef(\sinMulti, \dur,  Pn(Pseq(~geom1.at((400..700).mirror), 1),inf))
Pbindef(\sinMulti, \dur,  Pseq(~geom1, 1))
Pbindef(\sinMulti, \dur,  Pseq([0.3],inf))



Pbindef(\sinMulti, \octave, Pn(Pshuf([2,5,4,3],16),inf))
Pbindef(\sinMulti, \octave, Pn(Pshuf([1,2,1],16),inf))
Pbindef(\sinMulti, \octave, Pn(Pshuf([1,3,3],16),inf))
Pbindef(\sinMulti, \out, Pseq([0,1,2]+2,inf)) //only the vibs
Pbindef(\sinMulti, \octave, Pseq([2,3,4,5,6],inf))
Pbindef(\sinMulti, \amp, Pseq([1,0.5, 0.75]/2, inf))

