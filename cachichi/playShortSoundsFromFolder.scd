/*
 Please run the functions on playAllSoundFromFolder.scd
DON'T PUT LONG SAMPLES IN HERE
*/


(
//reference only the short sounds
~shortSounds =  Dictionary.new;
~shortSounds[\birds] = ~soundsFoldered[\birds];
~shortSounds[\vowels1] = ~soundsFoldered[\vowels1];
~shortSounds[\vowels2] = ~soundsFoldered[\vowels2];
~shortSounds[\vowels3] = ~soundsFoldered[\vowels3];
)

~shortSounds.keys

(
//do not change to other libraries!!
Pbindef(\birdsSuperDanger,
	\instrument, \simpleBufPlayer,
	\buf, Pfunc({~getRandBuf.([\birds, \vowels3].choose)}).stutter(1),
	\dur, Pn(Pshuf([3,5,7,5,10]/100,100), inf),
	\release, 1,
	\attack, 3,
	\sustain,5,
	\amp, Pxrand([0.3,0.5,0.7]*0.25,inf),
//	\out, Pn(Pshuf([0,1,2,3,4,5,6,7], 100), inf),
	\out, Pn(Pshuf([0,1], 100), inf),
//	\out, Prand([~buses[\infiniteReverbVib], ~buses[\infiniteReverbSurr] ], inf),
	\pan, Pseq(Array.series(21, -1, 0.1) ,inf),
	\panwidth, 1,
//	\rate, Pseq([0].midiratio, inf),
    \rate, Pseq([0.5,1 ,0.25, 0.125]/1, inf),
	\degree, Pseq([0 ,3, 5, 6, 7]-2,inf),
	\octave, Pseq([2,3,4,5,6,7,8,9,10],inf)
);
)



Pbindef(\birdsSuperDanger).play;
Pbindef(\birdsSuperDanger).stop;