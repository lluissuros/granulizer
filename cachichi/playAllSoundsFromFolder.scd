/*
* BandPlitter8, distribute something and pan it around, change out distribution
* Voices: haave the vowels play like Pbind, and from time to time a longer voice(a word, a a sentence). Add the bird dataset!
*/

Buffer.freeAll; //ojo tu que borra todo


/*
TODOS:
 -Folder path to Datasets, do not copy in SC folder!
*/


(
//================================================================
//========================= FUNCTIONS ============================
//================================================================
var addBuffersToDict= { |folderPath, soundsDict|
	var soundFilePaths = (folderPath +/+ "*").pathMatch;
	var buffers = soundFilePaths.collect({|path| Buffer.readChannel(s, path, channels:[0]) });
	postf("  \n ... loading % subfolder: \n", folderPath.folderName);

	buffers.do({|buf|
		// like this, it has easy acces such as ~soundsDict[9000]
		var key = soundsDict.size;
		soundsDict.add(key -> buf ) });
};



//creates a dict from the folders/files inside the given folder, flat Dictionary
~createSoundsFlatDict = {
	|soundsFolderPath=("shortSounds".resolveRelative)|
	var soundsDict = Dictionary.new;
	var subfolders = PathName(soundsFolderPath).entries;

	postf(" % subfolders found... \n", subfolders.size);

	if(subfolders == 0)
	{
		addBuffersToDict.(soundsFolderPath, soundsDict)}
	{
		subfolders.do{ addBuffersToDict.( _ , soundsDict)}};

	"sounds loaded into buffers...".postln;
	soundsDict;
};


/*
Creates a dict, organized in subfolders as (subolder:BufferList, subolder:BufferList)
Expects a subfolder structure
*/
~createSoundsFolderedDict = {
	|soundsFolderPath=("shortSounds".resolveRelative)|
	var soundsDict = Dictionary.new;
	var subfolders = PathName(soundsFolderPath).entries;

	subfolders.do({ |subfolder|
		var subfolderName = subfolder.folderName;
		var subfolderDict = Dictionary.new;
		addBuffersToDict.( subfolder, subfolderDict);
		soundsDict.add( subfolderName.asSymbol -> subfolderDict );
	});

	"\n ...loading complete, following keys:".postln;
	soundsDict.keys.do({ |key| key.postln });

	soundsDict;
};

~createSoundsLoadFolder = {
	|soundsFolderPath|
	var soundsDict = Dictionary.new;
	var subfolder =  PathName(soundsFolderPath);

	var subfolderName = subfolder.folderName;
	var subfolderDict = Dictionary.new;
	addBuffersToDict.( subfolder, subfolderDict);
	soundsDict.add( subfolderName.asSymbol -> subfolderDict );

	"\n ...loading complete, following keys:".postln;
	soundsDict.keys.do({ |key| key.postln });

	soundsDict;
};

)




//DATASET FOLDERS:
(
var datasetFolder = PathName("/Users/lluissuros/Documents/Datasets/");

var urban = (datasetFolder +/+ PathName("urban-sound-classification/train/Train/")).postln;
var birds = (datasetFolder +/+  PathName("CLO-43SD-AUDIO/audio/")).postln;
var ff1010bird = (datasetFolder +/+ PathName("ff1010bird_wav/")).postln;
var esc50 = (datasetFolder +/+ PathName("ESC-50-master/audio/")).postln;

var mySubfolders = [esc50];
~soundsFoldered = ~createSoundsLoadFolder.(esc50.fullPath);

)


(
var subfolder_ = ["yes"];
var test = subfolder_ ? "test";
test.postln;
)




x = Dictionary.new();
y = ~addBuffersToDict.(PathName("shortSounds".resolveRelative).entries[0], x);
y.at(500)
x[1000]

//test
PathName("shortSounds".resolveRelative).entries[0]


~sounds = ~createSoundsFlatDict.();
//this will allow more control...
~soundsFoldered[\birdsAudio].size
~soundsFoldered[\ff1010bird_wav].size
~soundsFoldered.keys.do({ |key| key.postln });




(
SynthDef(\simpleBufPlayer, {
	arg buf=0, rate=1, sPos=0, amp=0.1, out=0, loop=0,
	atk=1.1, sus=0.3, rel=1.1;
	var sig, env;
	env = EnvGen.kr(Env([0,1,1,0],[atk,sus,rel],[1,0,-1]),doneAction:2);
	sig = PlayBuf.ar(1, buf, rate*BufRateScale.ir(buf),startPos:sPos, loop:loop, doneAction:2);
	Out.ar(out, Mix.ar(sig*env*amp));
}).add;
)


(
SynthDef(\substractionMovingQBuf, {
	|out=0, freq=1100, amp=0.1, attack=1, sustain=3, release=9, pan=0, panwidth=2, numChans=4, revMix=0.2,
	sPos=0, loop=0, rate=1, buf|
	var env, sig, compSig, drySig, wetSig, rq;


	//keep total rq above zero!
	var factor =  (10/freq) ;
	//freq.poll(Impulse.kr(5));

	//TODO: Check XFade2 for equal power cross fade between two inputs
	//TODO better: this is what I'm doing: { Resonz.ar(WhiteNoise.ar(0.5), 2000, XLine.kr(1, 0.001, 8)) }.play

    rq = factor * XLine.kr(100,1,release) + LFNoise1.kr(0.1,factor,factor);
    env = EnvGen.kr(Env.linen(attack, sustain, release),doneAction:2);
    //env = EnvGen.kr(Env.perc(release, attack),doneAction:2); //reverse


	buf = PlayBuf.ar(1, buf, rate*BufRateScale.ir(buf),startPos:sPos, loop:loop, doneAction:2);


    sig = BPF.ar(buf, freq, rq);
    compSig =   Compander.ar(sig, sig, thresh: 0.1,slopeBelow: 1, slopeAbove: 0.15, clampTime: 0.01, relaxTime: 0.01,mul:1.5);
    compSig = sig * env;

    drySig = compSig * (1-revMix);
    //SUPEREXPENSIVE: use cheaper reverb, and think about routing to only 4 out_reverbs
    wetSig = GVerb.ar(compSig*revMix);
    sig = (drySig + wetSig) * amp;


    // -1 to +1 is used to modulate the pan along circle.
    Out.ar(out, PanAz.ar(2, Mix.ar(sig), pan) );
	}
).add;
)





(

~inOrder = Task({
	(0..~sounds.size-1).pyramid(3).do({ arg i;
		var out = if(i.even){0}{1};
		var soundDur = ~sounds[i].duration;
		i.postln;

		Synth(\simpleBufPlayer,[
			\buf, ~sounds[i],
			\out, out,
			\amp, 0.03
		]);

		(soundDur/[10,20,5,2].choose).wait;
    });
});
)

~inOrder.start;
~inOrder.pause;
~inOrder.resume;
~inOrder.reset;
~inOrder.stop;


(
//not so random but quite
~inRandom = Task({
	10000.do({
		var i = ~sounds.size.rand;
		var out = if(i.even){0}{1};

		var soundDur = ~sounds[i].duration;
		i.postln;

		Synth(\simpleBufPlayer,[
			\buf, ~sounds[i],
			\out, out,
			\amp, 0.03
		]);

		(1/[10,20,50,30].choose).wait;
    });
});
)


~inRandom.start;
~inRandom.pause;
~inRandom.resume;
~inRandom.reset;
~inRandom.stop;


(
var folderName = \audio;
~folderRandom.stop;
//var folderName = \ff1010bird_wav;
~folderRandom = Task({
	var folderDict = ~soundsFoldered[folderName];
	2000.do({
		var i = folderDict.size.rand;
		var out = if(i.even){0}{1};
		var soundDur = folderDict[i].duration;
		var waitTime = soundDur/([10,20,50,30]*2).choose;
		i.postln;

		Synth(\substractionMovingQBuf,[
			\buf, folderDict[i],
			\out, out,
			\amp, 0.03,
			\atk, waitTime*3,
			\sus, waitTime,
			\rel, waitTime*3,
		]);

		waitTime.wait;
    });
});
)


(
~activefolder = ~soundsFoldered[\audio];
//nice sounds ESC-50-master/audio/:
~niceSoundsESC = [2, 1050, 900, 20, 1658, 571, 1160, 1370, 1099, 1829, 34, 689, 709, 630, 738, 1844, 107, 1492, 450, 411, 1084, 492, 611, 950, 1629, 1297];


~getRandBuf = {
	var index = ~activefolder.size.rand;
	index.postln;
	~getBufAt.stop;
	~activefolder.at(index);
};

~getBufAt = {|index|
	~getRandBuf.stop;
	index.postln;
	~activefolder.at(index);
};

~getNiceESC = {
	var index = ~niceSoundsESC.at(~niceSoundsESC.size.rand);
	index.postln;
	~getBufAt.(index);
};

)


//longtime = 1050, 900

(
Pbindef(\movingQBufs,
	\instrument, \substractionMovingQBuf,
	\index, Pdefn(\indexTest),
	\buf, Pfunc(~getBufAt.(1050)).stutter(10),
	\dur, Pseq([3,5,7]/10,inf),
	\loop, 1,
	\release, 1,
	\attack, 3,
	\sustain,5,
	\amp, Prand([0.1,0.2,0.3],inf),
	\revMix, Prand([1,0.8,0.5,0.3,0.1],inf),
	\out, 0, //start for panning
	\pan, Pseq(Array.series(21, -1, 0.1) ,inf),
	\panwidth, 1,
	\degree, Pseq([0 ,3, 5, 6, 7]-2,inf),
	\octave, Pseq([2,3,4,5,6],inf)
);
)

Pbindef(\movingQBufs).play;
Pbindef(\movingQBufs).stop;


//play with release
(
Pbindef(\movingQBufs, \buf, Pfunc(~getBufAt.(1050)).stutter(10),
	\release, Pseq((1..100).mirror/10,inf).trace);
)


Pbindef(\movingQBufs, \dur, Pseq([3,5,7]/20,inf));
Pbindef(\movingQBufs, \degree, Pseq([0,3,6],inf)).stutter(4);
Pbindef(\movingQBufs, \octave, Pseq([2,3,7,5,2,11],inf)).stutter(4);
Pbindef(\movingQBufs, \revMix, Pseq([0.8,0.9,1],inf));
Pbindef(\movingQBufs, \amp, Prand([0.1,0.2,0.3]*2,inf));


~folderRandom.start;
~folderRandom.pause;
~folderRandom.resume;
~folderRandom.reset;
~folderRandom.stop;



