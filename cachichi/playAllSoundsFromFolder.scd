/*
* BandPlitter8, distribute something and pan it around, change out distribution
* Voices: haave the vowels play like Pbind, and from time to time a longer voice(a word, a a sentence). Add the bird dataset!
*/

~catAndDogsPath = "/Users/lluissuros/Documents/Datasets/audio-cats-and-dogs/cats_dogs/";
~ocellsPath = "/Users/lluissuros/Documents/Datasets/CLO-43SD-AUDIO/audio/"
~fargoVowelsPath = "/Users/lluissuros/Music/Praat/english_vowels_fargo1/vowels/"
~shortSoundsPath = "/Users/lluissuros/Music/SuperCollider/SuperCollider Projects/granulizer/cachichi/shortSounds/"

(
//load Sounds from a folder
var soundFileNames, audioFolderPath, buffers;
//var soundsFilenames = ("sounds".resolveRelative +/+ "*").pathMatch;
~sounds = Dictionary.new;
audioFolderPath = ~shortSoundsPath;
soundFileNames = (audioFolderPath +/+ "*").pathMatch;
buffers = soundFileNames.collect({arg path; Buffer.readChannel(s, path, channels:[0]) });
buffers.do({ arg n, index; ~sounds.add(index -> n) });

"sounds loaded into buffers...".postln;
)



(
SynthDef(\simpleBufPlayer, {
	arg buf=0, rate=1, sPos=0, amp=0.1, out=0, loop=0;
	var sig, env;
	sig = PlayBuf.ar(1, buf, rate*BufRateScale.ir(buf),startPos:sPos, loop:loop, doneAction:2);
	Out.ar(out, Mix.ar(sig*amp));
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
	    (0..~sounds.size-1).perfectShuffle.perfectShuffle.do({
		var i = ~sounds.size.rand;
		var out = if(i.even){0}{1};

		var soundDur = ~sounds[i].duration;
		i.postln;

		Synth(\simpleBufPlayer,[
			\buf, ~sounds[i],
			\out, out,
			\amp, 0.03
		]);

		(soundDur/[10,20,50,30].choose).wait;
    });
});
)


~inRandom.start;
~inRandom.pause;
~inRandom.resume;
~inRandom.reset;
~inRandom.stop;







