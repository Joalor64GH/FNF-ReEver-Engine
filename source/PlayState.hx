package;

import stages.StageMe;
import shaders.ColorSwap;
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var deathCounter:Int = 0;
	public static var practiceMode:Bool = false;

	var halloweenLevel:Bool = false;

	public var vocals:FlxSound;
	public var vocalsFinished:Bool = false;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Boyfriend;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];

	public var strumLine:FunkinSprite;

	public var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<FunkinSprite>;
	public var playerStrums:FlxTypedGroup<FunkinSprite>;

	public var camZooming:Bool = false;
	public var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	public var healthBarBG:FunkinSprite;
	public var healthBar:FlxBar;

	public var generatedMusic:Bool = false;
	public var startingSong:Bool = false;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];

	public static var seenCutscene:Bool = false;

	var talking:Bool = true;
	var songScore:Int = 0;
	var scoreTxt:FlxText;

	var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public static var campaignScore:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	var inCutscene:Bool = false;

	var camPos:FlxPoint;

	public static var instance:PlayState = null;

	override public function create()
	{
		instance = this;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.sound.cache(Paths.inst(PlayState.SONG.song));
		FlxG.sound.cache(Paths.voices(PlayState.SONG.song));

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new SwagCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		switch (SONG.song.toLowerCase())
		{
			case 'senpai':
				dialogue = CoolUtil.coolTextFile(Paths.txt('senpai/senpaiDialogue'));
			case 'roses':
				dialogue = CoolUtil.coolTextFile(Paths.txt('roses/rosesDialogue'));
			case 'thorns':
				dialogue = CoolUtil.coolTextFile(Paths.txt('thorns/thornsDialogue'));
		}

		var stageMe:StageMe = new StageMe("stage");
		add(stageMe);

		var gfVersion:String = 'gf';

		switch (curStage)
		{
			case 'limo':
				gfVersion = 'gf-car';
			case 'mall' | 'mallEvil':
				gfVersion = 'gf-christmas';
			case 'school' | 'schoolEvil':
				gfVersion = 'gf-pixel';
			case 'tank':
				gfVersion = 'gf-tankmen';
		}

		if (SONG.song.toLowerCase() == 'stress')
			gfVersion = 'pico-speaker';

		gf = new Character(400, 130, gfVersion);
		gf.scrollFactor.set(0.95, 0.95);

		dad = new Character(100, 100, SONG.player2);

		camPos = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		switch (SONG.player2)
		{
			case 'gf':
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				if (isStoryMode)
				{
					camPos.x += 600;
					tweenCamIn();
				}
			case "spooky":
				dad.y += 200;
			case "monster":
				dad.y += 100;
			case 'monster-christmas':
				dad.y += 130;
			case 'dad':
				camPos.x += 400;
			case 'pico':
				camPos.x += 600;
				dad.y += 300;
			case 'parents-christmas':
				dad.x -= 500;
			case 'senpai' | 'senpai-angry':
				dad.x += 150;
				dad.y += 360;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'spirit':
				dad.x -= 150;
				dad.y += 100;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'tankman':
				dad.y += 180;
		}

		boyfriend = new Boyfriend(770, 450, SONG.player1);

		add(gf);

		add(dad);
		add(boyfriend);

		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;

		Conductor.songPosition = -5000;

		strumLine = new FunkinSprite(0, 50);
		strumLine.makeGraphic(FlxG.width, 10);

		if (SaveData.get("downscroll"))
			strumLine.y = FlxG.height - 150; // 150 just random ass number lol

		strumLine.scrollFactor.set();

		strumLineNotes = new FlxTypedGroup<FunkinSprite>();
		add(strumLineNotes);

		// fake notesplash cache type deal so that it loads in the graphic?

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		var noteSplash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(noteSplash);
		noteSplash.alpha = 0.1;

		add(grpNoteSplashes);

		playerStrums = new FlxTypedGroup<FunkinSprite>();

		generateSong();

		// add(strumLine);

		camFollow = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		healthBarBG = new FunkinSprite(0, FlxG.height * 0.9);
		healthBarBG.loadGraphic(Paths.image('healthBar'));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		if (SaveData.get('downscroll'))
			healthBarBG.y = FlxG.height * 0.1;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		// healthBar
		add(healthBar);

		scoreTxt = new FlxText(healthBarBG.x + healthBarBG.width - 190, healthBarBG.y + 30, 0, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		add(scoreTxt);

		iconP1 = new HealthIcon(SONG.player1, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(SONG.player2, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		grpNoteSplashes.cameras = [camHUD];
		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		doof.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		if (isStoryMode && !seenCutscene)
		{
			seenCutscene = true;

			switch (curSong.toLowerCase())
			{
				case "winter-horrorland":
					var blackScreen:FunkinSprite = new FunkinSprite(0, 0);
					blackScreen.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;

					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						remove(blackScreen);
						FlxG.sound.play(Paths.sound('Lights_Turn_On'));
						camFollow.y = -2050;
						camFollow.x += 200;
						FlxG.camera.focusOn(camFollow.getPosition());
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(0.8, function(tmr:FlxTimer)
						{
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									startCountdown();
								}
							});
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					schoolIntro(doof);
				default:
					startCountdown();
			}
		}
		else
		{
			switch (curSong.toLowerCase())
			{
				default:
					startCountdown();
			}
		} 

		super.create();
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		var black:FunkinSprite = new FunkinSprite(-100, -100);
		black.makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FunkinSprite = new FunkinSprite(-100, -100);
		red.makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FunkinSprite = new FunkinSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * daPixelZoom));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += senpaiEvil.width / 5;

		camFollow.setPosition(camPos.x, camPos.y);

		if (SONG.song.toLowerCase() == 'roses' || SONG.song.toLowerCase() == 'thorns')
		{
			remove(black);

			if (SONG.song.toLowerCase() == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
			else
				FlxG.sound.play(Paths.sound('ANGRY'));
			// moved senpai angry noise in here to clean up cutscene switch case lol
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
				tmr.reset(0.3);
			else
			{
				if (dialogueBox != null)
				{
					inCutscene = true;

					if (SONG.song.toLowerCase() == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
								swagTimer.reset();
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
						add(dialogueBox);
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer = new FlxTimer();
	var perfectMode:Bool = false;

	function startCountdown():Void
	{
		inCutscene = false;
		camHUD.visible = true;

		generateStaticArrows(0);
		generateStaticArrows(1);

		talking = false;
		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer.start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			// this just based on beatHit stuff but compact
			if (swagCounter % gfSpeed == 0)
				gf.dance();
			if (swagCounter % 2 == 0)
			{
				if (!boyfriend.animation.curAnim.name.startsWith("sing"))
					boyfriend.playAnim('idle');
				if (!dad.animation.curAnim.name.startsWith("sing"))
					dad.dance();
			}
			else if (dad.curCharacter == 'spooky' && !dad.animation.curAnim.name.startsWith("sing"))
				dad.dance();
			if (generatedMusic)
				notes.sort(sortNotes, FlxSort.DESCENDING);

			var introSprPaths:Array<String> = ["ready", "set", "go"];
			var altSuffix:String = "";

			if (curStage.startsWith("school"))
			{
				altSuffix = '-pixel';
				introSprPaths = ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel'];
			}

			var introSndPaths:Array<String> = ["intro3" + altSuffix, "intro2" + altSuffix,
				"intro1" + altSuffix, "introGo" + altSuffix];

			if (swagCounter > 0)
				readySetGo(introSprPaths[swagCounter - 1]);
			FlxG.sound.play(Paths.sound(introSndPaths[swagCounter]), 0.6);

			/* switch (swagCounter)
			{
				case 0:
					
				case 1:
					
				case 2:
					
				case 3:
					
			} */

			swagCounter += 1;
		}, 4);
	}

	function readySetGo(path:String):Void
	{
		var spr:FunkinSprite = new FunkinSprite();
		spr.loadGraphic(Paths.image(path));
		spr.scrollFactor.set();

		if (curStage.startsWith('school'))
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.updateHitbox();
		spr.screenCenter();
		add(spr);
		FlxTween.tween(spr, {y: spr.y += 100, alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				spr.destroy();
			}
		});
	}

	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;

		if (!paused)
			FlxG.sound.playMusic(Paths.inst(SONG.song), 1, false);
		FlxG.sound.music.onComplete = endSong;
		vocals.play();
	}

	private function generateSong():Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(SONG.song));
		else
			vocals = new FlxSound();

		vocals.onComplete = function()
		{
			vocalsFinished = true;
		};
		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
					gottaHitNote = !section.mustHitSection;

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.altNote = songNotes[3];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
						sustainNote.x += FlxG.width / 2; // general offset
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
					swagNote.x += FlxG.width / 2; // general offset
			}
		}

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	// Now you are probably wondering why I made 2 of these very similar functions
	// sortByShit(), and sortNotes(). sortNotes is meant to be used by both sortByShit(), and the notes FlxGroup
	// sortByShit() is meant to be used only by the unspawnNotes array.
	// and the array sorting function doesnt need that order variable thingie
	// this is good enough for now lololol HERE IS COMMENT FOR THIS SORTA DUMB DECISION LOL
	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return sortNotes(FlxSort.ASCENDING, Obj1, Obj2);
	}

	function sortNotes(order:Int = FlxSort.ASCENDING, Obj1:Note, Obj2:Note)
	{
		return FlxSort.byValues(order, Obj1.strumTime, Obj2.strumTime);
	}

	// ^ These two sorts also look cute together ^

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var babyArrow:FunkinSprite = new FunkinSprite(0, strumLine.y);
			var colorswap:ColorSwap = new ColorSwap();
			babyArrow.shader = colorswap.shader;
			colorswap.update(Note.arrowColors[i]);

			switch (curStage)
			{
				case 'school' | 'schoolEvil':
					babyArrow.loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels'), true, 17, 17);
					babyArrow.animation.add('green', [6]);
					babyArrow.animation.add('red', [7]);
					babyArrow.animation.add('blue', [5]);
					babyArrow.animation.add('purplel', [4]);

					babyArrow.setGraphicSize(Std.int(babyArrow.width * daPixelZoom));
					babyArrow.updateHitbox();
					babyArrow.antialiasing = false;

					switch (Math.abs(i))
					{
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.add('static', [0]);
							babyArrow.animation.add('pressed', [4, 8], 12, false);
							babyArrow.animation.add('confirm', [12, 16], 24, false);
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.add('static', [1]);
							babyArrow.animation.add('pressed', [5, 9], 12, false);
							babyArrow.animation.add('confirm', [13, 17], 24, false);
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.add('static', [2]);
							babyArrow.animation.add('pressed', [6, 10], 12, false);
							babyArrow.animation.add('confirm', [14, 18], 12, false);
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.add('static', [3]);
							babyArrow.animation.add('pressed', [7, 11], 12, false);
							babyArrow.animation.add('confirm', [15, 19], 24, false);
					}

				default:
					babyArrow.frames = Paths.getSparrowAtlas('NOTE_assets');
					babyArrow.animation.addByPrefix('green', 'arrowUP');
					babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
					babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
					babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

					babyArrow.antialiasing = true;
					babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

					switch (Math.abs(i))
					{
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 1');
							babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 2');
							babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 4');
							babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 3');
							babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
					}
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			if (!isStoryMode)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			babyArrow.ID = i;

			if (player == 1)
				playerStrums.add(babyArrow);

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
				resyncVocals();

			if (!startTimer.finished)
				startTimer.active = true;
			paused = false;
		}

		super.closeSubState();
	}

	function resyncVocals():Void
	{
		if (_exiting)
			return;

		vocals.pause();
		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		if (vocalsFinished)
			return;

		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float)
	{
		// makes the lerp non-dependant on the framerate
		// FlxG.camera.followLerp = CoolUtil.camLerpShit(0.04);

		#if !debug
		perfectMode = false;
		#end

		// do this BEFORE super.update() so songPosition is accurate
		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition = FlxG.sound.music.time + Conductor.offset; // 20 is THE MILLISECONDS??
			// Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}
			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		super.update(elapsed);

		if (controls.PAUSE && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			// 1 / 1000 chance for Gitaroo Man easter egg
			if (FlxG.random.bool(0.1))
			{
				// gitaroo man easter egg
				FlxG.switchState(new GitarooPause());
			}
			else
			{
				var boyfriendPos = boyfriend.getScreenPosition();
				var pauseSubState = new PauseSubState(boyfriendPos.x, boyfriendPos.y);
				openSubState(pauseSubState);
				pauseSubState.camera = camHUD;
				boyfriendPos.put();
			}
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			FlxG.switchState(new ChartingState());
		}

		if (FlxG.keys.justPressed.NINE)
			iconP1.swapOldIcon();

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.85)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.85)));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		/* if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(new Charting()); */

		#if debug
		if (FlxG.keys.justPressed.ONE)
			endSong();
		if (FlxG.keys.justPressed.EIGHT)
		{
			/* 	 8 for opponent char
			   SHIFT+8 for player char
				 CTRL+SHIFT+8 for gf   */
			if (FlxG.keys.pressed.SHIFT)
				if (FlxG.keys.pressed.CONTROL)
					FlxG.switchState(new AnimationDebug(gf.curCharacter));
				else 
					FlxG.switchState(new AnimationDebug(SONG.player1));
			else
				FlxG.switchState(new AnimationDebug(SONG.player2));
		}
		if (FlxG.keys.justPressed.PAGEUP)
			changeSection(1);
		if (FlxG.keys.justPressed.PAGEDOWN)
			changeSection(-1);
		#end

		if (generatedMusic && SONG.notes[Std.int(curStep / 16)] != null)
		{
			cameraRightSide = SONG.notes[Std.int(curStep / 16)].mustHitSection;

			cameraMovement();
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (curSong == 'Fresh')
		{
			switch (curBeat)
			{
				case 16:
					camZooming = true;
					gfSpeed = 2;
				case 48:
					gfSpeed = 1;
				case 80:
					gfSpeed = 2;
				case 112:
					gfSpeed = 1;
				case 163:
					// FlxG.sound.music.stop();
					// FlxG.switchState(new TitleState());
			}
		}

		if (curSong == 'Bopeebo')
		{
			switch (curBeat)
			{
				case 128, 129, 130:
					vocals.volume = 0;
					// FlxG.sound.music.stop();
					// FlxG.switchState(new PlayState());
			}
		}
		// better streaming of shit

		if (!inCutscene && !_exiting)
		{
			// RESET = Quick Game Over Screen
			if (controls.RESET)
			{
				health = 0;
				trace("RESET = True");
			}

			#if CAN_CHEAT // brandon's a pussy
			if (controls.CHEAT)
			{
				health += 1;
				trace("User is cheating!");
			}
			#end

			if (health <= 0 && !practiceMode)
			{
				// boyfriend.stunned = true;

				persistentUpdate = false;
				persistentDraw = false;
				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				// unloadAssets();

				deathCounter += 1;

				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			}
		}

		while (unspawnNotes[0] != null && unspawnNotes[0].strumTime - Conductor.songPosition < 1800 / SONG.speed)
		{
			var dunceNote:Note = unspawnNotes[0];
			notes.add(dunceNote);

			var index:Int = unspawnNotes.indexOf(dunceNote);
			unspawnNotes.shift();
		}

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if ((SaveData.get('downscroll') && daNote.y < -daNote.height)
					|| (!SaveData.get('downscroll') && daNote.y > FlxG.height))
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				var strumLineMid = strumLine.y + Note.swagWidth / 2;

				if (SaveData.get('downscroll'))
				{
					daNote.y = (strumLine.y + (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2)));

					if (daNote.isSustainNote)
					{
						if (daNote.animation.curAnim.name.endsWith("end") && daNote.prevNote != null)
							daNote.y += daNote.prevNote.height;
						else
							daNote.y += daNote.height / 2;

						if ((!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))
							&& daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= strumLineMid)
						{
							// clipRect is applied to graphic itself so use frame Heights
							var swagRect:FlxRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);

							swagRect.height = (strumLineMid - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;
							daNote.clipRect = swagRect;
						}
					}
				}
				else
				{
					daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2)));

					if (daNote.isSustainNote
						&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))
						&& daNote.y + daNote.offset.y * daNote.scale.y <= strumLineMid)
					{
						var swagRect:FlxRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);

						swagRect.y = (strumLineMid - daNote.y) / daNote.scale.y;
						swagRect.height -= swagRect.y;
						daNote.clipRect = swagRect;
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit)
				{
					if (SONG.song != 'Tutorial')
						camZooming = true;

					var altAnim:String = "";

					if (SONG.notes[Math.floor(curStep / 16)] != null)
					{
						if (SONG.notes[Math.floor(curStep / 16)].altAnim)
							altAnim = '-alt';
					}

					if (daNote.altNote)
						altAnim = '-alt';

					switch (Math.abs(daNote.noteData))
					{
						case 0:
							dad.playAnim('singLEFT' + altAnim, true);
						case 1:
							dad.playAnim('singDOWN' + altAnim, true);
						case 2:
							dad.playAnim('singUP' + altAnim, true);
						case 3:
							dad.playAnim('singRIGHT' + altAnim, true);
					}

					dad.holdTimer = 0;

					if (SONG.needsVoices)
						vocals.volume = 1;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * SONG.speed));

				// removing this so whether the note misses or not is entirely up to Note class
				// var noteMiss:Bool = daNote.y < -daNote.height;

				// if (SaveData.get('downscroll'))
					// noteMiss = daNote.y > FlxG.height;

				if (daNote.isSustainNote && daNote.wasGoodHit)
				{
					if ((!SaveData.get('downscroll') && daNote.y < -daNote.height)
						|| (SaveData.get('downscroll') && daNote.y > FlxG.height))
					{
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				}
				else if (daNote.tooLate || daNote.wasGoodHit)
				{
					if (daNote.tooLate)
					{
						health -= 0.0475;
						vocals.volume = 0;
						killCombo();
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}

		if (!inCutscene)
			keyShit();
	}

	function killCombo():Void
	{
		if (combo > 5 && gf.animOffsets.exists('sad'))
			gf.playAnim('sad');
		if (combo != 0)
		{
			combo = 0;
			displayCombo();
		}
	}

	#if debug
	function changeSection(sec:Int):Void
	{
		FlxG.sound.music.pause();

		var daBPM:Float = SONG.bpm;
		var daPos:Float = 0;
		for (i in 0...(Std.int(curStep / 16 + sec)))
		{
			if (SONG.notes[i].changeBPM)
			{
				daBPM = SONG.notes[i].bpm;
			}
			daPos += 4 * (1000 * 60 / daBPM);
		}
		Conductor.songPosition = FlxG.sound.music.time = daPos;
		updateCurStep();
		resyncVocals();
	}
	#end

	function endSong():Void
	{
		seenCutscene = false;
		deathCounter = 0;
		canPause = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		if (SONG.validScore)
		{
			Highscore.saveScore(SONG.song, songScore, storyDifficulty);
		}

		if (isStoryMode)
		{
			campaignScore += songScore;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'));

				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				switch (PlayState.storyWeek)
				{
					default:
						FlxG.switchState(new StoryMenuState());
				}

				StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;

				if (SONG.validScore)
				{
					Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
				}

				FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
				FlxG.save.flush();
			}
			else
			{
				var difficulty:String = "";

				if (storyDifficulty == 0)
					difficulty = '-easy';

				if (storyDifficulty == 2)
					difficulty = '-hard';

				trace('LOADING NEXT SONG');
				trace(storyPlaylist[0].toLowerCase() + difficulty);

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				FlxG.sound.music.stop();
				vocals.stop();

				if (SONG.song.toLowerCase() == 'eggnog')
				{
					var blackShit:FunkinSprite = new FunkinSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom);
					blackShit.makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;
					inCutscene = true;

					FlxG.sound.play(Paths.sound('Lights_Shut_off'), function()
					{
						// no camFollow so it centers on horror tree
						SONG = Song.loadFromJson(storyPlaylist[0].toLowerCase() + difficulty, storyPlaylist[0]);
						LoadingState.loadAndMusicBeatState(new PlayState());
					});
				}
				else
				{
					prevCamFollow = camFollow;

					SONG = Song.loadFromJson(storyPlaylist[0].toLowerCase() + difficulty, storyPlaylist[0]);
					LoadingState.loadAndMusicBeatState(new PlayState());
				}
			}
		}
		else
		{
			trace('WENT BACK TO FREEPLAY??');
			// unloadAssets();
			FlxG.switchState(new FreeplayState());
		}
	}

	// gives score and pops up rating
	private function popUpScore(strumtime:Float, daNote:Note):Void
	{
		var noteDiff:Float = Math.abs(strumtime - Conductor.songPosition);
		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var rating:FunkinSprite = new FunkinSprite();
		var score:Int = 350;

		var daRating:String = "sick";

		var isSick:Bool = true;

		if (noteDiff > Conductor.safeZoneOffset * 0.9)
		{
			daRating = 'shit';
			score = 50;
			isSick = false; // shitty copypaste on this literally just because im lazy and tired lol!
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.75)
		{
			daRating = 'bad';
			score = 100;
			isSick = false;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.2)
		{
			daRating = 'good';
			score = 200;
			isSick = false;
		}

		if (isSick)
		{
			var noteSplash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
			noteSplash.setupNoteSplash(daNote.x, daNote.y, daNote.noteData);
			// new NoteSplash(daNote.x, daNote.y, daNote.noteData);
			grpNoteSplashes.add(noteSplash);
		}

		// Only add the score if you're not on practice mode
		if (!practiceMode)
			songScore += score;

		// ludum dare rating system
		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

		var ratingPath:String = daRating;

		if (curStage.startsWith('school'))
			ratingPath = "weeb/pixelUI/" + ratingPath + "-pixel";

		rating.loadGraphic(Paths.image(ratingPath));
		rating.x = FlxG.width * 0.55 - 40;
		// make sure rating is visible lol!
		if (rating.x < FlxG.camera.scroll.x)
			rating.x = FlxG.camera.scroll.x;
		else if (rating.x > FlxG.camera.scroll.x + FlxG.camera.width - rating.width)
			rating.x = FlxG.camera.scroll.x + FlxG.camera.width - rating.width;

		rating.y = FlxG.camera.scroll.y + FlxG.camera.height * 0.4 - 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		add(rating);

		if (curStage.startsWith('school'))
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = true;
		}
		rating.updateHitbox();

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
		if (combo >= 10 || combo == 0)
			displayCombo();
	}

	function displayCombo():Void
	{
		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (curStage.startsWith('school'))
		{
			pixelShitPart1 = 'weeb/pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		var comboSpr:FunkinSprite = new FunkinSprite();
		comboSpr.loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.y = FlxG.camera.scroll.y + FlxG.camera.height * 0.4 + 80;
		comboSpr.x = FlxG.width * 0.55;
		// make sure combo is visible lol!
		// 194 fits 4 combo digits
		if (comboSpr.x < FlxG.camera.scroll.x + 194)
			comboSpr.x = FlxG.camera.scroll.x + 194;
		else if (comboSpr.x > FlxG.camera.scroll.x + FlxG.camera.width - comboSpr.width)
			comboSpr.x = FlxG.camera.scroll.x + FlxG.camera.width - comboSpr.width;

		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.velocity.x += FlxG.random.int(1, 10);

		add(comboSpr);

		if (curStage.startsWith('school'))
		{
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));
		}
		else
		{
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = true;
		}
		comboSpr.updateHitbox();

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				comboSpr.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		var seperatedScore:Array<Int> = [];
		var tempCombo:Int = combo;

		while (tempCombo != 0)
		{
			seperatedScore.push(tempCombo % 10);
			tempCombo = Std.int(tempCombo / 10);
		}
		while (seperatedScore.length < 3)
			seperatedScore.push(0);

		// seperatedScore.reverse();

		var daLoop:Int = 1;
		for (i in seperatedScore)
		{
			var numScore:FunkinSprite = new FunkinSprite();
			numScore.loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.y = comboSpr.y;

			if (curStage.startsWith('school'))
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			else
			{
				numScore.antialiasing = true;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			numScore.updateHitbox();

			numScore.x = comboSpr.x - (43 * daLoop); //- 90;
			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
	}

	var cameraRightSide:Bool = false;

	function cameraMovement()
	{
		if (camFollow.x != dad.getMidpoint().x + 150 && !cameraRightSide)
		{
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			// camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);

			switch (dad.curCharacter)
			{
				case 'mom':
					camFollow.y = dad.getMidpoint().y;
				case 'senpai' | 'senpai-angry':
					camFollow.y = dad.getMidpoint().y - 430;
					camFollow.x = dad.getMidpoint().x - 100;
			}

			if (dad.curCharacter == 'mom')
				vocals.volume = 1;

			if (SONG.song.toLowerCase() == 'tutorial')
				tweenCamIn();
		}

		if (cameraRightSide && camFollow.x != boyfriend.getMidpoint().x - 100)
		{
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

			switch (curStage)
			{
				case 'limo':
					camFollow.x = boyfriend.getMidpoint().x - 300;
				case 'mall':
					camFollow.y = boyfriend.getMidpoint().y - 200;
				case 'school' | 'schoolEvil':
					camFollow.x = boyfriend.getMidpoint().x - 200;
					camFollow.y = boyfriend.getMidpoint().y - 200;
			}

			if (SONG.song.toLowerCase() == 'tutorial')
				FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
		}
	}

	private function keyShit():Void
	{
		// control arrays, order L D R U
		var holdArray:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
		var pressArray:Array<Bool> = [
			controls.LEFT_P,
			controls.DOWN_P,
			controls.UP_P,
			controls.RIGHT_P
		];
		var releaseArray:Array<Bool> = [
			controls.LEFT_R,
			controls.DOWN_R,
			controls.UP_R,
			controls.RIGHT_R
		];

		// HOLDS, check for sustain notes
		if (holdArray.contains(true) && /*!boyfriend.stunned && */ generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.noteData])
					goodNoteHit(daNote);
			});
		}

		// PRESSES, check for note hits
		if (pressArray.contains(true) && /*!boyfriend.stunned && */ generatedMusic)
		{
			boyfriend.holdTimer = 0;

			var possibleNotes:Array<Note> = []; // notes that can be hit
			var directionList:Array<Int> = []; // directions that can be hit
			var dumbNotes:Array<Note> = []; // notes to kill later

			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
				{
					if (directionList.contains(daNote.noteData))
					{
						for (coolNote in possibleNotes)
						{
							if (coolNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
							{ // if it's the same note twice at < 10ms distance, just delete it
								// EXCEPT u cant delete it in this loop cuz it fucks with the collection lol
								dumbNotes.push(daNote);
								break;
							}
							else if (coolNote.noteData == daNote.noteData && daNote.strumTime < coolNote.strumTime)
							{ // if daNote is earlier than existing note (coolNote), replace
								possibleNotes.remove(coolNote);
								possibleNotes.push(daNote);
								break;
							}
						}
					}
					else
					{
						possibleNotes.push(daNote);
						directionList.push(daNote.noteData);
					}
				}
			});

			for (note in dumbNotes)
			{
				FlxG.log.add("killing dumb ass note at " + note.strumTime);
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}

			possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

			if (perfectMode)
				goodNoteHit(possibleNotes[0]);
			else if (possibleNotes.length > 0)
			{
				for (shit in 0...pressArray.length)
				{ // if a direction is hit that shouldn't be
					if (pressArray[shit] && !directionList.contains(shit))
						noteMiss(shit);
				}
				for (coolNote in possibleNotes)
				{
					if (pressArray[coolNote.noteData])
						goodNoteHit(coolNote);
				}
			}
			else
			{
				for (shit in 0...pressArray.length)
					if (pressArray[shit])
						noteMiss(shit);
			}
		}

		if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !holdArray.contains(true))
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.playAnim('idle');
			}
		}

		playerStrums.forEach(function(spr:FunkinSprite)
		{
			if (pressArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
				spr.animation.play('pressed');
			if (!holdArray[spr.ID])
				spr.animation.play('static');

			if (spr.animation.curAnim.name == 'confirm' && !curStage.startsWith('school'))
			{
				spr.centerOffsets();
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			}
			else
				spr.centerOffsets();
		});
	}

	function noteMiss(direction:Int = 1):Void
	{
		// whole function used to be encased in if (!boyfriend.stunned)
		health -= 0.04;
		killCombo();

		if (!practiceMode)
			songScore -= 10;

		vocals.volume = 0;
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

		/* boyfriend.stunned = true;

		// get stunned for 5 seconds
		new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
		{
			boyfriend.stunned = false;
		}); */

		switch (direction)
		{
			case 0:
				boyfriend.playAnim('singLEFTmiss', true);
			case 1:
				boyfriend.playAnim('singDOWNmiss', true);
			case 2:
				boyfriend.playAnim('singUPmiss', true);
			case 3:
				boyfriend.playAnim('singRIGHTmiss', true);
		}
	}

	/* not used anymore lol

	function badNoteHit()
	{
		// just double pasting this shit cuz fuk u
		// REDO THIS SYSTEM!
		var leftP = controls.NOTE_LEFT_P;
		var downP = controls.NOTE_DOWN_P;
		var upP = controls.NOTE_UP_P;
		var rightP = controls.NOTE_RIGHT_P;

		if (leftP)
			noteMiss(0);
		if (downP)
			noteMiss(1);
		if (upP)
			noteMiss(2);
		if (rightP)
			noteMiss(3);
	} */

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note.strumTime, note);
			}

			if (note.noteData >= 0)
				health += 0.023;
			else
				health += 0.004;

			switch (note.noteData)
			{
				case 0:
					boyfriend.playAnim('singLEFT', true);
				case 1:
					boyfriend.playAnim('singDOWN', true);
				case 2:
					boyfriend.playAnim('singUP', true);
				case 3:
					boyfriend.playAnim('singRIGHT', true);
			}

			playerStrums.forEach(function(spr:FunkinSprite)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
					spr.animation.play('confirm', true);
				}
			});

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
		{
			resyncVocals();
		}

		if (dad.curCharacter == 'spooky' && curStep % 4 == 2)
		{
			// dad.dance();
		}
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	override function destroy() 
	{
		super.destroy();
		instance = null;
	}

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			notes.sort(sortNotes, FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			// else
			// Conductor.changeBPM(SONG.bpm);
		}

		if (SaveData.get('camera zoom'))
		{
			if (curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200 && camZooming && FlxG.camera.zoom < 1.35)
			{
				FlxG.camera.zoom += 0.015;
				camHUD.zoom += 0.03;
			}

			if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
			{
				FlxG.camera.zoom += 0.015;
				camHUD.zoom += 0.03;
			}
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (curBeat % gfSpeed == 0)
			gf.dance();

		if (curBeat % 2 == 0)
		{
			if (!boyfriend.animation.curAnim.name.startsWith("sing"))
				boyfriend.playAnim('idle');
			if (!dad.animation.curAnim.name.startsWith("sing"))
				dad.dance();
		}
		else if (dad.curCharacter == 'spooky')
		{
			if (!dad.animation.curAnim.name.startsWith("sing"))
				dad.dance();
		}

		if (curBeat % 8 == 7 && curSong == 'Bopeebo')
		{
			boyfriend.playAnim('hey', true);
		}

		if (curBeat % 16 == 15 && SONG.song == 'Tutorial' && dad.curCharacter == 'gf' && curBeat > 16 && curBeat < 48)
		{
			boyfriend.playAnim('hey', true);
			dad.playAnim('cheer', true);
		}
	}

	var curLight:Int = 0;
}