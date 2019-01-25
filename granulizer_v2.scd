//Granulizer v2


/*
TODO:

- Record and save it in the /sounds to be available for granulizer and for loop playback
- Master Group
*/

/*
DOUBTS:
-
*/

s
//Dynamically Load sounds:

(
ServerQuit.removeAll;
ServerBoot.removeAll;
ServerTree.removeAll;
Buffer.freeAll;


/*
 All this is provisional

/* ---------- 1.server ---------- */
s =Server.local;
//ServerOptions.devices
s.options.outDevice_(
	"Built-in Output"
	//	"Soundflower (2ch)"
	//	"Soundflower (64ch)"
	//	"Dispositivo de salida múltipl"
)
s.options.numOutputBusChannels = 2;
*/

// background task to acces Mouse from sclang:
// Maybe ServerTree.add could also work?
SkipJack({ defer {
	~cursorX = QtGUI.cursorPosition.x / Window.screenBounds.extent.x;
	~cursorY = QtGUI.cursorPosition.y / Window.screenBounds.extent.y;
} }, 0.1);


~sounds = Dictionary.new;
~soundToPlay = ();
~activeSounds = List.new;
~soundGains =  Dictionary.new; //add individual gains


~buses = Dictionary.new;

~buses.add(\infiniteHoldReverb0 -> Bus.audio(s, 2));
~buses.add(\reverb0 -> Bus.audio(s, 2));
~buses.add(\reverb1 -> Bus.audio(s, 2));
~buses.add(\streson0 -> Bus.audio(s, 2));

~createGroups = {
	~mainGrp = Group.new;
	~FxGrp = Group.after(~mainGrp);
	~reverbGrp = Group.after(~FxGrp);

	~streson0 = Synth(\streson, [\in, ~buses[\streson0], \out, ~buses[\reverb0], \mix, 1], ~FxGrp);
	~infiniteHoldReverb0 =  Synth(\infiniteHoldReverb, [\in, ~buses[\infiniteHoldReverb0], \out, 0, \mix, 0.5, \feedback, 0.4], ~reverbGrp);
	~reverb0 = Synth(\reverb,[\in, ~buses[\reverb0], \out, 0, \mix, 0.025], ~reverbGrp);
	~reverb1 = Synth(\reverb,[\in, ~buses[\reverb1], \out, 0, \mix, 0.3],~reverbGrp);
};


s.waitForBoot({

	var soundsFilenames = ("sounds".resolveRelative +/+ "*").pathMatch;
	var buffers = soundsFilenames.collect({arg path; Buffer.readChannel(s, path, channels:[0]) });
	buffers.do({ arg n, index; ~sounds.add(index -> n) });

	postf("loading % buffers... \n", buffers.size);
	s.sync;
	"sounds loaded...".postln;


	SynthDef(\bufPlayer, {
		arg buf=0, vel=1, sPos=0, atk=0.001, sus=0.2, rel=0.05, amp=1, pan=0, out=0;
		var env = Env( [0,1,1,0], [atk,sus,rel], [1,0,-1] ).kr(2);
		var framePos = sPos *  BufFrames.kr(buf);
		var sig = PlayBuf.ar(1, buf, vel * BufRateScale.kr(buf), startPos:framePos);
		sig = sig * env;
		sig = Pan2.ar(sig, pan, amp);
		Out.ar(out, sig);
	}).add;


	SynthDef(\reverb, {
		arg in=20, out=0, amp=1, mix=0.05, freqF=4000, decay=2.5, delay=0.05;
		var sig, wet, dry;
		dry = In.ar(in, 2);
		wet = dry;
		wet = DelayN.ar(wet, delay, delay);
		20.do{wet = AllpassN.ar(wet, 0.05,{Rand(0.001,0.05)}!2, decay); wet = LPF.ar(wet,freqF);};
		sig = XFade2.ar(dry, wet, mix*2-1, amp);
		Out.ar(out, sig);
	}).add;


	SynthDef(\streson, {
		arg in, res=0.9, amp=0.3, delaytime=0.0083,  out=0, mix=1;
		var dry = In.ar(in,2);
		var wet = Streson.ar(
			dry,
			delaytime + LFNoise2.ar(2).range(0.0001, 0.001), // provisional
			res,
			amp);
		var sig = XFade2.ar(dry, wet, 1*2-1);
		Out.ar(0, sig);
	}).add;

	SynthDef(\infiniteHoldReverb, {
		arg in, feedback = 0.9, gateThreshold = 0.02, amp=1, mix=1;
		//input signal
		var dry =  In.ar(in,2);
		var inAmp = Amplitude.kr(Mix.ar(dry));
		var gatedSig = dry * (inAmp > gateThreshold);
		var local = (LocalIn.ar(2) + gatedSig.dup);

		//apply reverb
		var out = (0..14).inject(local, AllpassL.ar( _ ,0.06, Rand(0.01, 0.06), 3));

		//complete feedback loop - send audio back to LoopIn
		out = LeakDC.ar(out);
		LocalOut.ar(out * feedback);

		//non-feedback output to speakers.
		out = Limiter.ar(out);
		out = XFade2.ar(dry, out, mix*2-1, amp).softclip;
		Out.ar(0, out);
	}).add;


	s.sync;
	"synthDefs loaded...".postln;


	ServerTree.add(~createGroups);
	Pbindef.all.do(_.clear);
	s.freeAll;

	///SystemClock, AppClock, TempoClock
	t = TempoClock(80/60);

	(
		~tempoCounter = {
			("Temps: "+ (t.beatInBar + 1)).postln;
			("Compas: "+ t.bar).postln;
			[t.beatsPerBar + ("/4"), t.tempo * 60 ].postln;
			"

".postln;
			1;
	} );



	// ---  TENDENCY  CHOOSING SAMPLES-----
	~tendency = Tendency.new(
		Env([1.0, 0.5, 1.0], [0.5, 0.5]),
		Env([0.9, 0.0, 0.9], [0.8, 0.2], [-10, 5]));

	~probCycleDurSeconds = 10;
	~probCycleSteps = 100;

	~getActiveSound = Task({
		~getActiveSoundWchosen.stop;
		inf.do({ |i|
			var numSamples = ~activeSounds.size;
			var phases = Array.fill(numSamples,  _/numSamples);
			var indexes = phases.collect( ( i/~probCycleSteps + _ )  %1 );
			var probs = indexes.collect(~tendency.at( _ ));

			var maxIndex = probs.maxIndex;
			var soundToPlayBuf = ~activeSounds.at(maxIndex);
			~soundToPlay = (
				buf: soundToPlayBuf,
				activeSoundsIndex: maxIndex,
				prob: probs.at(maxIndex),
			);

			//~soundToPlay[\buf].postln;

			(~probCycleDurSeconds/~probCycleSteps).wait;
		});
	});

	~getActiveSoundWchosen = Task({
		~getActiveSound.stop;
		inf.do({ |i|
			var numSamples = ~activeSounds.size;
			var phases = Array.fill(numSamples,  _/numSamples);
			var indexes = phases.collect( ( i/~probCycleSteps + _ )  %1 );
			var probs = indexes.collect(~tendency.at( _ ));

			var wChosenBuf = ~activeSounds.wchoose(probs.normalizeSum);
			var wChosenIndex = ~activeSounds.indexOf(wChosenBuf);

			~soundToPlay = (
				buf: wChosenBuf,
				activeSoundsIndex: wChosenIndex,
				prob: probs.at( wChosenIndex ),
			);

			//~soundToPlay[\buf].postln;
			(~probCycleDurSeconds/~probCycleSteps).wait;
		});
	});



	Pdefn(\morphPanner,
		Pfunc({
			var changeEachBar =  if(t.bar.asInt.odd){-1}{1};
			var panDirectionByIndex = if(~soundToPlay[\activeSoundsIndex].odd, 1, -1);
			var panVal = (~soundToPlay[\prob] -1)  * panDirectionByIndex * changeEachBar;
			panVal;
	}));


	Pdefn(\incrementally_0_to_1_millis_and_back, Pslide(Pseries(0.0, 0.001, 1000).asStream.all.mirror, inf, Pbrown(10,100,1), 1, 0));


	s.sync;
	"Tasks: ~getActiveSound and ~getActiveSoundWchosen available...".postln;
	"Pdefn: \morphPanner, \incrementally_0_to_1_millis_and_back  available...".postln;


	~activeSounds.add(~sounds.at(10));

	Pbindef(\glitch1,
		\instrument, \bufPlayer,
		\buf, Pseq(~activeSounds, inf),
		\dur, Pwrand([Pseq([1/8],8), Pseq([1/4],4), Pseq([1/2],2)]/100,[0.95,0.03,0.02],inf),
		//\dur, t.tempo * 4,
		\atk, 0.1,
		\sus, Pexprand(0.0025,0.075),
		\rel, 0.001,
		\sPos, Pfunc( { |evt|
			var noiseDev =  exprand(0.0001, 0.01);
			~cursorX + noiseDev } ),
		\vel, Pwrand([
			Pseq([1], 8),
			Pwrand([1,Pwhite(2.5,4,1),Pwhite(0.5,0.9,1)],[0.95,0.025,0.025],32),
			Pseq([2],8),
			Pseq([4],8)
		],[0.85,0.05,0.05, 0.05],inf),
		\pan, Pstutter(Pseq([1,3], inf), Pwhite(-1.0, 1.0 ) ),
		\amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf),
		\out, Pwrand( [~buses[\reverb0], ~buses[\reverb1]], [0.95,0.05], inf),
	);

	Pbindef(\morphPlayer,
		\instrument, \bufPlayer,
		\buf, Pfunc({~soundToPlay[\buf]}) ,
		\dur, Pwrand([Pseq([1/8],8), Pseq([1/4],4), Pseq([1/2],2)]/100,[0.95,0.03,0.02],inf),
		//\dur, t.tempo * 4,
		\atk, 0.1,
		\sus, Pexprand(0.0025,0.075),
		\rel, 0.001,
		\sPos, Pfunc( { |evt|
			var noiseDev =  exprand(0.0001, 0.01);
			~cursorX + noiseDev } ),
		\vel, Pwrand([
			Pseq([1], 8),
			Pwrand([1,Pwhite(2.5,4,1),Pwhite(0.5,0.9,1)],[0.95,0.025,0.025],32),
			Pseq([2],8),
			Pseq([4],8)
		],[0.96,0.01,0.01, 0.01],inf),
		\pan, Pdefn(\morphPanner),
		\prob, Pfunc({~soundToPlay[\prob]}),
		\amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf) * Pkey(\prob),
		\out, Pwrand( [~buses[\reverb0], ~buses[\reverb1]], [0.95,0.05], inf),
	);

	s.sync;
	"PbindDefs: \glitch1, \morphPlayer ready...".postln;
	"...All ready.".postln;
});
)





(
// ------  START ------
t = TempoClock.new.permanent_(true);
t.schedAbs(t.nextBar, {
	~getActiveSound.play(t);
	~activeSounds.add(~sounds[15] );
	Pbindef(\morphPlayer).play;
	//~tempoCounter.value;
});
)

(
// postcards
~activeSounds = List.new;
~activeSounds = ~sounds.atAll([7,8,9,10,11,12,15])
)


//spotlight:
(
~activeSounds = List.new;
~activeSounds.add(~sounds[34]);
)

Synth(\bufPlayer, ~soundToPlay[\buf])
{PlayBuf.ar(1, ~soundToPlay[\buf])}.play
{PlayBuf.ar(1, ~sounds[\songs][0])}.play




(
~sounds.keysDo{
	|key|
	~sounds[key].postln;
}
)



s.record;
s.stopRecording;

// ---  MORPH PLAYER ---
Pbindef(\morphPlayer).play;
Pbindef(\morphPlayer).stop;

Pbindef(\morphPlayer, \amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf) * Pkey(\prob).trace)
Pbindef(\morphPlayer, \amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf))

Pbindef(\morphPlayer, \sPos, Pdefn(\incrementally_0_to_1_millis_and_back));

Pbindef(\morphPlayer, \out, Pwrand( [~buses[\reverb0], ~buses[\reverb1], ~buses[\streson0]], [0.90 ,0.05, 0.05], inf));
Pbindef(\morphPlayer, \out, Pwrand( [~buses[\reverb0], ~buses[\reverb1], ~buses[\streson0]], [0.40 ,0.1, 0.50], inf));
Pbindef(\morphPlayer, \out, Pwrand( [~buses[\reverb0], ~buses[\reverb1], ~buses[\streson0], ~buses[\infiniteHoldReverb0]], [0.10 ,0.2, 0.2, 0.5], inf));
Pbindef(\morphPlayer, \out, ~buses[\infiniteHoldReverb0]);
Pbindef(\morphPlayer, \out, ~buses[\streson0]);

~infiniteHoldReverb0.set(\feedback, 0.49);
~infiniteHoldReverb0.set(\mix, 0.55);
~streson0.set(\delaytime, Pdefn(\incrementally_0_to_1_millis_and_back) + 0.00001)
~streson0.set(\out, ~buses[\infiniteHoldReverb0]);

Pbindef(\morphPlayer, \dur, Pwrand([Pseq([1/8],8), Pseq([1/4],4), Pseq([1/2],2)] ,[0.95,0.03,0.02],inf) / Pseq( Array.series(1000,1,0.05).mirror, inf));
Pbindef(\morphPlayer, \dur, Pwrand([Pseq([1/8],8), Pseq([1/4],4), Pseq([1/2],2)] ,[0.95,0.03,0.02],inf) / Pseq( Array.geom(1000,1,1.004).mirror, inf)); //nice

Pbindef(\morphPlayer, \atk, Pbrown(0.001, 0.5, 0.0125, inf));
Pbindef(\morphPlayer, \sus, Pbrown(0.001, 0.5, 0.0125, inf));
Pbindef(\morphPlayer, \rel, Pbrown(0.01, 0.05, 0.0125, inf));

//cursorX reset
Pbindef(\morphPlayer,\sPos, Pfunc( { |evt|
	var noiseDev =  exprand(0.0001, 0.01);
	~cursorX + noiseDev } ));







// ---  GLITCH 1 ---
Pbindef(\glitch1).play;
Pbindef(\glitch1).stop;


Pbindef(\glitch1, \buf, Pseq(~sounds.atAll([7,8,9,10,11,12,15]), inf));


Pbindef(\glitch1, \buf, Pn(
	Pfunc({
		var indexes = [7,8,9,10,11,12,13,14,15];
		var weights = [4,0.5,2,1,8,2,0.5,1,0.5].normalizeSum;
		~sounds.at(indexes.wchoose(weights));
}), 500), inf).play;

Pbindef(\glitch1, \buf, Pseq(~activeSounds, inf));
Pbindef(\glitch1, \buf, ~activeSounds.at(Pseq([5], inf))).play;

Pbindef(\glitch1, \pan, Pbrown(0, 1, 0.075, inf));

Pbindef(\glitch1, \atk, Pbrown(0.001, 0.5, 0.0125, inf));
Pbindef(\glitch1, \sus, Pbrown(0.001, 0.2, 0.0125, inf));
Pbindef(\glitch1, \rel, Pbrown(0.01, 0.05, 0.0125, inf));

Pbindef(\glitch1, \sPos, Pdefn(\incrementally_0_to_1_millis_and_back));


//reset
Pbindef(\glitch1,\sPos, Pfunc( { |evt|
	var noiseDev =  exprand(0.0001, 0.01);
	~cursorX + noiseDev } ));



s.record
s.stopRecording














// ------  SUPER NICE IDEAS ------

BandSplitter2
BandSplitter4



//record to loop
File.getcwd
var recordfolderPath = thisProcess.nowExecutingPath.dirname ++ "/records" ;

