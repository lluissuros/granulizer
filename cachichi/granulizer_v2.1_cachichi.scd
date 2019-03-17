
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
	~buses.add(\infiniteHoldReverb0 -> Bus.audio(s, 2));
	~buses.add(\reverb0 -> Bus.audio(s, 2));
	~buses.add(\reverb1 -> Bus.audio(s, 2));
	~buses.add(\streson0 -> Bus.audio(s, 2));
};


~getCursorPosition =  SkipJack({ defer {
	~cursorX = QtGUI.cursorPosition.x / Window.screenBounds.extent.x;
	~cursorY = QtGUI.cursorPosition.y / Window.screenBounds.extent.y;
} }, 0.1);


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

	SynthDef(\bufPlayerMultiChan, {
		arg atk=0.001, sus=0.2, rel=0.05,
		buf=0, rate=1, sPos=0,
		pan=0, amp=1, out=0;
		var env = Env( [0,1,1,0], [atk,sus,rel], [1,0,-1] ).kr(2);
		var framePos = sPos *  BufFrames.kr(buf);
		var sig = PlayBuf.ar(1, buf, rate * BufRateScale.kr(buf), startPos:framePos);
		sig = sig * env;
		Out.ar(out, PanAz.ar(4, Mix.ar(sig*amp), pan) );
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
		\amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf) * Pkey(\prob),
		\out, Pwrand( [~buses[\reverb0], ~buses[\reverb1]], [0.95,0.05], inf),
	);


	Pbindef(\morphAround,
		\instrument, \bufPlayerMultiChan,
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
		\pan, Pdefn(\morphPanner),
		\prob, Pfunc({~soundToPlay[\prob]}),
		\amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf) * Pkey(\prob),
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
Pbindef(\morphFront, \out, Pwrand( [~buses[\

	0], ~buses[\reverb1], ~buses[\streson0]], [0.90 ,0.05, 0.05], inf));
Pbindef(\morphFront, \out, Pwrand( [~buses[\reverb0], ~buses[\reverb1], ~buses[\streson0]], [0.40 ,0.1, 0.50], inf));
Pbindef(\morphFront, \out, Pwrand( [~buses[\reverb0], ~buses[\reverb1], ~buses[\streson0], ~buses[\infiniteHoldReverb0]], [0.10 ,0.2, 0.2, 0.5], inf));

Pbindef(\morphFront, \out, Pwrand( [~buses[\reverb0], ~buses[\reverb1], ~buses[\streson0], ~buses[\infiniteHoldReverb0]], [0.10 ,0.2, 0.2, 0.05].normalizeSum, inf));
Pbindef(\morphFront, \out, ~buses[\infiniteHoldReverb0]);
Pbindef(\morphFront, \out, ~buses[\streson0]);


~streson0.set(\delaytime, Pdefn(\incrementally_0_to_1_millis_and_back) + 0.00001)
~streson0.set(\out, ~buses[\infiniteHoldReverb0]);


~infiniteHoldReverb0.set(\feedback, 0.3);
~infiniteHoldReverb0.set(\feedback, 0.49);
~infiniteHoldReverb0.set(\feedback, 0.50); //DANGER
~infiniteHoldReverb0.set(\feedback, 0.51); //DANGER



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
//MULTICHANNEL:  \morphAround
//--------------------------------------------------------
//--------------------------------------------------------

Pbindef(\morphAround).play;
Pbindef(\morphAround).stop;


Pbindef(\morphAround, \amp, Pseq( [0.01],inf))//quite low
Pbindef(\morphAround, \amp, Pseq( [Pexprand(0.1,0.35,1), Pexprand(0.001,0.09,3)],inf) * Pkey(\prob) / 4) //less amp



Pbindef(\morphAround, \sPos, Pdefn(\incrementally_0_to_1_millis_and_back).stutter(1));


Pbindef(\morphAround, \instrument, \bufPlayerMultiChan);
Pbindef(\morphAround, \pan, Prand(Array.series(21, -1, 0.1) ,inf));
Pbindef(\morphAround, \out, Pseq([0] ,inf));


//sPos
(
~callPreset.(1);
Pbindef(\morphAround,\sPos, Pseq([0.35, 0.7].stutter(100)), inf);
)

//pos
(
Pbindef(\morphFront, \sPos, Pdefn(\incrementally_0_to_1_millis_and_back).stutter(1));
Pbindef(\morphAround, \sPos, Pdefn(\incrementally_0_to_1_millis_and_back).stutter(1));
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

Pbindef(\morphAround).play
Pbindef(\morphAround).stop




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
~removeActiveSoundAt.(4);


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
~probCycleDurSeconds = 10
~probCycleDurSeconds = 20
~probCycleDurSeconds = 40





s.record()
s.stopRecording








