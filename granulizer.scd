



(
p = ProxySpace.push;
ProxyMixer(p);

// figure 16.14 - GrainBuf and control proxies
b = b ? (); //create buffers object

//GrainBuf needs a mono source
b.pater = Buffer.read(s, "/Users/lluissuros/Music/Logic/Noe/pater.logicx/Media/Audio Files/Sin título_1#02.aif");
b.arp1Filter =  Buffer.readChannel(s,"/Users/lluissuros/Music/SuperCollider Recordings/arpegio1_impro.aiff" ,channels:[0]);
b.arp1 = Buffer.readChannel(s, "/Users/lluissuros/Music/SuperCollider Recordings/arpegio1_19_07.aiff", channels:[1]);
b.glacat = Buffer.readChannel(s, "/Users/lluissuros/Music/iTunes/iTunes Media/Music/Unknown Artist/Unknown Album/1.nechaev - glaçat mastered.wav", channels:[1]);
b.noPuedeSer = Buffer.readChannel(s, "/Users/lluissuros/Music/iTunes/iTunes Media/Music/Unknown Artist/Unknown Album/6.nechaev - no puede ser.wav", channels:[1]);
b.gosh = Buffer.readChannel(s, "/Users/lluissuros/Music/Samples Musica/01 Gosh.wav", channels:[0]);
b.entryGosh = Buffer.readChannel(s, "/Users/lluissuros/Music/Samples Musica/entryGosh.wav", channels:[0]);
//b.inCommon = Buffer.readChannel(s, "/Users/lluissuros/Music/Samples Musica/Alicia Keys - In Common.wav", channels:[0]);
b.fratres= Buffer.readChannel(s,"/Users/lluissuros/Music/Samples Musica/Arvo Part - Fratres For Cello And Piano.wav", channels:[0]);
//b.halo= Buffer.readChannel(s, "/Users/lluissuros/Music/Samples Musica/Beyoncé - Halo.wav", channels:[0]);
b.fostercare= Buffer.readChannel(s, "/Users/lluissuros/Music/Samples Musica/Burial - Fostercare (HQ).wav", channels:[0]);
//b.hotline= Buffer.readChannel(s, "/Users/lluissuros/Music/Samples Musica/Drake - Hotline Bling.wav", channels:[0]);
b.miserere= Buffer.readChannel(s, "/Users/lluissuros/Music/Samples Musica/Gregorio Allegri- Miserere.wav", channels:[0]);
b.klavierwerke= Buffer.readChannel(s, "/Users/lluissuros/Music/Samples Musica/James Blake - Klavierwerke.wav", channels:[0]);
b.funeral= Buffer.readChannel(s, "/Users/lluissuros/Music/Samples Musica/John Tavener - Funeral Canticle (1-2).wav", channels:[0]);
//b.sorry= Buffer.readChannel(s, "/Users/lluissuros/Music/Samples Musica/Justin Bieber - Sorry (Dance Video).wav", channels:[0]);
//b.allright= Buffer.readChannel(s, "/Users/lluissuros/Music/Samples Musica/Kendrick Lamar - Alright.wav", channels:[0]);
//b.kingKunta= Buffer.readChannel(s, "/Users/lluissuros/Music/Samples Musica/Kendrick Lamar - King Kunta.wav", channels:[0]);
b.drumming= Buffer.readChannel(s, "/Users/lluissuros/Music/Samples Musica/Steve Reich - Part IV - Drumming.wav", channels:[0]);
)


(
//~grain.set(\wavebuf, b.bufnum);
~wavebuf = b.pater.bufnum;
~trig = { |dens=50| Dust.kr(dens) };
~graindur = {MouseY.kr(0.5,25) + LFNoise0.kr(100,3)};
~filepos = { MouseX.kr + LFNoise0.kr(100, 0.03) };
~rate = { LFNoise1.kr.range(0.98, 1.02) };
~amp = 0.05;

~grain = { arg envbuf = -1, wavebuf = 0;
	GrainBuf.ar(2, ~trig.kr, ~graindur.kr, ~wavebuf,
	~rate.kr, ~filepos.kr, 2, WhiteNoise.kr, envbuf) * ~amp.kr
};
~grain.play;
)

	// experiment with control proxies
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


(
w = w ? ();

// POC  and some parameters for controlling the fade
//w.stopAfterFade = false;
w.xfadeTime = 40;
w.stepsPerSec= 20;
~arrayTest = Array.new(1000);

w.morph = TaskProxy({
	var nextSet= w[\target].copy;
	var startSet = w[\start].copy;
	var numSteps = w.xfadeTime * w.stepsPerSec;
	var blendVal, morphSettings;
	var arrayTest = Array.new(10000);

	(numSteps).do { |i|
		var toss;
		blendVal = (i + 1) / numSteps;
		toss = blendVal.coin;
		if (toss, {arrayTest.add(nextSet)}, {arrayTest.add(startSet)});
	};
	arrayTest.do{|item, i | [i," ",item].postln};

	//TODO: get array elements and set them here
	if (w.target.notNil) {
		arrayTest.do { |item, i|
			//var toss;
			//blendVal = (i + 1) / numSteps;
			//myVersion:
			//toss = blendVal.coin;
			//if (toss, {~wavebuf=nextSet}, {~wavebuf=startSet});
			["numSteps %", i*100/numSteps, " bufnum", arrayTest.at(i)].postln;
			~wavebuf = arrayTest.at(i);

			(1/w.stepsPerSec).wait;
		};
		~wavebuf = nextSet;
		w[\start] = w[\target].copy;
		"MORPH DONE.".postln;
	};

}).quant_(0);		// no quantization so the task starts immediately
)

~grain.play
~grain.stop


w.start = b.pater.bufnum;

w.target = b.pater.bufnum;
w.target = b.arp1Filter.bufnum;
w.target = b.arp1.bufnum;
w.target = b.glacat.bufnum;
w.target = b.noPuedeSer.bufnum;
w.target = b.gosh.bufnum;
w.target = b.entryGosh.bufnum;
//w.target = b.inCommon.bufnum;
w.target = b.fratres.bufnum;
//w.target = b.halo.bufnum;
w.target = b.fostercare.bufnum;
//w.target = b.hotline.bufnum;
w.target = b.miserere.bufnum;
//w.target = b.heartbeats.bufnum;//no
//w.target = b.klavierwerke.bufnum;
w.target = b.funeral.bufnum;
//w.target = b.sorry.bufnum;
//w.target = b.allright.bufnum;
//w.target = b.kingKunta.bufnum;
w.target = b.drumming.bufnum;

~bufnum = 0;
~bufnum = 8;

w.xfadeTime = 40;
w.stepsPerSec = 40;
//GO
w.morph.stop.play;


s.record;
s.stopRecording;

t = Array.new(1000);
t.add("test")
