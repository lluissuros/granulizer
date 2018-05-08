

//NANOKONTROL: I need to actuallize to new Dictionary notation
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
		var bufnum = m.samples.getsIntoCar;
		("gets into car").postln;
		~sample = {Pan4.ar(PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), loop: 0)) * ~sampleAmp};
	},
	32,0);

MIDIdef.cc(\buttonPlayEveryoneHasAJob,
	{
		var bufnum = m.samples.everyOneHAsAJob;
		("everyOneHAsAJob").postln;
		~sample = {Pan4.ar(PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), loop: 0)) * ~sampleAmp};
	},
	48,0);

MIDIdef.cc(\buttonPlayActuallizedFully,
	{
		var bufnum = m.samples.actualizedFully;
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
		m.discardButton= m.discardButton.not;
		if(m.discardButton,{},{
			var key;
			m.soundsIndex = m.soundsIndex-1;
			key = m.sounds.keys.asArray.wrapAt(m.soundsIndex);
			m.targetSound = key.asSymbol;
			("targetSound: " + key).postln;
		})
	},
	61,0);

MIDIdef.cc(\buttonNextNavigation,
	{
		m.discardButton= m.discardButton.not;
		if(m.discardButton,{},{
			var key;
			m.soundsIndex = m.soundsIndex+1;
			key = m.sounds.keys.asArray.wrapAt(m.soundsIndex);
			m.targetSound = key.asSymbol;
			("targetSound: " + key).postln;
		})
	},
	62,0);


MIDIdef.cc(\buttonPreviousToTarget,
	{
		m.discardButton= m.discardButton.not;
		if(m.discardButton,{},{
			m.targetSound = m.previousSound.copy;
			("targetSound: " + m.targetSound).postln;
		})
	},
	43,0);

MIDIdef.cc(\buttonEntryGosh,
	{
		m.discardButton= m.discardButton.not;
		if(m.discardButton,{},{
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
		m.discardButton= m.discardButton.not;
		if(m.discardButton,{},{
			m.morph.stop.play;
			("MORPH! ").postln;
		})
	},
	41,0);
)

