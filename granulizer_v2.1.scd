
/*
TODO:
- GUI for activeSounds
- new events
-Infinite Reverb detunes to infinite lower (put HPF)
*/


//The arquitecture is 90% based on Eli FieldStel https://www.youtube.com/watch?v=P85X1Ut3Hfc&t=58s

(
//1. server config
s = Server.local;
s.quit;

//ServerOptions.devices //get devices

s.options.outDevice_(
	//"Plantronics C320"
	"Fireface UCX (23382434)"
	//"Built-in Output"
	//"Soundflower (2ch)"
);
s.options.inDevice_(
	//"Plantronics C320"
	"Fireface UCX (23382434)"
	//"Built-in Microph"
	//"Soundflower (2ch)"
);



s.options.numOutputBusChannels_(2);

s.options.numInputBusChannels_(2);
s.options.sampleRate_(44100);
s.options.memSize_(2.pow(20));
s.newBusAllocators;
Pbindef.all.do(_.clear);
ServerBoot.removeAll;
ServerTree.removeAll;
ServerQuit.removeAll;

//2. initialize global variables
~out = 0;
~soundsPath = "sounds/".resolveRelative;
~sounds = ~sounds ? Dictionary.new;
~activeSounds = ~activeSounds ? List.new;
~soundToPlay = ();
~soundGains =  ~soundGains ? Dictionary.new; //add individual gains, TODO
~tuneInCents = 0;

~tendency = Tendency.new(
	Env([1.0, 0.5, 1.0], [0.5, 0.5]),
	Env([0.9, 0.0, 0.9], [0.8, 0.2], [-10, 5]));
~probCycleDurSeconds = 10;
~probCycleSteps = 100;
~initActiveSounds.();


//3. define piece-specific functions
~makeBuffers = {
	postf(" % subfolders found... \n", PathName(~soundsPath).entries.size);

	PathName(~soundsPath).entries.do{
		arg subfolder;
		var subfolderName = subfolder.folderName;
		postf("  \n ... loading % subfolder: \n", subfolderName);

		~sounds.add(
			subfolderName.asSymbol ->
			subfolder.entries.collect({
				arg path, i;
				postf("  * %  \n",  path.fileNameWithoutExtension);
				Buffer.readChannel(s, subfolder.entries[i].fullPath, channels:[0])
			});
		);
	};

	"\n ...loading complete \n";
};


~makeBusses = {
	~buses = Dictionary.new;
	~buses.add(\infiniteHoldReverb0 -> Bus.audio(s, 2));
	~buses.add(\reverb0 -> Bus.audio(s, 2));
	~buses.add(\reverb1 -> Bus.audio(s, 2));
	~buses.add(\streson0 -> Bus.audio(s, 2));
};


~getCursorPosition =  SkipJack({ defer {
	~cursorX = QtGUI.cursorPosition.x / Window.screenBounds.extent.x;
	~cursorY = QtGUI.cursorPosition.y / Window.screenBounds.extent.y;
} }, 0.1);

~initActiveSounds = {
	~activeSounds = List.new;
	~sounds[\postcards].do({ |buf|
		~activeSounds.add((buf));
	});
};

~cleanup = {
	s.newBusAllocators;
	ServerBoot.removeAll;
	ServerTree.removeAll;
	ServerQuit.removeAll;
};

~makeNodes = {
	s.bind({
		~mainGrp = Group.new;
		~fxGrp = Group.after(~mainGrp);
		~reverbGrp = Group.after(~fxGrp);

		~streson0 = Synth(\streson, [\in, ~buses[\streson0], \out, ~buses[\reverb0], \mix, 1], ~fxGrp);
		~infiniteHoldReverb0 =  Synth(\infiniteHoldReverb, [\in, ~buses[\infiniteHoldReverb0], \out, 0, \mix, 0.5, \feedback, 0.4], ~reverbGrp);
		~reverb0 = Synth(\reverb,[\in, ~buses[\reverb0], \out, 0, \mix, 0.025], ~reverbGrp);
		~reverb1 = Synth(\reverb,[\in, ~buses[\reverb1], \out, 0, \mix, 0.3],~reverbGrp);
	});
};


~getActiveSound = Task({
	~getActiveSoundWchosen.stop;
	inf.do({ |i|
		var numBuffers = ~activeSounds.size;
		if (numBuffers > 0 , {
			var phases = Array.fill(numBuffers,  _/numBuffers);
			var indexes = phases.collect( ( i/~probCycleSteps + _ )  %1 );
			var probs = indexes.collect(~tendency.at( _ ));

			var maxIndex = probs.maxIndex;
			var soundToPlayBuf = ~activeSounds.at(maxIndex);
			~soundToPlay = (
				buf: soundToPlayBuf,
				activeSoundsIndex: maxIndex,
				prob: probs.at(maxIndex),
			);
		});
		(~probCycleDurSeconds/~probCycleSteps).wait;
	});
});

~getActiveSoundWchosen = Task({
	~getActiveSound.stop;
	inf.do({ |i|
		var numBuffers = ~activeSounds.size;
		if (numBuffers > 0 , {
			var phases = Array.fill(numBuffers,  _/numBuffers);
			var indexes = phases.collect( ( i/~probCycleSteps + _ )  %1 );
			var probs = indexes.collect(~tendency.at( _ ));

			var wChosenBuf = ~activeSounds.wchoose(probs.normalizeSum);
			var wChosenIndex = ~activeSounds.indexOf(wChosenBuf);

			~soundToPlay = (
				buf: wChosenBuf,
				activeSoundsIndex: wChosenIndex,
				prob: probs.at( wChosenIndex ),
			);
		});
		(~probCycleDurSeconds/~probCycleSteps).wait;
	});
});

~findBufferByName = { |fileName|
	var subfoldersContents =  ~sounds.values;
	var foundBuffer = nil;
	var i = 0;

	while({ i<subfoldersContents.size && foundBuffer.isNil == true }, {
		var buffers = subfoldersContents[i];
		foundBuffer = buffers.detect({ |buffer|
			var bufferFileName = buffer.path.basename.splitext[0];
			bufferFileName == fileName;
		});
		i = i+1;
	});
	foundBuffer;
};

~getBufFileName = {|buf|
	PathName(buf.path).fileNameWithoutExtension;
};

~logSounds = {
	arg folderName;
	~sounds[folderName.asSymbol].do({
		|buf|
		~getBufFileName.(buf).postln;
	});
};

~removeActiveSound = {
	arg fileName;
	var indexToRemove = ~activeSounds.detectIndex({|buf| ~getBufFileName.(buf) == fileName });
	var newActiveSounds = ~activeSounds.reject({ |buf, index| index ==  indexToRemove});
	~activeSounds = newActiveSounds.asList;
};



~makePatterns = {
	Pdefn(\morphPanner,
		Pfunc({
			var changeEachBar =  if(t.bar.asInt.odd){-1}{1};
			var panDirectionByIndex = if(~soundToPlay[\activeSoundsIndex].odd, 1, -1);
			var panVal = (~soundToPlay[\prob] -1)  * panDirectionByIndex * changeEachBar;
			panVal;
	}));

	Pdefn(\incrementally_0_to_1_millis_and_back, Pslide(Pseries(0.0, 0.001, 1000).asStream.all.mirror, inf, Pbrown(10,100,1), 1, 0));
};





~makeEvents = {
	MIDIIn.connectAll;
	e = Dictionary.new;

	e.add(\event1 -> {
		~shakerSustain = Pbind(
			\instrument, \bpfBufPlayer,
			\dur, Pwhite(0.2,0.7),
			\atk, Pexprand(2,4),
			\rel, Pexprand(3,5),
			\buf, ~sounds[\shakers][13].bufnum,
			\rate, Pwhite(-7.0,-4.0).midiratio,
			\sPos, Pwhite(0, ~sounds[\shakers][13].numFrames/2),
			\amp, Pexprand(0.17,0.25),
			\freq, {rrand(85.0,105.0).midicps}!3,
			\rq, 0.005,
			\bpfmix, 0.97,
			\group, ~mainGrp,
			\out, ~buses[\reverb],
		).play;

		~drone = Pbind(
			\instrument, \bpfsaw,
			\dur, 1,
			\freq, 26.midicps,
			\detune, Pwhite(0.03,0.2),
			\rqmin, 0.08,
			\rqmax, 0.12,
			\cfmin, 50,
			\cfmax, 400,
			\atk, 2,
			\sus, 0.1,
			\rel, 2,
			\amp, 0.5,
			\group, ~mainGrp,
			\out, ~buses[\reverb],
		).play;
	});

	e.add(\event2 -> {
		Routine({
			~bellCloud = Pbind(
				\instrument, \bpfBufPlayer,
				\dur, Pexprand(0.2,2),
				\atk, Pexprand(0.5,2),
				\rel, Pexprand(2,6),
				\buf, ~sounds[\deskBells][0],
				\rate, Pwhite(-7.5,-5.5).midiratio,
				\sPos, Pwhite(5000,80000),
				\amp, Pexprand(2,5),
				\bpfmix, 0,
				\group, ~mainGrp,
				\out, ~buses[\reverb],
			).play;

			~bubbles = Pbind(
				\instrument, \bpfsaw,
				\dur, Pwhite(0.1,0.5),
				\freq, Pexprand(1,25),
				\detune, Pwhite(0.03, 0.2, inf),
				\rqmin, 0.1,
				\rqmax, 0.5,
				\cfmin, 50,
				\cfmax, 2000,
				\atk, 2,
				\sus, 0,
				\rel, Pexprand(3,8),
				\pan, Pwhite(-0.9,0.9),
				\amp, Pexprand(0.05,0.1),
				\group, ~mainGrp,
				\out, ~buses[\reverb],
			).play;

			4.wait;

			~shakerSustain.stop;
			~drone.stop;
		}).play(AppClock);
	});

	e.add(\event3 -> {
		~bellCloud.stop;
		~bubbles.stop;

		~bellTone = Pbind(
			\instrument, \bpfBufPlayer,
			\dur, Pexprand(0.5,3),
			\atk, 2,
			\rel, 2,
			\buf, ~sounds[\deskBells][11],
			\rate, Pwhite(-0.08,0.08).midiratio,
			\sPos, Pwhite(5000,20000),
			\amp, Pexprand(2,3.5),
			\bpfmix, 0,
			\group, ~mainGrp,
			\out, ~buses[\reverb],
		).play;

		~simpleMarimba = Pbind(
			\instrument, \bpfsaw,
			\dur, Prand([0.5,1,2,3],inf),
			\freq, Prand([1/2,3/4,1,3/2,2], inf),
			\detune, Pwhite(0,0.002),
			\rqmin, 0.005,
			\rqmax, 0.008,
			\cfmin, Prand([61,71,78,85,95].midicps,inf),
			\cfmax, Pkey(\cfmin) * Pwhite(1.008,1.025,inf),
			\atk, 3,
			\sus, 1,
			\rel, 5,
			\amp, 1,
			\group, ~mainGrp,
			\out, ~buses[\reverb],
		).play;
	});

	e.add(\event4 -> {
		~bellTone.stop;
		~simpleMarimba.stop;

		~chords = Pbind(
			\instrument, \bpfsaw,
			\dur, Pwhite(4.5,7.0),
			\midinote, Pxrand([
				[23,35,54,63,64],
				[45,52,54,59,61,64],
				[28,40,47,56,59,63],
				[42,52,57,61,63]
			], inf),
			\detune, Pexprand(0.05,0.2),
			\cfmin, 100,
			\cfmax, 1500,
			\rqmin, Pexprand(0.01,0.15),
			\atk, Pwhite(2.0,2.5),
			\rel, Pwhite(6.5,10.0),
			\ldb, 6,
			\amp, 0.2,
			\group, ~mainGrp,
			\out, ~buses[\reverb],
		).play;

		~marimba = Pbind(
			\instrument, \bpfsaw,
			\dur, Prand([1,0.5],inf),
			\freq, Prand([1/2,2/3,1,4/3,2,5/2,3,4,6,8],inf),
			\detune, Pwhite(0,0.1),
			\rqmin, 0.005,
			\rqmax, 0.008,
			\cfmin, Prand((Scale.major.degrees+64).midicps,inf) * Prand([0.5,1,2,4],inf),
			\cfmax, Pkey(\cfmin) * Pwhite(1.008,1.025),
			\atk, 3,
			\sus, 1,
			\rel, 5,
			\amp, 1,
			\group, ~mainGrp,
			\out, ~buses[\reverb],
		).play;
	});

	e.add(\event5 -> {
		~marimba.stop;
		~chords.stop;
	});

	e.add(\oneshot1 -> {
		12.do{
			Synth(
				\bpfsaw,
				[
					\atk, exprand(0.5,1.5),
					\rel, exprand(2.0,8.0),
					\c1, exprand(4,10.0),
					\c2, exprand(2.0,5).neg,
					\freq, exprand(8,60),
					\detune, rrand(0.1,4),
					\cfmin, 30,
					\cfmax, 400,
					\rqmin, 0.02,
					\rqmax, 0.08,
					\amp, exprand(0.5,0.9),
					\pan, rrand(-0.5,0.5),
					\out, ~buses[\reverb],
				],
				~mainGrp
			);
		};
	});

	e.add(\oneshot2 -> {
		15.do{
			Synth(
				\bpfBufPlayer,
				[
					\atk, rrand(0.2,3.0),
					\sus, rrand(0.2,2.0),
					\rel, exprand(1.0,6.0),
					\c1, exprand(1,8),
					\c2, exprand(-8,-1),
					//\buf, ~sounds[\shakers][13].bufnum,
					\buf, ~sounds[\postcards][2].bufnum,
					\rate, exprand(0.4,2.0),
					\bpfmix, 0,
					\amp, exprand(0.2,0.5),
					\pan, rrand(-0.9,0.9),
					\sPos, rrand(0,100000),
					\out, ~buses[\reverb]
				],
				~mainGrp
			);
		};
	});

	e.add(\oneshot3 -> {
		15.do{
			Synth(
				\bpfBufPlayer,
				[
					\atk, rrand(0.1,2.0),
					\sus, rrand(2.5,6.0),
					\rel, exprand(1.0,5.0),
					\c1, exprand(1,8),
					\c2, exprand(-8,-1),
					\buf, ~sounds[\shakers][13].bufnum,
					\rate, exprand(0.3,1.2),
					\freq, (Scale.major.degrees.choose+64 + [-12,0,12,24].choose).midicps,
					\rq, exprand(0.002,0.02),
					\bpfmix, 1,
					\amp, exprand(0.2,1.5),
					\pan, rrand(-0.9,0.9),
					\sPos, rrand(0,100000),
					\out, ~buses[\reverb],
				],
				~mainGrp
			);
		};
	});


	t = TempoClock(80/60).permanent_(true);
	~tempoCounter = {
		("Temps: "+ (t.beatInBar + 1)).postln;
		("Compas: "+ t.bar).postln;
		[t.beatsPerBar + ("/4"), t.tempo * 60 ].postln;
		"\n \n".postln;
		1;
	};


	MIDIdef.cc(\controllerWithRButtonsNano, {
		arg val, num;
		//basically FieldSteel things
		case
		{num==64 && val==127} {e[\event1].value;"event1".postln;}
		{num==65 && val==127} {e[\event2].value;"event2".postln;}
		{num==66 && val==127} {e[\event3].value;"event3".postln;}
		{num==67 && val==127} {e[\event4].value;"event4".postln;}
		{num==68 && val==127} {e[\event5].value;"event5".postln;}
		{num==69 && val==127} {e[\oneshot1].value;"oneshot1".postln;}
		{num==70 && val==127} {e[\oneshot2].value;"oneshot2".postln;}
		{num==71 && val==127} {e[\oneshot3].value;"oneshot3".postln;}
		{true} {nil};
	});
};

//4. register functions with ServerBoot/Quit/Tree
Buffer.freeAll;
ServerBoot.add(~makeBuffers);
ServerBoot.add(~makeBusses);
ServerBoot.add(~makePatterns);
ServerBoot.add(~initActiveSounds);
ServerQuit.add(~cleanup);

//5. boot server
s.waitForBoot({

	s.sync;

	//6a. SynthDefs
	SynthDef(\bpfsaw, {
		arg atk=2, sus=0, rel=3, c1=1, c2=(-1),
		freq=500, detune=0.2, pan=0, cfhzmin=0.1, cfhzmax=0.3,
		cfmin=500, cfmax=2000, rqmin=0.1, rqmax=0.2,
		lsf=200, ldb=0, amp=1, out=0;
		var sig, env;
		env = EnvGen.kr(Env([0,1,1,0],[atk,sus,rel],[c1,0,c2]),doneAction:2);
		sig = Saw.ar(freq * {LFNoise1.kr(0.5,detune).midiratio}!2);
		sig = BPF.ar(
			sig,
			{LFNoise1.kr(
				LFNoise1.kr(4).exprange(cfhzmin,cfhzmax)
			).exprange(cfmin,cfmax)}!2,
			{LFNoise1.kr(0.1).exprange(rqmin,rqmax)}!2
		);
		sig = BLowShelf.ar(sig, lsf, 0.5, ldb);
		sig = Balance2.ar(sig[0], sig[1], pan);
		sig = sig * env * amp;
		Out.ar(out, sig);
	}).add;

	SynthDef(\bpfBufPlayer, {
		arg atk=0, sus=0, rel=3, c1=1, c2=(-1),
		buf=0, rate=1, sPos=0, freq=440, rq=1, bpfmix=0,
		pan=0, amp=1, out=0;
		var sig, env;
		env = EnvGen.kr(Env([0,1,1,0],[atk,sus,rel],[c1,0,c2]),doneAction:2);
		sig = PlayBuf.ar(1, buf, rate*BufRateScale.ir(buf),startPos:sPos);
		sig = XFade2.ar(sig, BPF.ar(sig, freq, rq, 1/rq.sqrt), bpfmix*2-1);
		sig = sig * env;
		sig = Pan2.ar(sig, pan, amp);
		Out.ar(out, sig);
	}).add;

	SynthDef(\reverb, {
		arg in, predelay=0.1, revtime=1.8,
		lpf=4500, mix=0.15, amp=1, out=0;
		var dry, wet, temp, sig;
		dry = In.ar(in,2);
		temp = In.ar(in,2);
		wet = 0;
		temp = DelayN.ar(temp, 0,2, predelay);
		16.do{
			temp = AllpassN.ar(temp, 0.05, {Rand(0.001,0.05)}!2, revtime);
			temp = LPF.ar(temp, lpf);
			wet = wet + temp;
		};
		sig = XFade2.ar(dry, wet, mix*2-1, amp);
		Out.ar(out, sig);
	}).add;


	// MY SINTHDEFS BELOW
	SynthDef(\bufPlayer, {
		arg atk=0.001, sus=0.2, rel=0.05,
		buf=0, rate=1, sPos=0,
		pan=0, amp=1, out=0;
		var env = Env( [0,1,1,0], [atk,sus,rel], [1,0,-1] ).kr(2);
		var framePos = sPos *  BufFrames.kr(buf);
		var sig = PlayBuf.ar(1, buf, rate * BufRateScale.kr(buf), startPos:framePos);
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


	Pbindef(\morphPlayer,
		\instrument, \bufPlayer,
		\buf, Pfunc({~soundToPlay[\buf]}) ,
		\atk, Pbrown(0.001, 3, 0.0125, inf),
		\sus, Pbrown(0.001, 1, 0.0125, inf),
		\rel, Pbrown(0.01, 0.5, 0.0125, inf),
		//\dur, 0.01, // expensive!!
		\dur, ( (Pkey(\atk) + Pkey(\sus) + Pkey(\rel)) * Pwhite(0.005, 0.02, inf) ),
		\sPos, Pfunc( { |evt|
			var noiseDev =  exprand(0.0001, 0.01);
			~cursorX + noiseDev } ),
		\rate, Pwrand([
			Pseq([1], 8),
			Pwrand([1,Pwhite(2.5,4,1),Pwhite(0.5,0.9,1)],[0.95,0.025,0.025],32),
			Pseq([2],8),
			Pseq([4],8)
		],[0.999,0.01,0.01, 0.01].normalizeSum,inf),
		\pan, Pdefn(\morphPanner),
		\prob, Pfunc({~soundToPlay[\prob]}),
		\amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf) * Pkey(\prob),
		\out, Pwrand( [~buses[\reverb0], ~buses[\reverb1]], [0.95,0.05], inf),
	);

	s.sync;


	//6b. register remaining functions
	ServerTree.add(~makeNodes);
	ServerTree.add(~makeEvents);
	~getCursorPosition.();
	~getActiveSound.play(t);
	s.freeAll;

	s.sync;

	"\n ----- DONE ------- \n".postln;
});
)
















/*---------------------------------------------------------------------
-----------------------------PERFORMANCE ----
---------------------------------------------------------------------*/


(
// ------  START ----
t.schedAbs(t.nextBar, {
	//~getActiveSound.play(t);
	Pbindef(\morphPlayer).play;
	//~tempoCounter.value;
});
)

~getActiveSound.stop
~getActiveSound.play

~soundToPlay
~activeSounds.size

(
// postcards
~activeSounds = List.new;
~sounds[\postcards].do({ |buf|
	~activeSounds.add((buf));
})
)


//spotlight:
(
~activeSounds = List.new;
~activeSounds.add(~findBufferByName.("spotlight1"));
//~activeSounds.add(~findBufferByName.("spotlight3"));
)

(
~activeSounds = List.new;
~activeSounds.add(~findBufferByName.("Burial - Fostercare (HQ)"));
//~activeSounds.add(~findBufferByName.("spotlight3"));
)


~activeSounds.size

~logSounds.(\songs)
~logSounds.(\samples)
~logSounds.(\movies)
~logSounds.(\favs)



// ---  MORPH PLAYER ---
Pbindef(\morphPlayer).play;
Pbindef(\morphPlayer).stop;

Pbindef(\morphPlayer, \amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf) * Pkey(\prob))
Pbindef(\morphPlayer, \amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf))

//pos
Pbindef(\morphPlayer, \sPos, Pdefn(\incrementally_0_to_1_millis_and_back).stutter(1));
Pbindef(\morphPlayer, \sPos, 0.1);
Pbindef(\morphPlayer, \sPos, 0.6);

//detune
Pbindef(\morphPlayer, \rate, Pseq([1, 2.midiratio], inf));
Pbindef(\morphPlayer, \rate, Pseq([3.midiratio], inf));
Pbindef(\morphPlayer, \rate, Pseq([7.midiratio], inf));
Pbindef(\morphPlayer, \rate, Pseq([0.midiratio ], inf));
Pbindef(\morphPlayer, \rate, Pseq([-2.midiratio], inf));
Pbindef(\morphPlayer, \rate, Pseq([-5.midiratio], inf));
Pbindef(\morphPlayer, \rate, Pseq([-7.midiratio], inf));
Pbindef(\morphPlayer, \rate, Pseq([-10.midiratio], inf));
Pbindef(\morphPlayer, \rate, Pseq([0.midiratio, -2.midiratio, -12.midiratio], inf));

//FX
Pbindef(\morphPlayer, \out, Pwrand( [~buses[\reverb0], ~buses[\reverb1], ~buses[\streson0]], [0.90 ,0.05, 0.05], inf));
Pbindef(\morphPlayer, \out, Pwrand( [~buses[\reverb0], ~buses[\reverb1], ~buses[\streson0]], [0.40 ,0.1, 0.50], inf));
Pbindef(\morphPlayer, \out, Pwrand( [~buses[\reverb0], ~buses[\reverb1], ~buses[\streson0], ~buses[\infiniteHoldReverb0]], [0.10 ,0.2, 0.2, 0.5], inf));

Pbindef(\morphPlayer, \out, Pwrand( [~buses[\reverb0], ~buses[\reverb1], ~buses[\streson0], ~buses[\infiniteHoldReverb0]], [0.10 ,0.2, 0.2, 0.05].normalizeSum, inf));
Pbindef(\morphPlayer, \out, ~buses[\infiniteHoldReverb0]);
Pbindef(\morphPlayer, \out, ~buses[\streson0]);


~streson0.set(\delaytime, Pdefn(\incrementally_0_to_1_millis_and_back) + 0.00001)
~streson0.set(\out, ~buses[\infiniteHoldReverb0]);



~infiniteHoldReverb0.set(\feedback, 0.49);
~infiniteHoldReverb0.set(\feedback, 0.50); //DANGER
~infiniteHoldReverb0.set(\feedback, 0.51); //DANGER



//
Pbindef(\morphPlayer, \dur, Pwrand([Pseq([1/8],8), Pseq([1/4],4), Pseq([1/2],2)] ,[0.95,0.03,0.02],inf) / Pseq( Array.geom(1000,1,1.004).mirror, inf)); //nice

Pbindef(\morphPlayer, \atk, Pbrown(0.001, 0.5, 0.0125, inf));
Pbindef(\morphPlayer, \sus, Pbrown(0.001, 0.5, 0.0125, inf));
Pbindef(\morphPlayer, \rel, Pbrown(0.01, 0.05, 0.0125, inf));

//slow attack, very careful, can overload!!!
Pbindef(\morphPlayer, \atk, 5);



//cursorX reset
Pbindef(\morphPlayer,\sPos, Pfunc( { |evt|
	var noiseDev =  exprand(0.0001, 0.01);
	~cursorX + noiseDev } ));

//cursorX tuning
Pbindef(\morphPlayer,\rate, Pfunc( { |evt|
	var cursorPos = ~cursorX.linlin(0,1,0,12).ceil.postln;
	cursorPos.midiratio;
} ));

~activeSounds.size


(
//nice dur
Pbindef(\morphPlayer,
		\atk, Pbrown(0.001, 3, 0.0125, inf),
		\sus, Pbrown(0.001, 1, 0.0125, inf),
		\rel, Pbrown(0.01, 0.5, 0.0125, inf),
	\dur, Pwhite(0.005, 0.02, inf) * ( Pkey(\atk) + Pkey(\sus) + Pkey(\rel))
);
)


Pbindef(\morphPlayer, \dur, Pseq([0.1], inf));


Pbindef(\morphPlayer, \atk, Pbrown(0.001, 0.05, 0.0125, inf));
Pbindef(\morphPlayer, \atk, Pbrown(0.1, 5, 0.0125, inf));
Pbindef(\morphPlayer, \sus, Pbrown(0.001, 0.05, 0.0125, inf));
Pbindef(\morphPlayer, \rel, Pbrown(0.01, 0.05, 0.0125, inf));
Pbindef(\morphPlayer, \dur, Pwrand([Pseq([1/8],8), Pseq([1/4],4), Pseq([1/2],2)] ,[0.95,0.03,0.02],inf) / Pseq( Array.geom(1000,1,1.004).mirror, inf)); //nice








0.midiratio
0.25.midiratio
0.5.midiratio
1.midiratio
6.midiratio


s.record
s.stopRecording



t.beatsPerBar




t.tempo * 4


/*---------------------------------------------------------------------
----------------------------- SUPER NICE IDEAS  ----
---------------------------------------------------------------------*/


BandSplitter2
BandSplitter4


//record to loop
File.getcwd
var recordfolderPath = thisProcess.nowExecutingPath.dirname ++ "/records" ;

