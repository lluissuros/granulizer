/*
* BandPlitter8, distribute something and pan it around, change out distribution
* Voices: haave the vowels play like Pbind, and from time to time a longer voice(a word, a a sentence). Add the bird dataset!
*/

Buffer.freeAll; //ojo tu que borra todo


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

)






x = Dictionary.new();
y = ~addBuffersToDict.(PathName("shortSounds".resolveRelative).entries[0], x);
y.at(500)
x[1000]

//test
PathName("shortSounds".resolveRelative).entries[0]


~sounds = ~createSoundsFlatDict.();
//this will allow more control...
~soundsFoldered = ~createSoundsFolderedDict.()
~soundsFoldered[\birdsAudio].size
~soundsFoldered.keys.do({ |key| key.postln });




(
SynthDef(\simpleBufPlayer, {
	arg buf=0, rate=1, sPos=0, amp=0.1, out=0, loop=0,
	atk=0.1, sus=0.2, rel=0.1;
	var sig, env;
	env = EnvGen.kr(Env([0,1,1,0],[atk,sus,rel],[1,0,-1]),doneAction:2);
	sig = PlayBuf.ar(1, buf, rate*BufRateScale.ir(buf),startPos:sPos, loop:loop, doneAction:2);
	Out.ar(out, Mix.ar(sig*env*amp));
}).add;
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
//not so random but quite
~folderRandom = Task({
	var folderDict = ~soundsFoldered[\birdsAudio];
	1000.do({
		var i = folderDict.size.rand;
		var out = if(i.even){0}{1};
		var soundDur = folderDict[i].duration;
		i.postln;

		Synth(\simpleBufPlayer,[
			\buf, folderDict[i],
			\out, out,
			\amp, 0.03
		]);

		(1/[10,20,50,30].choose).wait;
    });
});
)

~soundsFoldered[\birdsAudio][200].duration

~folderRandom.start;
~folderRandom.pause;
~folderRandom.resume;
~folderRandom.reset;
~folderRandom.stop;



