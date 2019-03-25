
/*
This is a version for 44Perills.
 Some unused stuff is deleted.
some multichannel is added.
*/


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



s.options.numOutputBusChannels_(8);

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
//~initActiveSounds.();


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
	~buses.add(\infiniteReverbPA -> Bus.audio(s, 2));
	~buses.add(\infiniteReverbVib -> Bus.audio(s, 3)); //vibs
	~buses.add(\infiniteReverbSurr -> Bus.audio(s, 3)); //extra surr

	~buses.add(\reverb0PA -> Bus.audio(s, 2));
	~buses.add(\reverb0Vib -> Bus.audio(s, 3)); //vibs
	~buses.add(\reverb0Surr -> Bus.audio(s, 3)); //extra surr

	~buses.add(\reverb1PA -> Bus.audio(s, 2));
	~buses.add(\reverb1Vib -> Bus.audio(s, 3)); //vibs
	~buses.add(\reverb1Surr -> Bus.audio(s, 3)); //extra surr

	~buses.add(\stresonPA -> Bus.audio(s, 2));
	~buses.add(\stresonVib -> Bus.audio(s, 3)); //vibs
	~buses.add(\stresonSurr -> Bus.audio(s, 3)); //extra surr

};


~getCursorPosition =  SkipJack({ defer {
	~cursorX = QtGUI.cursorPosition.x / Window.screenBounds.extent.x;
	~cursorY = QtGUI.cursorPosition.y / Window.screenBounds.extent.y;
} }, 0.1);


//sound combination presets:
~buildPresets = {
	//values must be Lists
	"building presets... ".postln;
	~presetsDict = ();
	~presetsDict.put(1, ~sounds[\postcards].collect({ |buf| ~getBufFileName.(buf)}));
	~presetsDict.put(2, ["spot1", "silence", "spot3"]);
	~presetsDict.put(3, [ "spot4", "spot3", "spot4", "silence" ]);
	~presetsDict.put(4, [ "spot1", "entryGosh", "feedbackchords", "arpegio1_filtered_lowered"]);
	~presetsDict.put(5, [ "entryGosh", "spot6", "silence" ]);
	~presetsDict.put(6, [ "spot1", "entryGosh", "feedbackchords", "arpegio1_filtered_lowered" ]);
	~presetsDict.put(7, ~sounds[\jazz_c].collect({ |buf| ~getBufFileName.(buf)}));
};

~buildPresets.();

~callPreset = {|presetKey|
	~activeSounds = List.new;
	~presetsDict.at(presetKey).do({ |sound|
		~activeSounds.add((~findBufferByName.(sound)));
	});
	~logActiveSounds.();
};


~initActiveSounds = {
	~callPreset.(1);
};




// ===
//output FXs presets:
// ===
~logMapOut = {
	"\n____~mapOut Presets:___ ".postln;
	~mapOut.keys.do(_.postln);
};

~buildMapOutPreset = {
	"building out presets, function list  ".postln;
	~mapOut = ~mapOut ? ();
	~mapOut[\allClean] = {
		Pbindef(\morphFront, \out, 0);
		Pbindef(\morphAzVib, \out, 2);
		Pbindef(\morphAzSurr,\out, 5);
	};

	~mapOut[\allInfiniteReverb] = {
		Pbindef(\morphFront, \out, ~buses[\infiniteReverbPA]);
		Pbindef(\morphAzVib, \out, ~buses[\infiniteReverbVib]);
		Pbindef(\morphAzSurr, \out, ~buses[\infiniteReverbSurr]);
	};

	~mapOut[\allReverb0] = {
		Pbindef(\morphFront, \out, ~buses[\reverb0PA]);
		Pbindef(\morphAzVib, \out, ~buses[\reverb0Vib]);
		Pbindef(\morphAzSurr, \out, ~buses[\reverb0Surr]);
	};

	~mapOut[\allReverb1] = {
		Pbindef(\morphFront, \out, ~buses[\reverb1PA]);
		Pbindef(\morphAzVib, \out, ~buses[\reverb1Vib]);
		Pbindef(\morphAzSurr, \out, ~buses[\reverb1Surr]);
	};

	~mapOut[\allStreson] = {
		Pbindef(\morphFront, \out, ~buses[\stresonPA]);
		Pbindef(\morphAzVib, \out, ~buses[\stresonVib]);
		Pbindef(\morphAzSurr, \out, ~buses[\stresonSurr]);
	};

	~logMapOut.()
};

~buildMapOutPreset.();






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

		"Creating Groups and FXs....".postln;

		~stresonPA = Synth(\streson_st, [\in, ~buses[\stresonPA], \out, ~buses[\reverb0PA], \mix, 1], ~fxGrp);
		~stresonVib = Synth(\streson_3chan, [\in, ~buses[\stresonVib], \out, ~buses[\reverb0Vib], \mix, 1], ~fxGrp);
		~stresonSurr = Synth(\streson_3chan, [\in, ~buses[\stresonSurr], \out, ~buses[\reverb0Surr], \mix, 1], ~fxGrp);


		~infiniteHoldReverbPA =  Synth(\infiniteHoldReverb_st, [\in, ~buses[\infiniteReverbPA], \out, 0, \mix, 0.5, \feedback, 0.45], ~reverbGrp);
		~infiniteHoldReverbVib =  Synth(\infiniteHoldReverb_3chan, [\in, ~buses[\infiniteReverbVib], \out, 2, \mix, 0.5, \feedback, 0.45], ~reverbGrp);
		~infiniteHoldReverbSurr =  Synth(\infiniteHoldReverb_3chan, [\in, ~buses[\infiniteReverbSurr], \out, 5, \mix, 0.5, \feedback, 0.45], ~reverbGrp);


		~reverb0PA = Synth(\reverb_st,[\in, ~buses[\reverb0PA], \out, 0, \mix, 0.025], ~reverbGrp);
		~reverb0Vib = Synth(\reverb_3chan,[\in, ~buses[\reverb0Vib], \out, 2, \mix, 0.025], ~reverbGrp);
		~reverb0Surr = Synth(\reverb_3chan,[\in, ~buses[\reverb0Surr], \out, 5, \mix, 0.025], ~reverbGrp);


		~reverb1PA = Synth(\reverb_st,[\in, ~buses[\reverb1PA], \out, 0, \mix, 0.3],~reverbGrp);
		~reverb1Vib = Synth(\reverb_3chan,[\in, ~buses[\reverb1Vib], \out, 2, \mix, 0.3],~reverbGrp);
		~reverb1Surr = Synth(\reverb_3chan,[\in, ~buses[\reverb1Surr], \out, 5, \mix, 0.3],~reverbGrp);
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
		~probCycleDurSeconds = (0.1).max(~probCycleDurSeconds);
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
		~probCycleDurSeconds = (0.01).max(~probCycleDurSeconds);
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


~getFolderSoundNames = {
	arg folderName;
	~sounds[folderName.asSymbol].collect({ |buf| ~getBufFileName.(buf)});
};

~getAllSoundNames = {
	var allNames = List.new();
	var subfoldersContents =  ~sounds.values;
	var folders = ~sounds.keys.as(Array);
	folders.do({|folder|
		var folderItems = ~getFolderSoundNames.(folder.asSymbol);
		folderItems.do({ |name|
			allNames.add(name);
		});
	});
	allNames;
};

~doesNameExist = {|fileName|
	~getAllSoundNames.().any({ |item| item.asSymbol === fileName.asSymbol });
};

~logFolderSounds = {
	arg folderName;
	var names = ~getFolderSoundNames.(folderName.asSymbol);
	names.do({ |name| name.postln });
};

~logAllSounds = {
	~getAllSoundNames.().do({|name| name.postln});
};

~logActiveSounds = {
	"\n____ActiveSounds:___ ".postln;
	~activeSounds.collect({|sound| ~getBufFileName.(sound).postln})
};

~removeActiveSound = {
	arg fileName;
	var indexToRemove = ~activeSounds.detectIndex({|buf| ~getBufFileName.(buf) == fileName });
	var newActiveSounds = ~activeSounds.reject({ |buf, index| index ==  indexToRemove});
	~activeSounds = newActiveSounds.asList;
	~logActiveSounds.();
};

~removeActiveSoundAt = {
	arg indexToRemove;
	var newActiveSounds = ~activeSounds.reject({ |buf, index| index ==  indexToRemove});
	~activeSounds = newActiveSounds.asList;
	~logActiveSounds.();
};


~addActiveSound = {
	arg fileName;
	if(~doesNameExist.(fileName)){
		~activeSounds.add(~findBufferByName.(fileName));
		~logActiveSounds.();
	}{"filename not found".postln}
};


~addActiveSoundAt= {
	arg index, fileName;
	if(~doesNameExist.(fileName)){
		var buffer = ~findBufferByName.(fileName);
		~activeSounds.insert(index, buffer);
		~logActiveSounds.();
	}{"filename not found".postln}
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
	"\n~makeEvents is deleted in this version!!!\n".postln;
	t = TempoClock(80/60).permanent_(true);
	~tempoCounter = {
		("Temps: "+ (t.beatInBar + 1)).postln;
		("Compas: "+ t.bar).postln;
		[t.beatsPerBar + ("/4"), t.tempo * 60 ].postln;
		"\n \n".postln;
		1;
	};
};

//4. register functions with ServerBoot/Quit/Tree
Buffer.freeAll;
ServerBoot.add(~makeBuffers);
ServerBoot.add(~makeBusses);
ServerBoot.add(~makePatterns);
ServerBoot.add(~buildPresets);
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

	SynthDef(\bufPlayerMultiChan_3, {
		arg atk=0.001, sus=0.2, rel=0.05,
		buf=0, rate=1, sPos=0,
		pan=0, amp=1, out=0;
		var env = Env( [0,1,1,0], [atk,sus,rel], [1,0,-1] ).kr(2);
		var framePos = sPos *  BufFrames.kr(buf);
		var sig = PlayBuf.ar(1, buf, rate * BufRateScale.kr(buf), startPos:framePos);
		sig = sig * env;
		Out.ar(out, PanAz.ar(3, Mix.ar(sig*amp), pan) );
	}).add;

	SynthDef(\reverb_st, {
		arg in=20, out=0, amp=1, mix=0.05, freqF=4000, decay=2.5, delay=0.05;
		var sig, wet, dry;
		dry = In.ar(in, 2);
		wet = dry;
		wet = DelayN.ar(wet, delay, delay);
		20.do{wet = AllpassN.ar(wet, 0.05,{Rand(0.001,0.05)}!2, decay); wet = LPF.ar(wet,freqF);};
		sig = XFade2.ar(dry, wet, mix*2-1, amp);
		Out.ar(out, sig);
	}).add;

	SynthDef(\reverb_3chan, {
		arg in=20, amp=1, mix=0.05, freqF=4000, decay=2.5, delay=0.05, out=2;
		var sig, wet, dry;
		dry = In.ar(in, 3);
		wet = dry;
		wet = DelayN.ar(wet, delay, delay);
		20.do{wet = AllpassN.ar(wet, 0.05,{Rand(0.001,0.05)}!2, decay); wet = LPF.ar(wet,freqF);};
		sig = XFade2.ar(dry, wet, mix*2-1, amp);
		Out.ar(out, sig);
	}).add;

	SynthDef(\streson_st, {
		arg in, res=0.9, amp=0.3, delaytime=0.0083, out=0, mix=1;
		var dry = In.ar(in,2);
		var wet = Streson.ar(
			dry,
			delaytime + LFNoise2.ar(2).range(0.0001, 0.001), // provisional
			res,
			amp);
		var sig = XFade2.ar(dry, wet, 1*2-1);
		Out.ar(out, sig);
	}).add;

	SynthDef(\streson_3chan, {
		arg in, res=0.9, amp=0.3, delaytime=0.0083, out=2, mix=1;
		var dry = In.ar(in,3);
		var wet = Streson.ar(
			dry,
			delaytime + LFNoise2.ar(2).range(0.0001, 0.001), // provisional
			res,
			amp);
		var sig = XFade2.ar(dry, wet, 1*2-1);
		Out.ar(out, sig);
	}).add;

	SynthDef(\infiniteHoldReverb_st, {
		arg in, feedback = 0.3, gateThreshold = 0.02, amp=0.5, mix=1, out=0;
		//input signal
		var dry =  In.ar(in,2);
		var inAmp = Amplitude.kr(Mix.ar(dry));
		var gatedSig = dry * (inAmp > gateThreshold);
		var local = (LocalIn.ar(2) + gatedSig.dup);

		//apply reverb
		var sig = (0..14).inject(local, AllpassL.ar( _ ,0.06, Rand(0.01, 0.06), 3));

		//complete feedback loop - send audio back to LoopIn
		sig = LeakDC.ar(sig);
		LocalOut.ar(sig * feedback);

		//non-feedback output to speakers.
		sig = Limiter.ar(sig);
		sig = XFade2.ar(dry, sig, mix*2-1, amp).softclip;
		Out.ar(out, sig);
	}).add;


	SynthDef(\infiniteHoldReverb_3chan, {
		arg in, feedback = 0.3, gateThreshold = 0.03, amp=0.5, mix=1, out=2;
		//input signal
		var dry =  In.ar(in,3);
		var inAmp = Amplitude.kr(Mix.ar(dry));
		var gatedSig = Mix.ar(dry) * (inAmp > gateThreshold);
		var local = (LocalIn.ar(3) + gatedSig.dup(3));

		//apply reverb
		var sig = (0..14).inject(local, AllpassL.ar( _ ,0.06, Rand(0.01, 0.06), 3));

		//complete feedback loop - send audio back to LoopIn
		sig = LeakDC.ar(sig);
		LocalOut.ar(sig.scramble * feedback);

		//non-feedback output to speakers.
		sig = Limiter.ar(sig);
		sig = XFade2.ar(dry, sig, mix*2-1, amp).softclip;

		// -1 to +1 is used to modulate the pan along circle.
		Out.ar(out, sig);
	}).add;



	s.sync;




	Pbindef(\morphFront,
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
		\amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf) * Pkey(\prob) /9, //quite low,
		\out, Pwrand( [~buses[\reverb0PA], ~buses[\reverb1PA]], [0.95,0.05], inf),
	);


	Pbindef(\morphAzVib,
		\instrument, \bufPlayerMultiChan_3,
		\out, Pseq([2], inf),
		\buf, Pfunc({~soundToPlay[\buf]}),
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
//		\pan, Pdefn(\morphPanner),
		\pan, Pseq((-10..10)*0.1, inf),
		\prob, Pfunc({~soundToPlay[\prob]}),
		\amp, Pseq([Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf) * Pkey(\prob)/4,
	);



	Pbindef(\morphAzSurr,
		\instrument, \bufPlayerMultiChan_3,
		\out, Pseq([5], inf),
		\buf, Pfunc({~soundToPlay[\buf]}),
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
//		\pan, Pdefn(\morphPanner),
		\pan, Pseq((-10..10)*0.1, inf),
		\prob, Pfunc({~soundToPlay[\prob]}),
		\amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf) * Pkey(\prob) /9,
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




//--------------------------------------------------------
// ---  MORPH PLAYER ---
//--------------------------------------------------------

Pbindef(\morphFront).play;
Pbindef(\morphFront).stop;
Pbindef(\morphFront, \sPos, Pdefn(\incrementally_0_to_1_millis_and_back).stutter(1));



Pbindef(\morphFront, \amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf) * Pkey(\prob))
Pbindef(\morphFront, \amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf))
Pbindef(\morphFront, \amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf) * Pkey(\prob) /4) //less amp

//pos
Pbindef(\morphFront, \sPos, Pdefn(\incrementally_0_to_1_millis_and_back).stutter(1));
Pbindef(\morphFront, \sPos, 0.1);
Pbindef(\morphFront, \sPos, 0.6);

//detune
Pbindef(\morphFront, \rate, Pseq([1, 2.midiratio], inf));
Pbindef(\morphFront, \rate, Pseq([3.midiratio], inf));
Pbindef(\morphFront, \rate, Pseq([7.midiratio], inf));
Pbindef(\morphFront, \rate, Pseq([0.midiratio ], inf));
Pbindef(\morphFront, \rate, Pseq([-2.midiratio], inf));
Pbindef(\morphFront, \rate, Pseq([-5.midiratio], inf));
Pbindef(\morphFront, \rate, Pseq([-7.midiratio], inf));
Pbindef(\morphFront, \rate, Pseq([-10.midiratio], inf));
Pbindef(\morphFront, \rate, Pseq([0.midiratio, -2.midiratio, -12.midiratio], inf));

//FX
Pbindef(\morphFront, \out, Pwrand( [~buses[\reverb1PA], ~buses[\stresonPA]], [0.90 ,0.05, 0.05], inf));
Pbindef(\morphFront, \out, Pwrand( [~buses[\reverb0PA], ~buses[\reverb1PA], ~buses[\stresonPA]], [0.40 ,0.1, 0.50], inf));
Pbindef(\morphFront, \out, Pwrand( [~buses[\reverb0PA], ~buses[\reverb1PA], ~buses[\stresonPA], ~buses[\infiniteReverbPA]], [0.10 ,0.2, 0.2, 0.5], inf));

Pbindef(\morphFront, \out, Pwrand( [~buses[\reverb0PA], ~buses[\reverb1PA], ~buses[\stresonPA], ~buses[\infiniteReverbPA]], [0.10 ,0.2, 0.2, 0.05].normalizeSum, inf));
Pbindef(\morphFront, \out, ~buses[\infiniteReverbPA]);
Pbindef(\morphFront, \out, ~buses[\stresonPA]);


~stresonPA.set(\delaytime, Pdefn(\incrementally_0_to_1_millis_and_back) + 0.00001)
~stresonPA.set(\out, ~buses[\infiniteReverbPA]);


~infiniteHoldReverbPA.set(\feedback, 0.3);
~infiniteHoldReverbPA.set(\feedback, 0.49);
~infiniteHoldReverbPA.set(\feedback, 0.50); //DANGER
~infiniteHoldReverbPA.set(\feedback, 0.51); //DANGER



//
Pbindef(\morphFront, \dur, Pwrand([Pseq([1/8],8), Pseq([1/4],4), Pseq([1/2],2)] ,[0.95,0.03,0.02],inf) / Pseq( Array.geom(1000,1,1.004).mirror, inf)); //nice

Pbindef(\morphFront, \atk, Pbrown(0.001, 0.5, 0.0125, inf));
Pbindef(\morphFront, \sus, Pbrown(0.001, 0.5, 0.0125, inf));
Pbindef(\morphFront, \rel, Pbrown(0.01, 0.05, 0.0125, inf));

//slow attack, very careful, can overload!!!
Pbindef(\morphFront, \atk, 5);



//cursorX reset
Pbindef(\morphFront,\sPos, Pfunc( { |evt|
	var noiseDev =  exprand(0.0001, 0.01);
	~cursorX + noiseDev } ).trace);

//cursorX tuning
Pbindef(\morphFront,\rate, Pfunc( { |evt|
	var cursorPos = ~cursorX.linlin(0,1,0,12).ceil.postln;
	cursorPos.midiratio;
} ));

~activeSounds.size


(
//nice dur
Pbindef(\morphFront,
		\atk, Pbrown(0.001, 3, 0.0125, inf),
		\sus, Pbrown(0.001, 1, 0.0125, inf),
		\rel, Pbrown(0.01, 0.5, 0.0125, inf),
	\dur, Pwhite(0.005, 0.02, inf) * ( Pkey(\atk) + Pkey(\sus) + Pkey(\rel))
);
)


Pbindef(\morphFront, \dur, Pseq([0.1], inf));


Pbindef(\morphFront, \atk, Pbrown(0.001, 0.05, 0.0125, inf));
Pbindef(\morphFront, \atk, Pbrown(0.1, 5, 0.0125, inf));
Pbindef(\morphFront, \sus, Pbrown(0.001, 0.05, 0.0125, inf));
Pbindef(\morphFront, \rel, Pbrown(0.01, 0.05, 0.0125, inf));
Pbindef(\morphFront, \dur, Pwrand([Pseq([1/8],8), Pseq([1/4],4), Pseq([1/2],2)] ,[0.95,0.03,0.02],inf) / Pseq( Array.geom(1000,1,1.004).mirror, inf)); //nice





//--------------------------------------------------------
//--------------------------------------------------------
//MULTICHANNEL:  \morphAzVib
//--------------------------------------------------------
//--------------------------------------------------------

Pbindef(\morphAzVib).play;
Pbindef(\morphAzVib).stop;


Pbindef(\morphAzVib, \amp, Pseq( [0.01],inf))//quite low
Pbindef(\morphAzVib, \amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf) * Pkey(\prob) / 4) //less amp



Pbindef(\morphAzVib, \sPos, Pdefn(\incrementally_0_to_1_millis_and_back).stutter(1));


Pbindef(\morphAzVib, \instrument, \bufPlayerMultiChan_3);
Pbindef(\morphAzVib, \pan, Prand(Array.series(21, -1, 0.1) ,inf));
Pbindef(\morphAzVib, \out, Pseq([0] ,inf));


//sPos
(
~callPreset.(1);
Pbindef(\morphAzVib,\sPos, Pseq([0.35, 0.7].stutter(100)), inf);
)

//pos
(
Pbindef(\morphFront, \sPos, Pdefn(\incrementally_0_to_1_millis_and_back).stutter(1));
Pbindef(\morphAzVib, \sPos, Pdefn(\incrementally_0_to_1_millis_and_back).stutter(1));
Pbindef(\morphAzSurr, \sPos, Pdefn(\incrementally_0_to_1_millis_and_back).stutter(1));
)
Pbindef(\morphFront, \sPos, 0.1);
Pbindef(\morphFront, \sPos, 0.6);

(
//cursorX reset
Pbindef(\morphFront,\sPos, Pfunc( { |evt|
	var noiseDev =  exprand(0.0001, 0.01);
	~cursorX + noiseDev } ).trace);
)




Pbindef(\morphFront).play
Pbindef(\morphFront).stop

Pbindef(\morphAzVib).play
Pbindef(\morphAzVib).stop




//log
~logActiveSounds.();
~logAllSounds.();
~logSounds.(\songs)
~logSounds.(\spotlight)
~logSounds.(\samples)
~logSounds.(\movies)
~logSounds.(\favs)




//activeSounds
~removeActiveSound.("chords_organ2");
~removeActiveSoundAt.(0);
~removeActiveSoundAt.(1);
~removeActiveSoundAt.(2);
~removeActiveSoundAt.(3);
~removeActiveSoundAt.(3);
~removeActiveSoundAt.(4);
~removeActiveSoundAt.(5);


~addActiveSound.("silence");
~addActiveSound.("feedbackchords");
~addActiveSound.("entryGosh");


~addActiveSoundAt.(4, "spot1");
~addActiveSoundAt.(4, "spot3");
~addActiveSoundAt.(4, "spot4");
~addActiveSoundAt.(4, "spot5");
~addActiveSoundAt.(4, "spot6");
~addActiveSoundAt.(4, "spot7");
~addActiveSoundAt.(4, "shakerSustain");
~addActiveSoundAt.(4, "glaçat");
~addActiveSoundAt.(4, "arpegio1_filtered_lowered");



//presets!
~callPreset.(1)
~callPreset.(2)
~callPreset.(3)
~callPreset.(4)
~callPreset.(5)
~callPreset.(6)
~callPreset.(7)

~logActiveSounds.();

~probCycleDurSeconds = 0.1
~probCycleDurSeconds = 1
~probCycleDurSeconds = 10
~probCycleDurSeconds = 15
~probCycleDurSeconds = 20
~probCycleDurSeconds = 40





s.record()
s.stopRecording





// test test test test test test test test test test test test test test
// FXs map out
//test test test test test test test test test test test test test test



(
Pbindef(\morphFront).play
Pbindef(\morphAzVib).play
Pbindef(\morphAzSurr).play
)

//prefer decrease amp
Pbindef(\morphFront).stop
Pbindef(\morphAzVib).stop
Pbindef(\morphAzSurr).stop


~logMapOut.();


~mapOut[\allClean].();
~mapOut[\allInfiniteReverb].();
~mapOut[\allReverb1].();
~mapOut[\allReverb0].();
~mapOut[\allStreson].();


~stresonPA.set(\delaytime, Pdefn(\incrementally_0_to_1_millis_and_back) + 0.00001);
~stresonPA.set(\out, ~buses[\infiniteReverbPA]);
~stresonPA.set(\out, ~buses[\allReverb1]);



(
~infiniteHoldReverbPA.set(\feedback, 0.3);
~infiniteHoldReverbVib.set(\feedback, 0.3);
~infiniteHoldReverbSurr.set(\feedback, 0.3);
)
(
~infiniteHoldReverbPA.set(\feedback, 0.45);
~infiniteHoldReverbVib.set(\feedback, 0.45);
~infiniteHoldReverbSurr.set(\feedback, 0.45);
)
~infiniteHoldReverbPA.set(\feedback, 0.47);
~infiniteHoldReverbPA.set(\feedback, 0.49);



(
~stresonUpRand.stop;
~stresonUpRand = Task({
	"start".postln;
	20000.do({|i|
		var waitTimes = [1,2,5,10];
		var delayTime = i.rand * 0.0001;

		//\streson_3chan
		~stresonPA.set(\delaytime, delayTime);
		waitTimes.choose.wait;
    });
});
)

~stresonUpRand.start;
~stresonUpRand.pause;
~stresonUpRand.resume;
~stresonUpRand.reset;
~stresonUpRand.stop;


(
~changeMapOut1.stop;
~changeMapOut1 = Task({
	"start".postln;
	20000.do({|i|
		var waitTimes = [1,2,5,10];


		var func = [
			~mapOut[\allClean],
			~mapOut[\allInfiniteReverb],
			~mapOut[\allReverb1],
			~mapOut[\allReverb0],
			//~mapOut[\allStreson]
		].choose;
		//weighted?

		i.postln;

		func.();

		waitTimes.choose.wait;
    });
});
)

~changeMapOut1.start;
~changeMapOut1.pause;
~changeMapOut1.resume;
~changeMapOut1.reset;
~changeMapOut1.stop;







//amp

Pbindef(\morphFront, \amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf) * Pkey(\prob) / 90) //less amp
Pbindef(\morphAzVib, \amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf) * Pkey(\prob) / 90) //less amp
Pbindef(\morphAzSurr, \amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf) * Pkey(\prob) / 99) //less amp


Pbindef(\morphFront).play
Pbindef(\morphAzSurr).play
