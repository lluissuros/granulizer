/*DONES:
BUG: --> el navegador de sounds no va bé
BUG: circle pan broken
OK --> Bug: MouseY ml ajustat
TODO: -grainDur ha de tenir el centre sobre el 2


TODOS:
SAM: passar codi arp1 simplificat
-more panning modes besides circle --> i don't need the knob for pan
-mes truquis 4-chan
-passar arp1 filtered a 4-chan per poderho tocar


*/

(
s = Server.local;
//s.options.numOutputBusChannels = 4;
s.options.numOutputBusChannels = 2;
o = Server.internal.options;
o.memSize = 2 ** 19;
p = ProxySpace.push(s);
p.fadeTime = 0;
s.boot;
)

s.recChannels_(4); // or whatever number of channels
s.record;
s.stopRecording;

//LOADING AND SETUP
(
var soundsRelativePath = thisProcess.nowExecutingPath.dirname +/+ "Sounds/";
var samplesRelativePath = thisProcess.nowExecutingPath.dirname +/+ "Samples/";

b = b ? (); //buffers object
b.soundsIndex = 0;
b.discardButton = true; //workaround because button is called two times
b.sounds = ();
b.samples =();
//GrainBuf needs a mono source bufnum
b.sounds.pater = Buffer.read(s, soundsRelativePath ++ "pater_noe.aif",channels:[0]).bufnum;
b.sounds.arp1Filter =  Buffer.readChannel(s,soundsRelativePath ++ "nechaev - arpegio1_filtered_lowered.wav" ,channels:[0]).bufnum;
b.sounds.arp1 = Buffer.readChannel(s,soundsRelativePath ++ "nechaev - arpegio1_19_07_lowered.wav", channels:[0]).bufnum;
b.sounds.allegro1 = Buffer.readChannel(s,soundsRelativePath ++ "nechaev - allegro1_8_11_2013.wav", channels:[0]).bufnum;
b.sounds.ensQuedem = Buffer.readChannel(s,soundsRelativePath ++ "nechaev - ens quedem 7_07.wav", channels:[0]).bufnum;
b.sounds.feedbackChords = Buffer.readChannel(s,soundsRelativePath ++ "nechaev - feedbackchords.wav", channels:[0]).bufnum;
b.sounds.quePortes = Buffer.readChannel(s,soundsRelativePath ++ "nechaev - que portes 22_11_2015_SHORT.wav", channels:[0]).bufnum;
b.sounds.glacat = Buffer.readChannel(s, soundsRelativePath ++ "nechaev - glaçat mastered.wav", channels:[0]).bufnum;
b.sounds.noPuedeSer = Buffer.readChannel(s, soundsRelativePath ++ "nechaev - no puede ser.wav", channels:[0]).bufnum;
b.sounds.entryGosh = Buffer.readChannel(s, soundsRelativePath ++ "entryGosh.wav", channels:[0]).bufnum;
b.sounds.entryGoshClick = Buffer.readChannel(s, soundsRelativePath ++ "entryGosh_click.wav", channels:[0]).bufnum;
b.sounds.entryGoshWahWah = Buffer.readChannel(s, soundsRelativePath ++ "entryGosh_wahwah.wav", channels:[0]).bufnum;
b.sounds.fratresIntro= Buffer.readChannel(s,soundsRelativePath ++ "fratres intro.wav", channels:[0]).bufnum;
b.sounds.fratres= Buffer.readChannel(s,soundsRelativePath ++ "Arvo Part - Fratres For Cello And Piano.wav", channels:[0]).bufnum;
b.sounds.fostercare= Buffer.readChannel(s,soundsRelativePath ++ "Burial - Fostercare (HQ).wav", channels:[0]).bufnum;
b.sounds.miserere= Buffer.readChannel(s,soundsRelativePath ++ "Gregorio Allegri- Miserere.wav", channels:[0]).bufnum;
b.sounds.klavierwerke= Buffer.readChannel(s, soundsRelativePath ++ "James Blake - Klavierwerke.wav", channels:[0]).bufnum;
b.sounds.drumming= Buffer.readChannel(s, soundsRelativePath ++ "Steve Reich - Part IV - Drumming.wav", channels:[0]).bufnum;
b.sounds.funeral= Buffer.readChannel(s, soundsRelativePath ++ "funeral_canticle_chopped.wav", channels:[0]).bufnum;
b.sounds.funeralShort= Buffer.readChannel(s, soundsRelativePath ++ "funeral_chopped_short.wav", channels:[0]).bufnum;
b.sounds.spotlight1= Buffer.readChannel(s, soundsRelativePath ++ "spotlight1.wav", channels:[0]).bufnum;
b.sounds.spotlight2= Buffer.readChannel(s, soundsRelativePath ++ "spotlight2.wav", channels:[0]).bufnum;
b.sounds.spotlight3= Buffer.readChannel(s, soundsRelativePath ++ "spotlight3.wav", channels:[0]).bufnum;

//samples to trig
b.samples.getsIntoCar =Buffer.readChannel(s, samplesRelativePath ++ "Fargo - gets into car.wav").bufnum;
b.samples.everyOneHAsAJob =Buffer.readChannel(s, samplesRelativePath ++ "Fargo - everyone has a job.wav").bufnum;
b.samples.actualizedFully =Buffer.readChannel(s, samplesRelativePath ++ "Fargo - have you actualized fully.wav").bufnum;

m = m ? ();//morpher object
m.xfadeTime = 20;
m.stepsPerSec= 10;

m.morph = TaskProxy({
	var numSteps = m.xfadeTime * m.stepsPerSec;
	var soundsToMorph = Array.new(numSteps+1);

	(numSteps).do { |i|
		var playTargetSound;
		var targetSoundProbability;
		targetSoundProbability = (i + 1) / numSteps;
		playTargetSound = targetSoundProbability.coin;
		if (playTargetSound, {soundsToMorph.add(m.targetSound.copy)}, {soundsToMorph.add(m.currentSound.copy)});
	};

	soundsToMorph.do{|item, i | [i," ",item].postln};

	if (m.targetSound.notNil) {
		soundsToMorph.do { |item, i|
			var percent = i*100/numSteps;
			var sound = soundsToMorph.at(i);
			var buf = b.sounds[sound];
			["numSteps %", percent, " sound:", sound, " buf: "+ buf].postln;
			~wavebuf = buf;
			(1/m.stepsPerSec).wait;
		};
		~wavebuf = b.sounds[m.targetSound];
		m.previousSound = m.currentSound.copy;
		m.currentSound = m.targetSound.copy;
		["MORPH DONE. curent : " + m.currentSound].postln;
	};
}).quant_(0);		// no quantization so the task starts immediately


MIDIClient.init;
MIDIIn.connectAll;
MIDIdef.freeAll;
)



//NANOKONTROL
(
MIDIdef.cc(\slider7toAmp,
	{
		arg val, num, chan, src;
		var amp = val.linlin(0,127,0,0.1);
		("amp: "+amp).postln;
		~amp = amp;
	}
	,7,0);

MIDIdef.cc(\knob7toAmpDev,
	{
		arg val, num, chan, src;
		var ampDev = val.linlin(0,127,0,0.05);
		("ampDev: "+ampDev).postln;
		~ampDev = ampDev;
	},
	23,0);

MIDIdef.cc(\slider0toSampleAmp,
	{
		arg val;
		var sliderVal = val.linlin(0,127,0,1);
		("sampleAmp: "+ sliderVal).postln;
		~sampleAmp = sliderVal;
	},
	0,0);

MIDIdef.cc(\buttonPlayGetsIntoCar,
	{
		var bufnum = b.samples.getsIntoCar;
		("gets into car").postln;
		~sample = {Pan4.ar(PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), loop: 0)) * ~sampleAmp};
	},
	32,0);

MIDIdef.cc(\buttonPlayEveryoneHasAJob,
	{
		var bufnum = b.samples.everyOneHAsAJob;
		("everyOneHAsAJob").postln;
		~sample = {Pan4.ar(PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), loop: 0)) * ~sampleAmp};
	},
	48,0);

MIDIdef.cc(\buttonPlayActuallizedFully,
	{
		var bufnum = b.samples.actualizedFully;
		("actualizedFully").postln;
		~sample = {Pan4.ar(PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), loop: 0)) * ~sampleAmp};
	},
	64,0);


MIDIdef.cc(\knob6toAmpDevChangeRate,
	{  |val|
		var knobVal = val.linlin(0,127,5,30);
		("amp dev change rate: "+ knobVal).postln;
		~ampDevChangeRate = knobVal;
	},
	22,0);


MIDIdef.cc(\slider6toPanDev,
	{
		arg val;
		var sliderVal = val.linlin(0,127,0,1.5);
		("panDev: "+ sliderVal).postln;
		~panDev =  sliderVal;
	},
	6,0);


MIDIdef.cc(\buttonPanCircle,
	{
		("circle pan Mode").postln;
		~panCentral = {LFSaw.kr(10)};
		~panDev = 0;
	},
	38,0);


MIDIdef.cc(\buttonPanEqualRandom,
	{
		("equal random Mode").postln;
		~panCentral = 0;
		~panDev = 1;
	},
	54,0);

MIDIdef.cc(\slider1toRateRange,
	{
		arg val;
		var sliderVal = val.linexp(0,127,0.001,0.5);
		("rateRange: "+ sliderVal + " %").postln;
		~rateRange = sliderVal;
	},
	1,0);


MIDIdef.cc(\knob1toTriggerDensity,
	{
		arg val;
		var sliderVal = val.linexp(0,127,2,200);
		("grainDensity: "+ sliderVal).postln;
		~triggerDensity = sliderVal;
	},
	17,0);


MIDIdef.cc(\knob2toMorphStepsPerSec,
	{
		arg val;
		m.stepsPerSec  = val.linlin(0,127,1,60);
		("stepsPerSec: "+ m.stepsPerSec).postln;
	},
	18,0);

MIDIdef.cc(\slider2toMorphCrossFadeTime,
	{
		arg val;
		m.xfadeTime  = val.linlin(0,127,1,60);
		("crossFade time: "+ m.xfadeTime).postln;
	},
	2,0);

MIDIdef.cc(\buttonPreviousNavigation,
	{
		b.discardButton= b.discardButton.not;
		if(b.discardButton,{},{
			var key;
			b.soundsIndex = b.soundsIndex-1;
			key = b.sounds.keys.asArray.wrapAt(b.soundsIndex);
			m.targetSound = key.asSymbol;
			("targetSound: " + key).postln;
		})
	},
	61,0);

MIDIdef.cc(\buttonNextNavigation,
	{
		b.discardButton= b.discardButton.not;
		if(b.discardButton,{},{
			var key;
			b.soundsIndex = b.soundsIndex+1;
			key = b.sounds.keys.asArray.wrapAt(b.soundsIndex);
			m.targetSound = key.asSymbol;
			("targetSound: " + key).postln;
		})
	},
	62,0);


MIDIdef.cc(\buttonPreviousToTarget,
	{
		b.discardButton= b.discardButton.not;
		if(b.discardButton,{},{
			m.targetSound = m.previousSound.copy;
			("targetSound: " + m.targetSound).postln;
		})
	},
	43,0);

MIDIdef.cc(\buttonEntryGosh,
	{
		b.discardButton= b.discardButton.not;
		if(b.discardButton,{},{
			var auxFadeTime = m.xfadeTime.copy;
			m.targetSound = \entryGosh;
			m.xfadeTime = 3;
			m.morph.stop.play;
			"entryGosh".postln;
			m.xfadeTime = auxFadeTime;
		})
	},
	42,0);


MIDIdef.cc(\buttonToGoMorph,
	{
		b.discardButton= b.discardButton.not;
		if(b.discardButton,{},{
			m.morph.stop.play;
			("MORPH! ").postln;
		})
	},
	41,0);
)


/*
PanAz
pos = pan position. Channels are evenly spaced over a cyclic period of 2.0 in pos with 0.0 equal to channel zero and 2.0/numChans equal to channel 1, 4.0/numChans equal to channel 2, etc.
Thus all channels will be cyclically panned through if a sawtooth wave from -1 to +1 is used to modulate the pos.
==> basically, 0 is front, then 0.5 right, 1and -1 rear, -0.5 left
==> tmabe pots rotar desde 0 a 2 per fer una volta completa, nice!!

*/


/*START TO PLAY*/
(
var numOutputs = s.options.numOutputBusChannels;
~wavebuf = b.sounds.entryGosh;
m.currentSound = \entryGosh;

~triggerDensity = 50;
~trig = { Dust.kr(~triggerDensity)};

//~grainDurDev = {MouseY.kr(0.05,15) + LFNoise0.kr(100,3)};
~grainDurDev = {MouseY.kr(0.05,10).poll(2)};
~grainDur = {~grainDurDev + LFNoise0.kr(100,~grainDurDev.min(3))};

~filePos = {MouseX.kr};
~filePosNoised = {~filePos + LFNoise0.kr(100, 0.03)};

~rateRange = 0.02;
~rate = { LFNoise1.kr.range((1- ~rateRange), (1+~rateRange)) };

~panCentral = 0;
~panDev = 1;
~pan = {~panCentral + {WhiteNoise.kr(mul: ~panDev)}};

~amp = 0.05;
~ampDev = 0.00;
~ampDevChangeRate = 10;
~ampNoised ={LFNoise0.kr(~ampDevChangeRate).range( ~amp - ~ampDev,  ~amp + ~ampDev)};

~grain = { arg envbuf = -1, wavebuf = 0;
	GrainBuf.ar(numOutputs, ~trig.kr, ~grainDur.kr, ~wavebuf,
		~rate.kr, ~filePosNoised.kr, 2, ~pan , envbuf) * ~ampNoised.kr
};
~grain.play;
~sample.play;
)

/*STOP*/
~grain.stop;


/*SOME SETTINGS, experimentation with control proxies*/
~trig = { |dens=50| Impulse.kr(dens) };
~rate = { LFNoise1.kr.range(0.5, 1.5) };
~rate = { LFNoise1.kr.range(0.98, 1.02) };
~filePos = { MouseX.kr + LFNoise0.kr(100, 0.03) };
~grainDur = {MouseY.kr(0.5,25) + LFNoise0.kr(100,3)};
~grainDur = {SinOsc.ar(0.05).range(0.05,10)};
~trig = { |dens=50| Dust.kr(dens) };



/*MORPH TO OTHER SOUNDS*/
m.currentSound = \pater;

m.targetSound = \pater;
m.targetSound = \arp1Filter;
m.targetSound = \arp1;
m.targetSound = \allegro1;
m.targetSound = \ensQuedem;
m.targetSound = \quePortes;
m.targetSound = \feedbackChords;
m.targetSound = \glacat;
m.targetSound = \noPuedeSer;
m.targetSound = \entryGosh;
m.targetSound = \entryGoshClick;
m.targetSound = \entryGoshWahWah;
m.targetSound = \fratresIntro;
m.targetSound = \fratres;
m.targetSound = \fostercare;
m.targetSound = \miserere;
m.targetSound = \klavierwerke;
m.targetSound = \funeral;
m.targetSound = \funeralShort;
m.targetSound = \drumming;
m.targetSound = \spotlight1;
m.targetSound = \spotlight2;
m.targetSound = \spotlight3;

//MORPH SETTINGS
m.xfadeTime = 1;
m.stepsPerSec = 5;
m.stepsPerSec = 1; //when low number there is no "leaks"
//GO!
m.morph.stop.play;



s.record;
s.stopRecording;

