(
s = Server.local;
//s.options.numOutputBusChannels = 4;
s.options.numOutputBusChannels = 2;
o = Server.internal.options;
o.memSize = 2 ** 19;
x = ProxySpace.push(s);
x.fadeTime = 0;
s.boot;
)


v = v ? ();//morpher object
v.message = "test1";
v.message = "test2";

(
v.test = TaskProxy({
	    var message = v.message;
		inf.do { |item, i|
		message.postln;
		0.2.wait;
		};
	};
).quant_(0);		// no quantization so the task starts immediately
)


v.message = "test1";
v.message = "test2";
v.arrayTest = [1,2,3];
v.arrayTest = [4,5,6,7,8,9];

v.test.stop.play


(
v.test = TaskProxy({
		inf.do { |item, i|
		v.arrayTest.wrapAt(i).postln;
		v.message.postln;
		i.postln;
		0.2.wait;
		};
	};
).quant_(0);		// no quantization so the task starts immediately
)

[5,5,6,6,1,1,1,1,1,1].collect({|el, i| i.postln})
a = nil;
a = a ? List.new(0);
a.add(\test)
a.add(\test2)
a.remove(\test2)
a