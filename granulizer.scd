/*
TODOS:
 - Volume al sample, no al GrainBuf
 - Adaptar Pan a PanAz
*/

(
s = Server.local;
//s.options.numOutputBusChannels = 4;
//s.options.numOutputBusChannels = 2;
s.options.numOutputBusChannels = 3;
"This will play on ".post + s.options.numOutputBusChannels.post + " channels".postln;
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

m = m ? (); //buffers object
m.oundsIndex = 0;
m.discardButton  = true; //workaround because button is called two times
m.sounds = ();
m.samples = ();
//GrainBuf needs a mono source bufnum
m.sounds.pater = Buffer.read(s, soundsRelativePath ++ "pater_noe.aif",channels:[0]).bufnum;
m.sounds.arp1Filter =  Buffer.readChannel(s,soundsRelativePath ++ "nechaev - arpegio1_filtered_lowered.wav" ,channels:[0]).bufnum;
m.sounds.arp1 = Buffer.readChannel(s,soundsRelativePath ++ "nechaev - arpegio1_19_07_lowered.wav", channels:[0]).bufnum;
m.sounds.allegro1 = Buffer.readChannel(s,soundsRelativePath ++ "nechaev - allegro1_8_11_2013.wav", channels:[0]).bufnum;
m.sounds.ensQuedem = Buffer.readChannel(s,soundsRelativePath ++ "nechaev - ens quedem 7_07.wav", channels:[0]).bufnum;
m.sounds.feedbackChords = Buffer.readChannel(s,soundsRelativePath ++ "nechaev - feedbackchords.wav", channels:[0]).bufnum;
m.sounds.quePortes = Buffer.readChannel(s,soundsRelativePath ++ "nechaev - que portes 22_11_2015_SHORT.wav", channels:[0]).bufnum;
m.sounds.glacat = Buffer.readChannel(s, soundsRelativePath ++ "nechaev - glaçat mastered.wav", channels:[0]).bufnum;
m.sounds.noPuedeSer = Buffer.readChannel(s, soundsRelativePath ++ "nechaev - no puede ser.wav", channels:[0]).bufnum;
m.sounds.entryGosh = Buffer.readChannel(s, soundsRelativePath ++ "entryGosh.wav", channels:[0]).bufnum;
m.sounds.entryGoshClick = Buffer.readChannel(s, soundsRelativePath ++ "entryGosh_click.wav", channels:[0]).bufnum;
m.sounds.entryGoshWahWah = Buffer.readChannel(s, soundsRelativePath ++ "entryGosh_wahwah.wav", channels:[0]).bufnum;
m.sounds.fratresIntro = Buffer.readChannel(s,soundsRelativePath ++ "fratres intro.wav", channels:[0]).bufnum;
m.sounds.fratres = Buffer.readChannel(s,soundsRelativePath ++ "Arvo Part - Fratres For Cello And Piano.wav", channels:[0]).bufnum;
m.sounds.fostercare = Buffer.readChannel(s,soundsRelativePath ++ "Burial - Fostercare (HQ).wav", channels:[0]).bufnum;
m.sounds.miserere = Buffer.readChannel(s,soundsRelativePath ++ "Gregorio Allegri- Miserere.wav", channels:[0]).bufnum;
m.sounds.klavierwerke = Buffer.readChannel(s, soundsRelativePath ++ "James Blake - Klavierwerke.wav", channels:[0]).bufnum;
m.sounds.drumming = Buffer.readChannel(s, soundsRelativePath ++ "Steve Reich - Part IV - Drumming.wav", channels:[0]).bufnum;
m.sounds.funeral = Buffer.readChannel(s, soundsRelativePath ++ "funeral_canticle_chopped.wav", channels:[0]).bufnum;
m.sounds.funeralShort = Buffer.readChannel(s, soundsRelativePath ++ "funeral_chopped_short.wav", channels:[0]).bufnum;
m.sounds.silence = Buffer.readChannel(s, soundsRelativePath ++ "silence.aif", channels:[0]).bufnum;
m.sounds.noise = Buffer.readChannel(s, soundsRelativePath ++ "noiseSnr.aif", channels:[0]).bufnum;
m.sounds.spotlight1 = Buffer.readChannel(s, soundsRelativePath ++ "spotlight1.wav", channels:[0]).bufnum;
m.sounds.spotlight2 = Buffer.readChannel(s, soundsRelativePath ++ "spotlight2.wav", channels:[0]).bufnum;
m.sounds.spotlight3 = Buffer.readChannel(s, soundsRelativePath ++ "spotlight3.wav", channels:[0]).bufnum;

//samples to trig
m.samples.getsIntoCar =Buffer.readChannel(s, samplesRelativePath ++ "Fargo - gets into car.wav").bufnum;
m.samples.everyOneHAsAJob =Buffer.readChannel(s, samplesRelativePath ++ "Fargo - everyone has a job.wav").bufnum;
m.samples.actualizedFully =Buffer.readChannel(s, samplesRelativePath ++ "Fargo - have you actualized fully.wav").bufnum;

//initialization:
m.cycle = 10;

m.probabilityShape =  Wavetable.sineFill(512, 1.0/[1]).asArray[0..512]; //only take the postive part of sine
m.probabilityShape =  Env.new([0.001, 0.001, 1, 1, 0.001], [0.25, 0.25, 0.25, 0.25], '\sin' ).asSignal.asArray;
m.probabilityShape.plot;

m.currentSounds = List.new(0);
m.currentSoundDBs = ();

m.addSound =  {|self, soundName|
	m.currentSoundDBs[soundName] = m.currentSoundDBs[soundName] ? 0;
	m.currentSounds.add(soundName);
};

m.removeSound = {|self, soundName|
	m.currentSounds.remove(soundName);
};

m.morphMultiple = TaskProxy({
	var panDirection = 1;

	inf.do { |el, index|
		if (m.currentSounds.size > 0) {
			var phase = (m.probabilityShape.size/m.currentSounds.size).floor;
			var probs = m.currentSounds.collect({ |el, i|
				m.probabilityShape.wrapAt(i*phase + index).abs;
			});
			var soundToPlay =  m.currentSounds.wchoose(probs.normalizeSum);

			var indexOfSound =  m.currentSounds.indexOf(soundToPlay);
			var soundProb = probs.at(indexOfSound);
			var panDirectionByIndex = if(indexOfSound.odd, 1, -1);

			if ( index %  m.probabilityShape.size == 0){
				"CHANGE PAN DIRECTION".postln;
				panDirection = panDirection * -1;
			};

			~pan = soundProb -1 * panDirection * panDirectionByIndex;
			~wavebuf = m.sounds[soundToPlay];
			~individualAmp = m.currentSoundDBs[soundToPlay].dbamp;

/*			[
			soundProb,
			soundToPlay,
				m.sounds[soundToPlay],
			m.currentSoundDBs[soundToPlay].dbamp
			].postln;*/

		};
	(m.cycle/m.probabilityShape.size).wait;
	};
}).quant_(0);


MIDIClient.init;
MIDIIn.connectAll;
MIDIdef.freeAll;
)




/*DEFINE GLOVARS AND START TO PLAY*/
(
var numOutputs = s.options.numOutputBusChannels;
m.addSound(\entryGosh);

~triggerDensity = 50;
~trig = { Dust.kr(~triggerDensity)};


~grainDurDev = { MouseY.kr(0.05,10) };
~grainDur = {~grainDurDev + LFNoise0.kr(100,~grainDurDev.min(3))};

~filePos = {MouseX.kr};
~filePosNoised = {~filePos + LFNoise0.kr(100, 0.03)};

~rateRange = 0.02;
~rate = { LFNoise1.kr.range((1- ~rateRange), (1+~rateRange)) };

~panCentral = 0;
~panDev = 1;
~pan = {~panCentral + {WhiteNoise.kr(mul: ~panDev)}};

~amp = 0.05;
~individualAmp = 1;
~ampDev = 0.00;
~ampDevChangeRate = 10;
~ampNoised = ~individualAmp * {LFNoise0.kr(~ampDevChangeRate).range( ~amp - ~ampDev,  ~amp + ~ampDev)};

~grain = { arg envbuf = -1, wavebuf = 0;
	GrainBuf.ar(numOutputs, ~trig.kr, ~grainDur.kr, ~wavebuf,
		~rate.kr, ~filePosNoised.kr, 2, ~pan , envbuf, mul: ~ampNoised.ar)
};

~grain.play;
~sample.play;

// TODO: more elegant ways of handling async in "asyncronous execution" help file, but it works :p
SystemClock.sched(0.5, {m.morphMultiple.play});
SystemClock.sched(1, {
	"/Users/lluissuros/Music/SuperCollider/SuperCollider Projects/granulizer/GUI_Buttons.scd".loadPaths
});

)









/*
PanAz
pos = pan position. Channels are evenly spaced over a cyclic period of 2.0 in pos with 0.0 equal to channel zero and 2.0/numChans equal to channel 1, 4.0/numChans equal to channel 2, etc.
Thus all channels will be cyclically panned through if a sawtooth wave from -1 to +1 is used to modulate the pos.
==> basically, 0 is front, then 0.5 right, 1and -1 rear, -0.5 left
==> tmabe pots rotar desde 0 a 2 per fer una volta completa, nice!!
*/
~panCentral = 0
~panCentral = 2/3
~panCentral = 4/3
2/3
4/3
//uniform pan distribution in PanAZ
~panDev = 1;
~panDev = 0.3;
~panDev = 0;

50.do({"he".postln; 0.1.wait})
(
var r;
r = Routine {
    100.do({ arg a;
		~panCentral = [0, 2/3, 4/3].choose;
        1.wait;
    });
}.play;
)






//morphMultiple play
m.currentSounds
m.currentSoundDBs
m.addSound(\klavierwerke);
m.addSound(\spotlight1);
m.addSound(\spotlight2);
m.addSound(\spotlight3);
m.addSound(\entryGosh);
m.addSound(\entryGoshClick);
m.addSound(\entryGoshWahWah);
m.addSound(\drumming);
m.addSound(\fratres);
m.addSound(\glacat);
m.addSound(\arp1);
m.addSound(\arp1Filter);
m.addSound(\silence);
m.addSound(\noise);

m.removeSound(\klavierwerke);
m.removeSound(\spotlight1);
m.removeSound(\spotlight2);
m.removeSound(\spotlight3);
m.removeSound(\entryGosh);
m.removeSound(\entryGoshClick);
m.removeSound(\entryGoshWahWah);
m.removeSound(\drumming);
m.removeSound(\fratres);
m.removeSound(\glacat);
m.removeSound(\arp1);
m.removeSound(\arp1Filter);
m.removeSound(\silence);
m.removeSound(\noise);




/*STOP*/
~grain.stop;

/*SOME SETTINGS:  */
~trig = { |dens=50| Impulse.kr(dens) };
~rate = { LFNoise1.kr.range(0.5, 1.5) };
~rate = { LFNoise1.kr.range(0.98, 1.02) };
~filePos = { MouseX.kr + LFNoise0.kr(100, 0.03) };
~grainDur = {MouseY.kr(0.5,25) + LFNoise0.kr(100,3)};
~grainDur = {SinOsc.ar(0.05).range(0.05,10)};
~trig = { |dens=50| Dust.kr(dens) };


//cycle
m.cycle = 30;
m.cycle = 10;
m.cycle = 5;

//nice combnations
m.currentSounds = List[\entryGoshClick, \noise, \silence]
m.currentSounds = List[\arp1Filter,  \silence, \fratres, \noise,  \arp1Filter, \silence]
m.currentSounds = List[\entryGosh, \fratres, \spotlight3] //ending




//a score
m.cycle = 5;
~grain.play;
~sample.play;
m.morphMultiple.play;
m.morphMultiple.stop;
~grain.stop;
m.currentSounds = List[\entryGoshClick, \noise, \silence]

m.addSound(\fratres);
m.addSound(\spotlight3);
m.removeSound(\spotlight3);
m.removeSound(\silence);
m.removeSound(\noise);




