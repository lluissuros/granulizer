/*
Synth that generates sound at a given freq, by substraction, filtering the noise with a moving Q.
Need to keep rq above zero or you'll fuck your ears up.
*/

/*
(
s= Server.local;
s.options.numOutputBusChannels = 6;
s.boot;
)
*/

(
SynthDef(\substractionMovingQ5chan, {
		|out=0, freq=1100, amp=0.5, attack=1, sustain=3, release=9, pan=0, panwidth=2, numChans=4, revMix=0.2|
		var env, sig, compSig, drySig, wetSig, rq;


		//keep total rq above zero!
		var factor =  (10/freq) ;
	//freq.poll(Impulse.kr(5));

		//TODO: Check XFade2 for equal power cross fade between two inputs
		//TODO better: this is what I'm doing: { Resonz.ar(WhiteNoise.ar(0.5), 2000, XLine.kr(1, 0.001, 8)) }.play

		rq = factor * XLine.kr(100,1,release) + LFNoise1.kr(0.1,factor,factor);
		env = EnvGen.kr(Env.linen(attack, sustain, release),doneAction:2);
		//env = EnvGen.kr(Env.perc(release, attack),doneAction:2); //reverse
		sig = BPF.ar( WhiteNoise.ar, freq, rq);
		compSig =   Compander.ar(sig, sig, thresh: 0.1,slopeBelow: 1, slopeAbove: 0.15, clampTime: 0.01, relaxTime: 0.01,mul:1.5);
		compSig = sig * env;

		drySig = compSig * (1-revMix);
		//SUPEREXPENSIVE: use cheaper reverb, and think about routing to only 4 out_reverbs
		wetSig = GVerb.ar(compSig*revMix);
		sig = (drySig + wetSig) * amp;


		// -1 to +1 is used to modulate the pan along circle.
		Out.ar(out, PanAz.ar(3, Mix.ar(sig), pan) );
	}
).add;
)




//Some Pdefs:
(
Pbindef(\movingQ1,
	\instrument, \substractionMovingQ5chan,
	\dur, Pseq([5,10],inf),
	\release, 10,
	\attack, 3,
	\sustain,2,
	\amp, Prand([0.1,0.2,0.3],inf),
	\revMix, Prand([1,0.8,0.5,0.3,0.1],inf),
	\out, 2, //start for panning
	\pan, Pseq(Array.series(21, -1, 0.1) ,inf),
	\panwidth, 1,
	\degree, Pseq([0 ,3, 5, 6, 7]-2,inf),
	\octave, Pseq([2,4,5,6,7,8,9,10,11],inf)
);
)




Pbindef(\movingQ1).play;
Pbindef(\movingQ1).stop;

Pbindef(\movingQ1, \dur, Pseq([2,5]*2, inf));
Pbindef(\movingQ1, \out, Pseq([2], inf));
Pbindef(\movingQ1, \panwidth, 2);
Pbindef(\movingQ1, \out, Pseq([0,1,2], inf));
Pbindef(\movingQ1, \dur, Pseq([0.5,1],inf)); //move faster
Pbindef(\movingQ1, \dur, Pseq([0.5,1]*10,inf));
Pbindef(\movingQ1, \amp, Prand([0.1,0.1,0.05]/1.5,inf));
Pbindef(\movingQ1, 	\pan, Prand(Array.series(21, -1, 0.1) ,inf));

//freq
Pbindef(\movingQ1).play;
Pbindef(\movingQ1).stop;
Pbindef(\movingQ1, \dur, Pseq([2,5]*3, inf));
Pbindef(\movingQ1, \amp, Prand([0.1,0.1,0.05]/4,inf));
Pbindef(\movingQ1, \revMix, Prand([1,0.8],inf))

Pbindef(\movingQ1, \degree, Pseq([0 ,3, 5, 6, 7]-2,inf))
Pbindef(\movingQ1, \octave, Pseq([2,3,4,5,6,7,8,9,11],inf))







