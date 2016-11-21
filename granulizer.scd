/*TODO:
-all samples in b. are mono at the moment
-funeral is too big

DONE --> panning cycle should be proportional to graindur
DONE --> nanokontrol to grain density
DONE -->button for changing between mouseX and slider for position
-more panning modes besides circle --> i don't need the knob for pan
-tener reverb, delay, dist
-b.soundsArray at setup, because if I do array on the fly the order changes all the time

DONE --> arrows to switch between sounds, and button to morph.play (or the arrow changes and plays?)
DONE -->control to set the steps and duration of morph

TODO: -an entryGosh is playing all the time, controlled by a slider?


BUG: --> el navegador de sounds no va bé
Bug: MouseY ml ajustat
BUG: circle pan broken

TODO: -grainDur ha de tenir el centre sobre el 2
TODO: - arp1 i arp1filter esta massa fort i entry gosh fluix MOLT IMPORTANT ELS VOLUMS, per no causar estrés a l'oient. Si hi ha osties de volumn no es podran relaxar
TODO: més sons: molaria més sons de baix rollo entryGosh, tambe altres peces atmosferiques rollo que_portes
TODO amb la rme posar compressors a la sortida.

*/

(
s = Server.local;
s.options.numOutputBusChannels = 4;
s.boot;
)

//LOADING AND SETUP
(
var soundsRelativePath = thisProcess.nowExecutingPath.dirname +/+ "Sounds/";

s = Server.local;
s.options.numOutputBusChannels = 4;
s.boot;

p = ProxySpace.push;

b = b ? (); //buffers object
b.soundsIndex = 0;
b.discardButton = true; //workaround because button is called two times
b.sounds = ();

//GrainBuf needs a mono source bufnum
b.sounds.pater = Buffer.read(s, soundsRelativePath ++ "pater_noe.aif",channels:[0]).bufnum;
b.sounds.arp1Filter =  Buffer.readChannel(s,soundsRelativePath ++ "arpegio1_impro.aiff" ,channels:[0]).bufnum;
b.sounds.arp1 = Buffer.readChannel(s,soundsRelativePath ++ "arpegio1_19_07.aiff", channels:[0]).bufnum;
b.sounds.glacat = Buffer.readChannel(s, soundsRelativePath ++ "nechaev - glaçat mastered.wav", channels:[0]).bufnum;
b.sounds.noPuedeSer = Buffer.readChannel(s, soundsRelativePath ++ "nechaev - no puede ser.wav", channels:[0]).bufnum;
b.sounds.gosh = Buffer.readChannel(s, soundsRelativePath ++ "jamiexx - Gosh.wav", channels:[0]).bufnum;
b.sounds.entryGosh = Buffer.readChannel(s, soundsRelativePath ++ "entryGosh.wav", channels:[0]).bufnum;
b.sounds.fratres= Buffer.readChannel(s,soundsRelativePath ++ "Arvo Part - Fratres For Cello And Piano.wav", channels:[0]).bufnum;
b.sounds.fostercare= Buffer.readChannel(s,soundsRelativePath ++ "Burial - Fostercare (HQ).wav", channels:[0]).bufnum;
b.sounds.miserere= Buffer.readChannel(s,soundsRelativePath ++ "Gregorio Allegri- Miserere.wav", channels:[0]).bufnum;
b.sounds.klavierwerke= Buffer.readChannel(s, soundsRelativePath ++ "James Blake - Klavierwerke.wav", channels:[0]).bufnum;
b.sounds.drumming= Buffer.readChannel(s, soundsRelativePath ++ "Steve Reich - Part IV - Drumming.wav", channels:[0]).bufnum;
//TODO: Toooo big!
b.sounds.funeral= Buffer.readChannel(s, soundsRelativePath ++ "John Tavener - Funeral Canticle (1-2).wav", channels:[0]).bufnum;



m = m ? ();//morpher object
m.xfadeTime = 20;
m.stepsPerSec= 10;

m.morph = TaskProxy({
	var targetBuf= m[\targetBuf].copy;
	var currentBuf = m[\currentBuf].copy;
	var numSteps = m.xfadeTime * m.stepsPerSec;
	var bufsToMorph = Array.new(numSteps+1);

	(numSteps).do { |i|
		var playTargetBuf;
		var targetBufProbability;
		targetBufProbability = (i + 1) / numSteps;
		playTargetBuf = targetBufProbability.coin;
		if (playTargetBuf, {bufsToMorph.add(targetBuf)}, {bufsToMorph.add(currentBuf)});
	};

	bufsToMorph.do{|item, i | [i," ",item].postln};

	if (m.targetBuf.notNil) {
		bufsToMorph.do { |item, i|
			var percent = i*100/numSteps;
			["numSteps %", percent, " bufnum", bufsToMorph.at(i)].postln;
			~wavebuf = bufsToMorph.at(i);
			(1/m.stepsPerSec).wait;
		};
		~wavebuf = targetBuf;
		m[\currentBuf] = m[\targetBuf].copy;
		"MORPH DONE.".postln;
	};
}).quant_(0);		// no quantization so the task starts immediately


MIDIClient.init;
MIDIIn.connectAll;
MIDIdef.freeAll;


)


//NANOKONTROL
/*
+Midi controls for Nano:
- ~filePos
- ~grainDur
- ~amp
- ~rateRange(adds and rests to rate)
- ~GoMorph (button)
- x and y panning
*/
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

MIDIdef.cc(\slider0toFilePos,
	{
		arg val;
		var sliderVal = val.linlin(0,127,0,1);
		("filePos: "+ sliderVal).postln;
		~filePos = sliderVal;
	},
	0,0);

MIDIdef.cc(\knob0toGraindur,
	{
		arg val;
		var grainDurDev = val.linexp(0,127,0.1,30);
		("grainDurDev: "+ grainDurDev).postln;
		~grainDurDev = grainDurDev;
	},
	16,0);

MIDIdef.cc(\buttonEnableMouseXPositionAndMouseYGrainDur,
	{
		("position by MouseX and GrainDur mouseY, touch controls to recover midi").postln;
		~filePos = {MouseX.kr};
		~grainDurDev = {MouseY.kr(0.05,10).poll};
	},
	32,0);


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
		~panCentral = {LFSaw.kr(4/~grainDur)};
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



MIDIdef.cc(\buttonPreviousBuffer,
	{
		b.discardButton= b.discardButton.not;
		if(b.discardButton,{},{
			var key = b.sounds.keys.asArray.wrapAt(b.soundsIndex);
			m.targetBuf = b.sounds[key];
			("targetBuf: " + key).postln;
			b.soundsIndex = b.soundsIndex-1;
		})
	},
	43,0);

MIDIdef.cc(\buttonNextBuffer,
	{
		b.discardButton= b.discardButton.not;
		if(b.discardButton,{},{
			var key = b.sounds.keys.asArray.wrapAt(b.soundsIndex);
			m.targetBuf = b.sounds[key];
			("targetBuf: " + key).postln;
			b.soundsIndex = b.soundsIndex+1;
		})
	},
	44,0);

MIDIdef.cc(\buttonToGo,
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
m.start = b.sounds.entryGosh;

~triggerDensity = 50;
~trig = { Dust.kr(~triggerDensity)};

//~grainDurDev = {MouseY.kr(0.05,15) + LFNoise0.kr(100,3)};
~grainDurDev = {MouseY.kr(0.05,10).poll};
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
m.start = b.sounds.pater;

m.targetBuf = b.sounds.pater;
m.targetBuf = b.sounds.arp1Filter;
m.targetBuf = b.sounds.arp1;
m.targetBuf = b.sounds.glacat;
m.targetBuf = b.sounds.noPuedeSer;
m.targetBuf = b.sounds.gosh;
m.targetBuf = b.sounds.entryGosh;
m.targetBuf = b.sounds.fratres;
m.targetBuf = b.sounds.fostercare;
m.targetBuf = b.sounds.miserere;
m.targetBuf = b.sounds.klavierwerke;
m.targetBuf = b.sounds.funeral;
m.targetBuf = b.sounds.drumming;

//MORPH SETTINGS
m.xfadeTime = 30;
m.stepsPerSec = 20;
m.stepsPerSec = 1; //when low number there is no "leaks"
//GO!
m.morph.stop.play;



s.record;
s.stopRecording;

