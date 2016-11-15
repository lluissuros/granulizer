/*NICE:  pulse trans -5, iter 2

*/

s.record;
s.stopRecording;


/*TODO:
- A way of controlling multiple params : gui , and later nanokontrol
-efficientcy: kr as synthdefs, groups
-multichannel surrond
-play with out and mix: make it sweet progressive, dont like this out pattern
-TempoClock, linked to dur?
-Check PdefAllGui
-iters are not cool: too much cpu consuming
*/

Pdef(\arpegio2,
	Pseq([ Pseq(#[-7,-3,0,2,4,7,\rest], 1), Pshuf(#[-7,-3,0,2,4,7,\rest,\rest, \rest], 2), Pseq(#[-7,-3,0,2,4,7,\rest].reverse , 1)]));  //sums up 48, which /4 is 12 bars

Pdef(\arpegio2,
	Pseq(#[-7,-3,0,2,4,7,\rest],1));  //



/*other settings for patterns: check ~ampWaves
TODO: check chapter 16 of book, nice use of Pbindef
*/

Pdef(\pulseArp).set(\degree, Pshuf(#[-7,-3,0,2,4,7]));
Pdef(\pulseArp).set(\degree, Pseq([0]));
Pdef(\pulseArp).set(\degree, Pn(Pdef(\arpegio1),inf, \step));

Pdef(\iterArp1).set(\degree, Pshuf(#[-7,-3,0,2,4,7]));
Pdef(\iterArp1).set(\degree, Pn(Pdef(\arpegio2), inf, \step));

Pdef(\iterArp2).set(\degree, Pshuf(#[-7,-3,0,2,4,7]));
Pdef(\iterArp2).set(\degree, Pshuf(#[-7,-3,0,2,4,7]));


Pbindef(\grain0).play;





(
//s.record;

Pdef(\pulseArp).reset;
Pdef(\iterArp1).reset;
Pdef(\iterArp2).reset;

Pdef(\pulseArp).play;
Pdef(\iterArp1).play;
Pdef(\iterArp2).play;

Pdef(\pulseArp).fadeTime =2;
Pdef(\iterArp1).fadeTime =2;
Pdef(\iterArp2).fadeTime =2;
)


(
// changing amps like phased waves, TODO:needs to be exp!!
var amps = Array.fill(100,{arg i; i/100}) ++ Array.fill(100,{arg i; i/100}).reverse; //nicer
//var amps = Array.geom(20, 0.01, 1.27) ++ Array.geom(20, 0.01, 1.27).reverse;
~ampWaves = Task({
	inf.do({ arg i;
		Pdef(\ampPulse, Pseq([amps.wrapAt( i )]));
		Pdef(\ampIter1, Pseq([amps.wrapAt( i + (amps.size*1/3)) ]));
		Pdef(\ampIter2, Pseq([amps.wrapAt( i + (amps.size*2/3)) ]));
		0.4.wait;
	});
});
)
~ampWaves.start;
~ampWaves.stop;

Pdef(\amp, Pseq([0.2]));

~test = [1,2,3,4]
~test.size

~test.wrapAt(4.1)

t.start;
t.pause;
t.resume;
t.reset;
t.stop;

Array.geom(20, 0.01, 1.27).at(19)

(
// ordered sequence of mix value
q = Pseq(Array.fill(100,{arg i; i/100}) ++ Array.fill(100,{arg i; i/100}).reverse, inf).asStream;
m = Task({
	loop({
		~freeVerb.set(\mix, q.value);
		0.1.wait;
	});
});
)
m.start;
m.stop;



Pdef(\pulseArp).stop;
Pdef(\iterArp1).stop;
Pdef(\iterArp2).stop;


Synth.new(\pulseArp).play;

s.stopRecording


/*
 ******** Initialization **********
*/
(

/*SYNTHS
TODO: use AmpComp to compensate high frequencies!
*/

SynthDef.new(\iter1,{
	arg freq = 40 , out = 0, amp=1, minffreq=80, maxffreq=2000,pan=0,panX=0,panY=0;
	var temp, sum, env, ffreq;
	sum = 0;
	env = EnvGen.kr(
		//Env.perc(0.01,3,1,-2),
		Env.perc(0.01,8,-4),
		doneAction:2
	);
	//TODO: Splay/Mix instead of mono summing?
	10.do{
		temp = VarSaw.ar(
			freq * {Rand(0.99,1.02)}!2,
			{Rand(0.0,1.0)}!2,
			{ExpRand(0.005,0.05)}!2
		);
		sum = sum +temp;
	};

	maxffreq = MouseX.kr(0,1).exprange(50,4000);
	sum = sum * 0.02 * env * amp;
	ffreq = Rand(minffreq, maxffreq);
	sum = MoogFF.ar(sum, SinOscFB.kr(freq:ffreq.reciprocal, feedback: Rand(0,2), mul:ffreq/2, add:ffreq), MouseY.kr(0,4));

//	Out.ar(0, Pan2.ar(sum, pan));
	//panY.poll;
Out.ar( [0,1,2,3], Pan4.ar(sum, panX,panY));
}).add;


/*granular synth with variable click,  an expodec envelope sine grain with adjustable phase*/
SynthDef(\expodecPH, { |out, amp=0.1, freq=1000, click=0, sustain=0.01, pan|
	var snd = FSinOsc.ar(freq, click * 0.5pi);
	var env = XLine.ar(amp, amp * 0.001, sustain, doneAction: 2) * (AmpComp.ir(freq) * 0.5);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 6).add;



//TODO: this bassy click sound why?

SynthDef.new(\pulse1,{
	arg width = 0.5, maxPartial=4,ampHz=4, freq=40, out=~freeVerbBus, pan, sustain=2, amp=1;
	var amp1,amp2,freq1,freq2,sig1, sig2, src, env, noise1, noise2, ffreq;

	amp1=LFPulse.kr(ampHz,0,0.12)*0.75;
	amp2=LFPulse.kr(ampHz,0.0,0.12)*0.75;

	noise1 =  LFNoise0.kr(4);
	noise2 =  LFNoise0.kr(4);

	freq1 = noise1.exprange(freq, freq*maxPartial).round(freq);
	freq2 = noise2.exprange(freq, freq*maxPartial).round(freq);
	freq1= freq1 * LFPulse.kr(6,noise2, add:1);
	freq2= freq2/pan.linexp(-1, 1, 1, 8).round(2) * LFPulse.kr(8,noise1, add:1);
//	freq2= freq2/LFClipNoise.ar(6,add:3) * LFPulse.kr(8,noise1, add:1);

	env = EnvGen.kr(
		Env.perc(0.5,sustain,1,-2),
		doneAction:2
	);

	sig1= Pulse.ar(freq1,width,amp1) * env;
	sig2= Pulse.ar(freq2,width,amp2) * env;

	sig1 = Pan2.ar(sig1, pan);
	sig2 = Pan2.ar(sig2, pan.neg);

	src = sig1 + sig2;
	src = src *amp;

	Out.ar(out,src);
}).add;


//Reverb SynthDef

SynthDef.new(\freeVerb, {
	arg in=~freeVerbBus, out=0, mix =0.7, room=0.7, damp=0.8;
	var sig;
	sig = In.ar(in,2);
	Out.ar(0, FreeVerb.ar(sig,mix,room,damp));
}).add;
)

(
//BUSES
~freeVerbBus = Bus.audio(s,2);
~gVerbBus = Bus.audio(s,2);
~controlNoiseBus1 = Bus.control(s,1);
/*TODO: make Synthdefs with controls and pass them along in a control bus to the sourceUgens. Group them as controlGrp and add them before sourceGrp*/
~controlNoiseBus = Bus.control(s,1);
~controlGrp = Group.new;
~sourceGrp = Group.after(~controlGrp);
~fxGrp = Group.after(~sourceGrp);


// the 'catch-all' synth for fx
~freeVerb = Synth.new(\freeVerb, [\in, ~freeVerbBus], ~fxGrp ,addAction: 'addToTail');
)


(
var sweepPan;
/*PDEFS DECLARATION, GLOVARS and GUI*/
Pdef(\arpegio1,
	Pseq([ Pseq(#[-7,-3,0,2,4,7,\rest], 1), Pshuf(#[-7,-3,0,2,4,7,\rest,\rest, \rest], 2), Pseq(#[-7,-3,0,2,4,7,\rest].reverse , 1), Pshuf(#[-7,-3,0,2,4,7,\rest,\rest], 2)])
);  //sums up 48, which /4 is 12 bars

Pdef(\dur, Pseq([0.15]));
Pdef(\ampPulse, Pseq([1]));
Pdef(\ampIter1, Pseq([1]));
Pdef(\ampIter2, Pseq([1]));
Pdef(\cadence, Pseq([0,1,-2,2,-3,-5,-7,-7]));
Pdef(\octave, Pseq([5,5,5,5,5,5,6] ++ [5,4]++Array.fill(32, { arg i; 5 })));
sweepPan = Array.fill(21,{arg i; (i/10) -1}).mirror.postln;
Pdef(\pan, Pseq(sweepPan));
Pdef(\panX, Pseq(sweepPan));
Pdef(\panY, Pseq(sweepPan.rotate(10)));



Pdef(\pulseArp,
	Pbind(
		\instrument, \pulse1,
		\degree, Pn(Pdef(\arpegio1), inf, \step),
		//\mtranspose, Pgate(Pdef(\cadence), inf, \step), //when arpegio finishes
		\mtranspose, Pfunc({~mtranspose.wrapAt(~counterPulse)}) ,
		\dur, Pn(Pdef(\dur),inf),
		\octave, Pn(Pdef(\octave)+1, inf),
		\sustain, Pkey(\dur)*10,
		\pan, Pn(Pdef(\pan), inf),
		\amp, Pn(Pdef(\ampPulse),inf),
		\out, ~freeVerbBus,
		\group, ~sourceGrp));


Pdef(\iterArp1,
	Pbind(
		\instrument, \iter1,
		\degree, Pn(Pdef(\arpegio1), inf, \step),
		//\mtranspose, Pgate(Pdef(\cadence), inf, \step), //when arpegio finishes
		\mtranspose, Pfunc({~mtranspose.wrapAt(~counterIter)}) ,
		\dur, Pn(Pdef(\dur),inf),
		\octave, Pn(Pdef(\octave) -1, inf),
		\sustain, Pkey(\dur)*10,
		\pan, Pn(Pdef(\pan), inf),
		\panX, Pn(Pdef(\panX), inf),
		\panY, Pn(Pdef(\panY), inf),
		\out, ~freeVerbBus,
		\amp, Pn(Pdef(\ampIter1),inf),
		\group, ~sourceGrp));

Pdef(\iterArp2,
	Pbind(
		\instrument, \iter1,
		\degree, Pn(Pdef(\arpegio1), inf, \step),
		//\mtranspose, Pgate(Pdef(\cadence), inf, \step), //when arpegio finishes
		\mtranspose, Pfunc({~mtranspose.wrapAt(~counterIter)}) ,
		\dur, Pn(Pdef(\dur),inf),
		\octave, Pn(Pdef(\octave) + 1, inf),
		\sustain, Pkey(\dur)*10,
		\pan, Pn(Pdef(\pan), inf),
		\panX, Pn(Pdef(\panX), inf),
		\panY, Pn(Pdef(\panY), inf),
		\out, ~freeVerbBus,
		\amp, Pn(Pdef(\ampIter2),inf),
		\group, ~sourceGrp));

//Pbindef is way cooler
Pbindef(\grain0,
		\instrument, \expodecPH,
		\degree, Pn(Pdef(\arpegio1), inf, \step),
		\mtranspose, Pfunc({~mtranspose.wrapAt(~counterIter)}) ,
	//	\mtranspose, Pgate(Pdef(\cadence), inf, \step), //when arpegio finishes
		\dur, Pn(Penv([0.01, 0.1, 0.1, 0.01], [50,10.rand,50], \lin), inf),
	    \octave, Pn(Pdef(\octave) + 1, inf) + Pstutter(Pwhite(10, 50),  Pbrown(-1,3,1, inf)),
		\sustain, 0.1,
		\pan, Pfunc({ |ev| if(ev.degree.isInteger){ev.degree.linlin(-7,7,-1,1)}{0} }), // coupled to degree
		\out, ~freeVerbBus,
		\amp, Pbrown(0.3, 1, 0.1),
		\group, ~sourceGrp,
		\click, Pseq((0..200)/200, inf) // add more and more click
);




//GUI:
~mtranspose = [0,1,-2,2,-3,-5,-7];
~counterIter = 0;
~counterPulse= 0;
w = Window.new("Control transpose", Rect(1200, 100, 400, 150)).front;
w.view.decorator = f = FlowLayout(w.view.bounds);

f.nextLine;
StaticText(w, Rect(0, 0, 100, 20)).string_("pulse").stringColor_(Color.green);
Button.new(w, Rect(0, 0, 100, 20)).states_([["previous", Color.black, Color.clear]])
	.action_({
	~counterPulse = ~counterPulse - 1;
	~mtranspose.wrapAt(~counterPulse).postln});
Button.new(w, Rect(100, 50, 100, 20)).states_([["next", Color.black, Color.clear]])
	.action_({
	~counterPulse = ~counterPulse + 1;
	~mtranspose.wrapAt(~counterPulse).postln});


f.nextLine;
StaticText(w, Rect(0, 0, 100, 20)).string_("pulse").stringColor_(Color.green);
Button.new(w, Rect(50, 50, 100, 20)).states_([["pulseStart", Color.black, Color.clear]])
	.action_({
	Pdef(\pulseArp).reset;
	Pdef(\pulseArp).play;
	"pulseStart".postln;
});
Button.new(w, Rect(0, 0, 100, 20)).states_([["pulseStop", Color.black, Color.clear]])
	.action_({
	Pdef(\pulseArp).stop;
});

f.nextLine;
StaticText(w, Rect(0, 0, 100, 20)).string_("iter1").stringColor_(Color.blue);
Button.new(w, Rect(50, 50, 100, 20)).states_([["iter1Start", Color.black, Color.clear]])
	.action_({
	Pdef(\iterArp1).reset;
	Pdef(\iterArp1).play;
	"pulseStart".postln;
});
Button.new(w, Rect(0, 0, 100, 20)).states_([["iter1Stop", Color.black, Color.clear]])
	.action_({
	Pdef(\iterArp1).stop;
});

f.nextLine;
	StaticText(w, Rect(0, 0, 100, 20)).string_("iter2").stringColor_(Color.blue);
Button.new(w, Rect(50, 50, 100, 20)).states_([["iter2Start", Color.black, Color.clear]])
	.action_({
	Pdef(\iterArp2).reset;
	Pdef(\iterArp2).play;
	"pulseStart".postln;
});
Button.new(w, Rect(0, 0, 100, 20)).states_([["iter2Stop", Color.black, Color.clear]])
	.action_({
	Pdef(\iterArp2).stop;
});


f.nextLine;
	StaticText(w, Rect(0, 0, 100, 20)).string_("grain0").stringColor_(Color.blue);
Button.new(w, Rect(50, 50, 100, 20)).states_([["grain0Start", Color.black, Color.clear]])
	.action_({
	Pbindef(\grain0).reset;
	Pbindef(\grain0).play;
	"grainStart".postln;
});
Button.new(w, Rect(0, 0, 100, 20)).states_([["grain0Stop", Color.black, Color.clear]])
	.action_({
	Pbindef(\grain0).stop;
});


f.nextLine;
StaticText(w, Rect(0, 0, 100, 20)).string_("iterTransp").stringColor_(Color.blue);
Button.new(w, Rect(0, 0, 100, 20)).states_([["previous", Color.black, Color.clear]])
	.action_({
	~counterIter = ~counterIter - 1;
	~mtranspose.wrapAt(~counterIter).postln});
Button.new(w, Rect(50, 50, 100, 20)).states_([["next", Color.black, Color.clear]])
	.action_({
	~counterIter = ~counterIter + 1;
	~mtranspose.wrapAt(~counterIter).postln});


//s.plotTree;

)


/*Simple trigger code...*/
(

SynthDef(\ampListener, {arg id1, limit = 1, thresh = 0.5;
	var src, amp, amptrig, timer;
	src = SoundIn.ar(0);
	// analyze the amplitude input, cause a trigger if the output is over the thresh
	amp = Amplitude.kr(src);
	amptrig = Trig.kr(amp > thresh, limit);
	// use amptrig to see how long it is between triggers.
	//timer = Timer.kr(amptrig);
	// send the values back with two different ids
	SendTrig.kr(amptrig, id1, amp);
	//SendTrig.kr(amptrig, id2, timer);
}).add;


// modulated noise to respond to amp spikes
SynthDef(\makeNoise, {arg freq;
	Out.ar(1, LFNoise1.ar(200) * SinOsc.ar(freq, 0,
		XLine.kr(0.1, 0.00001, 0.5, doneAction: 2)));
}).add;

// allocate the unique ids for the trigger ids
~id1 = UniqueID.next;

// an envelope to poll for amp values later
e = Env([440, 880], [1], \exp);

// add the responder:
o = OSCresponderNode(s.addr, '/tr', {arg time, responder, msg;
	// the msg is an array with 4 values... post them
	msg.postln;
	// the id sent back from the SendTrig is msg[2]... use it to decide what to do
	case
		// amp trigger
		{msg[2] == ~id1}
	   // play a noise burst, higher the amp value, higher the freq(polls the Env 'e')
		{Synth(\makeNoise, [\freq, e[msg[3]]]);
		//change the counter:
		~counterIter = ~counterIter + 1;
	   ~mtranspose.wrapAt(~counterIter).postln;
		~counterPulse = ~counterPulse + 1;
		~mtranspose.wrapAt(~counterPulse).postln;
	}
}).add;

//the listener:
Synth(\ampListener, [\id1, ~id1, \limit, 0.2, \thresh, 0.75]);

// add a command period function to stop the synths and remove the responder
CmdPeriod.doOnce({
	o.remove; "Removed the responder".postln;
})
)
