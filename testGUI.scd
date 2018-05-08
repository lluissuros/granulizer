
m.sounds.size
m.sounds.keys.asArray.sort({ |a, b| a > b }).reverse; //order alphabetically
m.sounds.at(25)


//GUI IMPORTANT
m.morphMultiple.play
m.cycle



(
// create an array of buttons representing available sounds.
var win, label1, label2;
var soundsSorted = m.sounds.keys.asArray.sort({ |a, b| a > b }).reverse; //order alphabetically

win = Window("Granulizer", Rect(128, 64, 840, 360));
win.name = "Granulizer";

win.drawFunc = Routine {
    loop {
		var playButton, freeButton;
		win.view.removeAll;
		win.view.decorator = FlowLayout(win.view.bounds);

		//general controls
		playButton = Button(win, Rect(0,0, 75, 24));
		playButton.states = [["playMorph", Color.black, Color.green], ["stopMorph", Color.white, Color.blue]];
		playButton.action = {|btn|
			btn.string.postln;
			if(btn.string == "stopMorph")
			  {	 ~grain.play; ~sample.play; m.morphMultiple.play; "play".postln;}
			  {	 m.morphMultiple.stop;  "stop".postln;}
		};

		freeButton = Button(win, Rect(0,0, 75, 24));
		freeButton.states = [["Free", Color.black, Color.red]];
		freeButton.action = {|btn|
			  {	 ~grain.stop; ~sample.stop; m.morphMultiple.stop;}
		};

		//Available Sounds
		win.view.decorator.nextLine;
		label1 = StaticText(win, win.view.bounds.width @ 24);
		label1.string = "Available Sounds";
		label1.stringColor = Color.black;
		label1.background = Color.white;
		label1.align = \center;

		win.view.decorator.nextLine;
		soundsSorted.do({ arg sound;
			var btn = Button(win, Rect(0,0, 75, 24));
			btn.states = [[sound, Color.black, Color.rand]];
			btn.string = sound;
			btn.action = { |btn|
				m.addSound(btn.string);
				win.refresh;
		}});

		//Current Sounds
		win.view.decorator.nextLine;
		label2 = StaticText(win, win.view.bounds.width @ 24);
		label2.string = "Available Sounds";
		label2.stringColor = Color.black;
		label2.background = Color.white;
		label2.align = \center;

		m.currentSounds.do({ arg sound;
			var height = 16;
			var btn = Button(win, Rect(0,0, 75, height));
			var slider;
			var spec = \db.asSpec;

			btn.states = [[sound, Color.black, Color.rand]];
			btn.string = sound;
			btn.action = { |btn|
				m.removeSound(btn.string);
				win.refresh;
			};

			slider = EZSlider( win,         // parent
              390@height,    // bounds
              "",  // label
              \db.asSpec,     // controlSpec
				{ |sldr|
					m.currentSoundDBs[sound]= sldr.value;
					// {win.refresh}.defer(1)
				}, //action
				m.currentSoundDBs[sound]  //initialValue
			);

			win.view.decorator.nextLine;
		});
        0.yield // stop here, return something unimportant
    }
};

//auto refresh
// { while { win.isClosed.not } { win.refresh; 5.wait; } }.fork(AppClock);

win.front;
)






// MIXER, use this for currentSounds
////////////////////////////////////////////////////////////7
(
// create a GUI for a mixer.
var w, v, s, n;

w = Window("mixer", Rect(128, 64, 340, 360));
w.view.decorator = f = FlowLayout(w.view.bounds,Point(4,4),Point(4,2));
17.do({ arg i;
	var v, s, n, spec, p, height = 16;

	v = StaticText(w, Rect(0, 0, 56, height+2));
	if (i == 0, {
		v.font = Font("Helvetica", 13).boldVariant;
		v.stringColor = Color.yellow;
	},{
		v.font = Font("Helvetica", 12);
		v.stringColor = Color.white;
	});
	v.align = \right;
	s = Slider(w, Rect(0, 0, 182, height));
	s.resize = 2;
	spec = \db.asSpec;
	s.action = {
		var db;
		db = spec.map(s.value).round(0.1);
		//v.string = if (db < -100, { "-inf" },{ db.asString ++ " dB" });
		v.string = db.asString ++ " dB" ;
	};
	s.action.value;

	n = StaticText(w, Rect(0, 0, 72, height+2));
	if (i == 0, {
		n.string = "Master";
		n.stringColor = Color.yellow;
		n.font = Font("Helvetica", 13).boldVariant;
	},{
		n.string = "Channel " ++ i;
		n.stringColor = Color.white;
		n.font = Font("Helvetica", 12);
	});
	n.background = Color.rand(0.1,0.5);
	n.resize = 3;

	f.nextLine;
});
w.view.background = Color.blue;
w.view.background = HiliteGradient(Color.blue, Color.green, \h, 128, 0.3);
w.front;
w.refresh;
)














//HERE there is a 2D slider
////////////////////////////////////////////////////////////////////////

(
// jumble of controls

w = Window.new;

a = Slider(w, Rect(20,20,114,24));

b = Button(w, Rect(20, 50, 80, 24));

b.states = [["Start Sound", Color.red, Color.grey(0.9)],["Stop Sound", Color.white, Color.grey(0.4)]];

c = DragSource(w, Rect(120, 50, 80, 24));
c.string = "DragSource";
c.font = Font("Helvetica", 12);
c.beginDragAction = { arg view; [view.object,view.object]; };
//c.stringColor = Color(0.5, 0.2, 0.7);


d = DragSink(w, Rect(120, 85, 80, 24));
d.string = "DragSink";

z = CompositeView(w, Rect(0,100,800,300));

l = Slider(z, Rect(20,120,180,24));

//l.backColor = Color(0,1,0);
//l.knobColor = Color(1,0,0);
l.step = 1/10;

r = RangeSlider(z, Rect(20,170,180,24));
r.step = 1/20;

q = RangeSlider(z, Rect(220, 170, 24, 180));

t = Slider2D(w, Rect(220,20, 80, 80));
t.action = { arg slider; c.object = slider.y.postln.round(0.001); };

p = Slider(z, Rect(248, 170, 24, 180));
p.action = { arg slider; slider.value.postln; };

w.front;
w.refresh;
)

// properties you can set in the window above.
w.view.background = Color.blue;	// fallback on SwingOSC
w.view.background = HiliteGradient(Color.blue, Color.red, \v, 128, 0.2);
r.background = Color.gray; r.hi = 0.2;

z.visible = false;
z.visible = true;

z.enabled = false;	// NO EFFECT WITH SWINGOSC!
z.enabled = true;

b.visible = false;
b.visible = true;

b.enabled = false;
b.enabled = true;

c.visible = false;
c.visible = true;

b.enabled = false;
b.visible = false;
b.visible = true;
b.enabled = true;

t.enabled = false;
t.enabled = true;
t.visible = false;
t.visible = true;

r.step = 0;

t.canFocus = false;
t.canFocus = true;
t.canFocus = false;

c.object = Point(3,4);

c.object = [1, 2, 3, 4];
c.object = 123.456;
c.object = WhiteNoise.ar(1);
c.object = WhiteNoise;
c.object = true;

t.resize = 2;
t.resize = 5;
t.resize = 7;

w.alpha = 0.7;
w.close;

////////////////////////////////////////////////////////////////////////