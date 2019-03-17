(
SynthDef(\simpleBufPlayer, {
	arg buf=0, rate=1, sPos=0, amp=0.1, out=0, loop=0;
	var sig, env;
	sig = PlayBuf.ar(1, buf, rate*BufRateScale.ir(buf),startPos:sPos, loop:loop, doneAction:2);
	Out.ar(out, Mix.ar(sig*amp));
}).add;

~sampleBus = ~findBufferByName.("Fargo - gets into car");
~sampleBusLoop = ~findBufferByName.("tape");
)

fa_Nompeng
fa_actuallized
fa_bats
fa_croacks
fa_daniBateria
fa_hasAJob
fa_intoTheCar
fa_localMusicRadio
fa_niceLocals

~logAllSounds.()
~sampleBus = ~findBufferByName.("fa_hasAJob");
~sampleBus = ~findBufferByName.("fa_intoTheCar");
~sampleBus = ~findBufferByName.("fa_actuallized");

~sampleBus = ~findBufferByName.("fa_daniBateria");
~sampleBus = ~findBufferByName.("fa_niceLocals");
~sampleBus = ~findBufferByName.("fa_bats");


~sampleBusLoop = ~findBufferByName.("tape");

~samplesOutLoop= 3;
~samplesOut= 5;//bluetooh

(
x.free;
x = Synth(\simpleBufPlayer, [\buf, ~sampleBusLoop, \amp, 0.2, \out, ~samplesOutLoop, \loop:1]);
)


(
y.free;
y = Synth(\simpleBufPlayer, [\buf, ~sampleBus, \amp, 0.2, \out, ~samplesOut]);
)

y.free;
x.free;




