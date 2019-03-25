//test BandSplitter8

(
SynthDef(\BandSplitter8, {
	arg in, minCross, maxCross, out=0, mix=1;

	var dry = In.ar(in,2);

	//TODO it should move around that would be really nice, maybe thourg sclang providing an array as argument

//also sum an SinOsc to the freqs
	var f1 = 200;
	var f2 = 400;
	var f3 = 700;
	var f4 = 1000;
	var f5 = 1500;
	var f6 = 2000;
	var f7 = 3500;

	var spl1, spl2, spl3, spl4, spl5, spl6, spl7, spl8;

	#spl1, spl2, spl3, spl4, spl5, spl6, spl7, spl8 = BandSplitter8.ar(dry, f1, f2, f3, f4, f5, f6, f7);

	Out.ar(out, [spl1, spl2, spl3, spl4, spl5, spl6, spl7, spl8]);
}).add;

)


~bandSplitter8 = Synth(\BandSplitter8, [\in, ~buses[\reverb0], \out, 0], ~reverbGrp);