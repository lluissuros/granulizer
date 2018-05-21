
var win, label1, label2, label3;
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

		//General Controls
		win.view.decorator.nextLine;
		label3 = StaticText(win, win.view.bounds.width @ 24);
		label3.string = "General Controls";
		label3.stringColor = Color.black;
		label3.background = Color.white;
		label3.align = \center;

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
		label2.string = "Playing Sounds";
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

win.front;
