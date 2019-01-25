(
var win;

//first for songs, later for each

//sort later?
//var soundsTest = ~sounds[\songs].sort({ |a, b| a > b }).reverse; //order alphabetically

var materialColorsCSS = ["#ff5722", "#f44336", "#e91e63", "#9c27b0", "#673ab7", "#3f51b5", "#2196f3", "#03a9f4", "#00bcd4", "#009688", "#4caf50", "#8bc34a", "#cddc39", "#fdd835", "#ffc107", "#ff9800", "#ff5722"];
var colors = materialColorsCSS.collect({|color| Color.fromHexString(color)});
var colorsForBufName = Dictionary.new;

var createAvailableSounds = {
	StaticText(win, win.view.bounds.width @ 54)
	.string_("Available Sounds")
	.font_(Font("Helvetica", 40))
	.background_(Color.fromHexString("#ff5252"))
	.stringColor_(Color.white)
	.align_(\center);

	~sounds.keysDo({
		|folderName, index|
		var color = colors.at(index);
		win.view.decorator.nextLine;

		StaticText(win, 200 @ 24)
		.string_(folderName.asString.toUpper)
		.background_(color)
		.font_(Font("Helvetica", 15))
		.stringColor_(Color.white)
		.align_(\center);
		win.view.decorator.nextLine;

		~sounds[folderName.asSymbol].do({ arg buf, index;
			var fileName = ~getBufFileName.(buf);
			var btn = Button(win, Rect(0,0, 75, 24));
			var alpha = (index / (~sounds[folderName.asSymbol].size) ).linlin(0,1,0.6,1);
			var btnColor = color.multiply(alpha);

			colorsForBufName.put(fileName, btnColor);

			btn.states = [[fileName, Color.white, btnColor]];
			btn.action = { |btn|
				btn.string.postln;
				~activeSounds.add(~findBufferByName.(btn.string));
				win.refresh;
		}});
		win.view.decorator.nextLine;
		win.view.decorator.nextLine;
		win.view.decorator.nextLine;
	});
};

var createCurrentSounds = {
	win.view.decorator.nextLine;

	StaticText(win, win.view.bounds.width @ 54)
	.string_("Playing Sounds")
	.font_(Font("Helvetica", 40))
	.background_(Color.fromHexString("#ffb300"))
	.stringColor_(Color.white)
	.align_(\center);

	~activeSounds.do({  arg buf;
		var fileName = ~getBufFileName.(buf);
		var btn = Button(win, 100 @ 54)
		.states_([
			[fileName,
				Color.white,
				colorsForBufName.at(fileName)]])
		.action_({
			|btn|
			~removeActiveSound.(btn.string);
			win.refresh;
		});
	});
};

var createPlayStopButtons = {
	var button = Button(win, 100 @ 54)
	.states_([
		["STOP", Color.white, Color.red],
		["PLAY", Color.white, Color.green]
	])
	.font_(Font.defaultMonoFace, 20)
	.action_({
		|btn|
		if(btn.value == 0, {
			Pbindef(\morphPlayer).play;
		}, {
			Pbindef(\morphPlayer).stop;
		});
	});

	if(Pbindef(\morphPlayer).isPlaying, {button.value = 0 }, {button.value = 1});
	win.view.decorator.nextLine;
};

var drawFunction = {
	var playButton, freeButton;
	win.view.removeAll;
	win.view.decorator = FlowLayout(win.view.bounds);
	win.view.decorator.nextLine;

	createPlayStopButtons.();
	createAvailableSounds.();
	createCurrentSounds.();
};


Window.closeAll;

win =
Window("Granulizer", Rect(0, 0, Window.screenBounds.width, Window.screenBounds.height), scroll:true)
.name_("Granulizer")
.front
.alwaysOnTop_(true)
.background_(Color.fromHexString("#fff8e1"))
.drawFunc_(drawFunction);


Routine.new({
	loop {
		win.refresh;
		1.yield;
}}).play(AppClock);

)