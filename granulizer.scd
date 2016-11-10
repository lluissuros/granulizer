/*TODO:
-all samples in b. are mono at the moment
-funeral is too big

+Midi controls for Nano:
  - ~filepos
  - ~graindur
  - ~amp
  - ~rateRange(adds and rests to rate)
  - ~GoMorph (button)
  - x and y panning
*/


//LOADING AND SETUP
(
var soundsRelativePath = thisProcess.nowExecutingPath.dirname +/+ "Sounds/";

p = ProxySpace.push;
ProxyMixer(p);

b = b ? (); //buffers object
//GrainBuf needs a mono source bufnum
b.pater = Buffer.read(s, soundsRelativePath ++ "pater_noe.aif",channels:[0]).bufnum;
b.arp1Filter =  Buffer.readChannel(s,soundsRelativePath ++ "arpegio1_impro.aiff" ,channels:[0]).bufnum;
b.arp1 = Buffer.readChannel(s,soundsRelativePath ++ "arpegio1_19_07.aiff", channels:[0]).bufnum;
b.glacat = Buffer.readChannel(s, soundsRelativePath ++ "nechaev - glaçat mastered.wav", channels:[0]).bufnum;
b.noPuedeSer = Buffer.readChannel(s, soundsRelativePath ++ "nechaev - no puede ser.wav", channels:[0]).bufnum;
b.gosh = Buffer.readChannel(s, soundsRelativePath ++ "jamiexx - Gosh.wav", channels:[0]).bufnum;
b.entryGosh = Buffer.readChannel(s, soundsRelativePath ++ "entryGosh.wav", channels:[0]).bufnum;
b.fratres= Buffer.readChannel(s,soundsRelativePath ++ "Arvo Part - Fratres For Cello And Piano.wav", channels:[0]).bufnum;
b.fostercare= Buffer.readChannel(s,soundsRelativePath ++ "Burial - Fostercare (HQ).wav", channels:[0]).bufnum;
b.miserere= Buffer.readChannel(s,soundsRelativePath ++ "Gregorio Allegri- Miserere.wav", channels:[0]).bufnum;
b.klavierwerke= Buffer.readChannel(s, soundsRelativePath ++ "James Blake - Klavierwerke.wav", channels:[0]).bufnum;
b.drumming= Buffer.readChannel(s, soundsRelativePath ++ "Steve Reich - Part IV - Drumming.wav", channels:[0]).bufnum;
//TODO: Toooo big!
b.funeral= Buffer.readChannel(s, soundsRelativePath ++ "John Tavener - Funeral Canticle (1-2).wav", channels:[0]).bufnum;



m = m ? ();//morpher object
m.xfadeTime = 40;
m.stepsPerSec= 20;

m.morph = TaskProxy({
	var targetBuf= w[\targetBuf].copy;
	var currentBuf = w[\currentBuf].copy;
	var numSteps = m.xfadeTime * m.stepsPerSec;
	var bufsToMorph = Array.new(numSteps+1);

	(numSteps).do { |i|
		var playTargetBuf;
	    var targetBufProbability;
		targetBufProbability = (i + 1) / numSteps;
		playTargetBuf = targetBufProbability.coin;
		if (playTargetBuf, {bufsToMorph.add(targetBuf)}, {bufsToMorph.add(currentBuf)});
	};

	//bufsToMorph.do{|item, i | [i," ",item].postln};

	if (m.targetBuf.notNil) {
		bufsToMorph.do { |item, i|
			var percent = i*100/numSteps;
			["numSteps %", percent, " bufnum", bufsToMorph.at(i)].postln;
			~wavebuf = bufsToMorph.at(i);
			(1/m.stepsPerSec).wait;
		};
		~wavebuf = targetBuf;
		w[\currentBuf] = w[\targetBuf].copy;
		"MORPH DONE.".postln;
	};
}).quant_(0);		// no quantization so the task starts immediately
)


/*START TO PLAY*/
(
~wavebuf = b.pater;
~trig = { |dens=50| Dust.kr(dens) };
~graindur = {MouseY.kr(0.05,15) + LFNoise0.kr(100,3)};
~filepos = { MouseX.kr + LFNoise0.kr(100, 0.03) };
~rate = { LFNoise1.kr.range(0.98, 1.02) };
~amp = 0.05;
~pan = {WhiteNoise.kr};
~grain = { arg envbuf = -1, wavebuf = 0;
	GrainBuf.ar(2, ~trig.kr, ~graindur.kr, ~wavebuf,
	~rate.kr, ~filepos.kr, 2, ~pan , envbuf) * ~amp.kr
};
~grain.play;
)

/*STOP*/
~grain.stop;


/*SOME SETTINGS, experimentation with control proxies*/
~trig = { |dens=50| Impulse.kr(dens) };
~rate = { LFNoise1.kr.range(0.5, 1.5) };
~rate = { LFNoise1.kr.range(0.98, 1.02) };
~filepos = { MouseX.kr + LFNoise0.kr(100, 0.03) };
~graindur = 0.05;
~graindur = 0.5;
~graindur = 2;
~graindur = 10;
~amp =0.05;
~graindur = {MouseY.kr(0.5,25) + LFNoise0.kr(100,3)};
~graindur = {SinOsc.ar(0.05).range(0.05,0.5)};
~trig = { |dens=50| Dust.kr(dens) };



/*MORPH TO OTHER SOUNDS*/
m.start = b.pater;

m.targetBuf = b.pater;
m.targetBuf = b.arp1Filter;
m.targetBuf = b.arp1;
m.targetBuf = b.glacat;
m.targetBuf = b.noPuedeSer;
m.targetBuf = b.gosh;
m.targetBuf = b.entryGosh;
m.targetBuf = b.fratres;
m.targetBuf = b.fostercare;
m.targetBuf = b.miserere;
m.targetBuf = b.klavierwerke;
m.targetBuf = b.funeral;
m.targetBuf = b.drumming;

//MORPH SETTINGS
m.xfadeTime = 10;
m.stepsPerSec = 20;
m.stepsPerSec = 1; //when low number there is no "leaks"
//GO!
m.morph.stop.play;




s.record;
s.stopRecording;

