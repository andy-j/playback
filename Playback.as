package
{
	import caurina.transitions.Tweener;
	import components.FTKnob;
	import flash.desktop.NativeApplication;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import fr.kikko.lab.ShineMP3Encoder;
	import qnx.ui.buttons.Button;
	import qnx.ui.buttons.LabelButton;
	import qnx.ui.buttons.RadioButton;
	import qnx.ui.core.Container;
	import qnx.ui.core.ContainerFlow;
	import qnx.ui.events.SliderEvent;
	import qnx.ui.progress.ActivityIndicator;
	import qnx.ui.slider.Slider;
	import skins.FTPlayButton;
	import skins.FTRadioButton;
	import skins.FTRecordButton;
	import skins.FTSaveButton;
	import skins.FTSliderFill;
	import skins.FTSliderThumb;
	import skins.FTSliderTrack;






	// The following metadata specifies the size and properties of the canvas that
	// this application should occupy on the BlackBerry PlayBook screen.
	[SWF(width="1024", height="600", backgroundColor="#AAAAAA", frameRate="30")]
	public class Playback extends Sprite
	{
		private var base:Container = new Container();

		private var recordButton:LabelButton = new LabelButton();
		private var playButton:LabelButton = new LabelButton();
		private var saveButton:LabelButton = new LabelButton();

		private var track1:Track = new Track("1");
		private var track2:Track = new Track("2");
		private var track3:Track = new Track("3");
		private var track4:Track = new Track("4");

		private var track1Record:RadioButton = new RadioButton();
		private var track2Record:RadioButton = new RadioButton();
		private var track3Record:RadioButton = new RadioButton();
		private var track4Record:RadioButton = new RadioButton();

		private var track1Volume:Slider = new Slider();
		private var track2Volume:Slider = new Slider();
		private var track3Volume:Slider = new Slider();
		private var track4Volume:Slider = new Slider();

		private var track1Pan:FTKnob = new FTKnob();
		private var track2Pan:FTKnob = new FTKnob();
		private var track3Pan:FTKnob = new FTKnob();
		private var track4Pan:FTKnob = new FTKnob();

		private var masterVolume:Slider = new Slider();
		private var masterTransform:SoundTransform = SoundMixer.soundTransform;

		private var manager:TrackManager = new TrackManager();

		private var tracks:Array = new Array();

		private var file:File;

		private var waiting:Container = new Container();
		private var numbers:Container = new Container();

		[Embed(source="assets/background.png")]
		private var background:Class;

		[Embed(source="assets/over.png")]
		private var Overlay:Class;
		private var over:Bitmap = new Overlay();

		[Embed(source="assets/3.png")]
		private var Three:Class;
		private var three:Bitmap = new Three();

		[Embed(source="assets/2.png")]
		private var Two:Class;
		private var two:Bitmap = new Two();

		[Embed(source="assets/1.png")]
		private var One:Class;
		private var one:Bitmap = new One();

		[Embed(source="assets/go.png")]
		private var Go:Class;
		private var go:Bitmap = new Go();

		[Embed(source="assets/playing.png")]
		private var Playing:Class;
		private var playing:Bitmap = new Playing();

		[Embed(source="assets/saving.png")]
		private var Saving:Class;
		private var saving:Bitmap = new Saving();

		private var activity:ActivityIndicator = new ActivityIndicator();

		private var secondTimer:Timer = new Timer(1000);

		private var bigButton:Button = new Button();

		private var _isPlaying:Boolean = false;

		private var mix12:ByteArray;
		private var mix34:ByteArray;
		private var bigMix:ByteArray;
		private var stream:FileStream;

		private var mp3encoder:ShineMP3Encoder;

		public function Playback()
		{
			bigButton.setSize(1024, 600);
			bigButton.alpha = 0;

			masterTransform.volume = 0;
			base.addChild(new background());
			base.flow = ContainerFlow.HORIZONTAL;

			initializeTracks();
			initializeTrackButtons();
			initializeKnobs();
			initializeSliders();
			initializeControlButtons();
			layoutUI();

			NativeApplication.nativeApplication.addEventListener(Event.EXITING, closeWindow);
			NativeApplication.nativeApplication.addEventListener(Event.DEACTIVATE, stopAll);

			activity.x = 512 - activity.width / 2;
			activity.y = 300 - activity.height / 2;
			waiting.addChild(over);
			waiting.addChild(activity);
			waiting.alpha = 0;

			numbers.visible = false;

			addChild(base);
			addChild(numbers);

			stage.nativeWindow.visible = true;
		}

		private function layoutUI():void
		{
			base.addChild(track1Volume);
			base.addChild(track1Pan);
			base.addChild(track1Record);

			base.addChild(track2Volume);
			base.addChild(track2Pan);
			base.addChild(track2Record);

			base.addChild(track3Volume);
			base.addChild(track3Pan);
			base.addChild(track3Record);

			base.addChild(track4Volume);
			base.addChild(track4Pan);
			base.addChild(track4Record);

			base.addChild(playButton);
			base.addChild(recordButton);
			base.addChild(saveButton);

			three.alpha = 0;
			two.alpha = 0;
			one.alpha = 0;
			go.alpha = 0;
			playing.alpha = 0;
			saving.alpha = 0;

			numbers.addChild(go);
			numbers.addChild(one);
			numbers.addChild(two);
			numbers.addChild(three);
			numbers.addChild(playing);
			numbers.addChild(saving);
		}

		private function initializeKnobs():void
		{
			track1Pan.addEventListener(FTKnob.CHANGE, function():void { track1.setPan(track1Pan.value) });
			track1Pan.x = 48;
			track1Pan.y = 360;
			track2Pan.addEventListener(FTKnob.CHANGE, function():void { track2.setPan(track2Pan.value) });
			track2Pan.x = 243;
			track2Pan.y = 360;
			track3Pan.addEventListener(FTKnob.CHANGE, function():void { track3.setPan(track3Pan.value) });
			track3Pan.x = 438;
			track3Pan.y = 360;
			track4Pan.addEventListener(FTKnob.CHANGE, function():void { track4.setPan(track4Pan.value) });
			track4Pan.x = 633;
			track4Pan.y = 360;
		}

		private function initializeTracks():void
		{
			tracks.push(track1);
			tracks.push(track2);
			tracks.push(track3);
			tracks.push(track4);

			manager.addEventListener(TrackManager.PLAY, track1.play);
			manager.addEventListener(TrackManager.STOP_PLAYING, track1.stop);
			manager.addEventListener(TrackManager.RECORD, track1.prepareRecord);
			track1.addEventListener(Track.RECORD_READY, goRecord);
			track1.addEventListener(Track.PLAY_FINISH, playFinished);
			manager.addEventListener(TrackManager.STOP_RECORDING, track1.stopRecording);
			manager.addEventListener(TrackManager.PLAY_OR_RECORD, track1.playOrRecord);
			track1.recordEnabled = true;

			manager.addEventListener(TrackManager.PLAY, track2.play);
			manager.addEventListener(TrackManager.STOP_PLAYING, track2.stop);
			manager.addEventListener(TrackManager.RECORD, track2.prepareRecord);
			track2.addEventListener(Track.RECORD_READY, goRecord);
			track2.addEventListener(Track.PLAY_FINISH, playFinished);
			manager.addEventListener(TrackManager.STOP_RECORDING, track2.stopRecording);
			manager.addEventListener(TrackManager.PLAY_OR_RECORD, track2.playOrRecord);

			manager.addEventListener(TrackManager.PLAY, track3.play);
			manager.addEventListener(TrackManager.STOP_PLAYING, track3.stop);
			manager.addEventListener(TrackManager.RECORD, track3.prepareRecord);
			track3.addEventListener(Track.RECORD_READY, goRecord);
			track3.addEventListener(Track.PLAY_FINISH, playFinished);
			manager.addEventListener(TrackManager.STOP_RECORDING, track3.stopRecording);
			manager.addEventListener(TrackManager.PLAY_OR_RECORD, track3.playOrRecord);

			manager.addEventListener(TrackManager.PLAY, track4.play);
			manager.addEventListener(TrackManager.STOP_PLAYING, track4.stop);
			manager.addEventListener(TrackManager.RECORD, track4.prepareRecord);
			track4.addEventListener(Track.RECORD_READY, goRecord);
			track4.addEventListener(Track.PLAY_FINISH, playFinished);
			manager.addEventListener(TrackManager.STOP_RECORDING, track4.stopRecording);
			manager.addEventListener(TrackManager.PLAY_OR_RECORD, track4.playOrRecord);
		}

		private function goRecord(event:Event):void {
			secondTimer.addEventListener(TimerEvent.TIMER, countDown);
			base.addChild(over);
			numbers.addChild(bigButton);
			numbers.visible = true;
			enableRecordOverlay(true);
			secondTimer.start();
			Tweener.addTween(three, {alpha:1, time:0.9, transition:"linear"});
			Tweener.addTween(three, {alpha:0, time:0.2, delay:0.9, transition:"linear"});

			function countDown(event:TimerEvent):void
			{
				if (Timer(event.target).currentCount == 1)
				{
					Tweener.addTween(two, {alpha:1, time:0.8, transition:"linear"});
					Tweener.addTween(two, {alpha:0, time:0.2, delay:0.9, transition:"linear"});

				}
				else if (Timer(event.target).currentCount == 2)
				{
					Tweener.addTween(one, {alpha:1, time:0.9, transition:"linear"});
					Tweener.addTween(one, {alpha:0, time:0.2, delay:0.9, transition:"linear"});
				}
				else if (Timer(event.target).currentCount > 2)
				{
					secondTimer.stop();
					secondTimer.reset();
					secondTimer.removeEventListener(TimerEvent.TIMER, countDown);
					bigButton.addEventListener(MouseEvent.CLICK, stopRecording);
					Tweener.addTween(go, {alpha:1, time:0.9, transition:"linear"});
					manager.playOrRecord(null);
				}
			}

			function stopRecording():void {
				bigButton.removeEventListener(MouseEvent.CLICK, stopRecording);
				manager.stopRecording(null);
				enableRecordOverlay(false);
				numbers.removeChild(bigButton);
				numbers.visible = false;
				base.removeChild(over);
			}
		}

		public function playFinished(event:Event):void
		{
			if (manager.isRecording)
				return;

			for each (var t:Track in tracks) {
				if (t.isPlaying)
					return;
			}
			_isPlaying = false;
			stopPlaying(null);
		}

		private function initializeTrackButtons():void
		{
			track1Record.setSkin(FTRadioButton);
			track1Record.groupname = "record";
			track1Record.x = 48;
			track1Record.y = 525;
			track1Record.selected = true;
			track1Record.addEventListener(MouseEvent.CLICK,
				function(event:Event):void {
					if (!manager.isRecording) {
						removeRecords();
						track1.recordEnabled = true;
					}
					else
						event.preventDefault();
				});

			track2Record.setSkin(FTRadioButton);
			track2Record.groupname = "record";
			track2Record.x = 243;
			track2Record.y = 525;
			track2Record.addEventListener(MouseEvent.CLICK,
				function(event:Event):void {
					if (!manager.isRecording) {
						removeRecords();
						track2.recordEnabled = true;
					}
					else
						event.preventDefault();
				});

			track3Record.setSkin(FTRadioButton);
			track3Record.groupname = "record";
			track3Record.x = 438;
			track3Record.y = 525;
			track3Record.addEventListener(MouseEvent.CLICK,
				function(event:Event):void {
					if (!manager.isRecording) {
						removeRecords();
						track3.recordEnabled = true;
					}
					else
						event.preventDefault();
				});

			track4Record.setSkin(FTRadioButton);
			track4Record.groupname = "record";
			track4Record.x = 633;
			track4Record.y = 525;
			track4Record.addEventListener(MouseEvent.CLICK,
				function(event:Event):void {
					if (!manager.isRecording) {
						removeRecords();
						track4.recordEnabled = true;
					}
					else
						event.preventDefault();
				});
		}

		private function removeRecords():void
		{
			if (!manager.isRecording)
			{
				track1.recordEnabled = false;
				track2.recordEnabled = false;
				track3.recordEnabled = false;
				track4.recordEnabled = false;
			}
		}

		private function initializeSliders():void
		{
			track1Volume.rotation = -90;
			track1Volume.x = 48;
			track1Volume.y = 340;
			track1Volume.setSize(340, 148);
			track1Volume.setFillSkin(FTSliderFill);
			track1Volume.setThumbSkin(FTSliderThumb);
			track1Volume.setTrackSkin(FTSliderTrack);
			track1Volume.addEventListener(SliderEvent.END, function():void { track1.setVolume(track1Volume.value) });

			track2Volume.rotation = -90;
			track2Volume.x = 243;
			track2Volume.y = 340;
			track2Volume.setSize(340, 148);
			track2Volume.setFillSkin(FTSliderFill);
			track2Volume.setThumbSkin(FTSliderThumb);
			track2Volume.setTrackSkin(FTSliderTrack);
			track2Volume.addEventListener(SliderEvent.END, function():void { track2.setVolume(track2Volume.value) });

			track3Volume.rotation = -90;
			track3Volume.x = 438;
			track3Volume.y = 340;
			track3Volume.setSize(340, 148);
			track3Volume.setFillSkin(FTSliderFill);
			track3Volume.setThumbSkin(FTSliderThumb);
			track3Volume.setTrackSkin(FTSliderTrack);
			track3Volume.addEventListener(SliderEvent.END, function():void { track3.setVolume(track3Volume.value) });

			track4Volume.rotation = -90;
			track4Volume.x = 633;
			track4Volume.y = 340;
			track4Volume.setSize(340, 148);
			track4Volume.setFillSkin(FTSliderFill);
			track4Volume.setThumbSkin(FTSliderThumb);
			track4Volume.setTrackSkin(FTSliderTrack);
			track4Volume.addEventListener(SliderEvent.END, function():void { track4.setVolume(track4Volume.value) });
		}

		private function initializeControlButtons():void
		{

			recordButton.setSkin(FTRecordButton);
			recordButton.x = 828;
			recordButton.y = 240;
			recordButton.addEventListener(MouseEvent.CLICK, onOff);

			playButton.setSkin(FTPlayButton);
			//playButton.toggle = true;
			playButton.x = 828;
			playButton.y = 60;
			playButton.addEventListener(MouseEvent.CLICK, playTracks);

			saveButton.setSkin(FTSaveButton);
			saveButton.x = 828;
			saveButton.y = 420;
			saveButton.addEventListener(MouseEvent.CLICK, save);
		}

		private function closeWindow(event:MouseEvent):void
		{
			SoundMixer.stopAll();
		}

		private function stopAll(event:Event):void
		{
			manager.stopRecording(event);
			stopPlaying(event);
			SoundMixer.stopAll();
		}

		private function onOff(event:MouseEvent):void
		{
			manager.record(null);
		}

		private function playTracks(event:MouseEvent):void
		{
			if (!_isPlaying)
			{
				base.addChild(over);
				enablePlayOverlay(true);
				numbers.visible = true;
				numbers.addChild(bigButton);

				Tweener.addTween(playing, {alpha:1, time:0.8, transition:"linear"});
				bigButton.addEventListener(MouseEvent.CLICK, stopPlaying);
				_isPlaying = true;
				manager.play(null);
			}
		}

		private function stopPlaying(event:Event):void
		{

			_isPlaying = false;
			enablePlayOverlay(false);
			numbers.visible = false;
			bigButton.removeEventListener(MouseEvent.CLICK, stopPlaying);

			if (numbers.contains(bigButton))
				numbers.removeChild(bigButton);

			if (base.contains(over))
				base.removeChild(over);

			manager.stopPlaying(null);
		}

		private function enablePlayOverlay(enable:Boolean):void
		{
			if (enable)
			{
				numbers.addChild(playing);
			}
			else
			{
				playing.alpha = 0;
				if (numbers.contains(playing))
					numbers.removeChild(playing);
			}
		}

		private function enableSaveOverlay(enable:Boolean):void
		{
			if (enable)
			{
				numbers.addChild(saving);
			}
			else
			{
				saving.alpha = 0;

				if(numbers.contains(saving))
					numbers.removeChild(saving);
			}

		}

		private function enableRecordOverlay(enable:Boolean):void
		{
			if (enable)
			{
				numbers.addChild(one);
				numbers.addChild(two);
				numbers.addChild(three);
				numbers.addChild(go);
			}
			else
			{
				one.alpha = 0;
				two.alpha = 0;
				three.alpha = 0;
				go.alpha = 0;

				if (numbers.contains(one))
					numbers.removeChild(one);
				if (numbers.contains(two))
					numbers.removeChild(two);
				if (numbers.contains(three))
					numbers.removeChild(three);
				if (numbers.contains(go))
					numbers.removeChild(go);
			}
		}

		private function save(event:Event):void
		{
			activity.animate(true);
			base.addChild(waiting);
			enableSaveOverlay(true);
			numbers.visible = true;
			Tweener.addTween(saving, {alpha:1, time:0.8, transition:"linear", onComplete:tellFilesToSave});
			Tweener.addTween(waiting, {alpha:1, time:0.8, transition:"linear"});

			//tellFilesToSave();
		}

		private function tellFilesToSave():void
		{
			var wavWriter:WAVWriter = new WAVWriter();

			// Set settings
			wavWriter.numOfChannels = 2;
			wavWriter.sampleBitRate = 16;
			wavWriter.samplingRate = 44100;

			if (track1.trackTransform.volume < 0.1 || track1.recordedData.length == 0)
				mix12 = wavWriter.monoToStereo(track2.recordedData, track2.trackTransform.volume, track2.trackTransform.pan);
			else if (track2.trackTransform.volume < 0.1 || track2.recordedData.length == 0)
				mix12 = wavWriter.monoToStereo(track1.recordedData, track1.trackTransform.volume, track1.trackTransform.pan);
			else
				mix12 = wavWriter.combineMonoTracks(track1.recordedData, track2.recordedData, track1.trackTransform.volume, track2.trackTransform.volume, track1.trackTransform.pan, track2.trackTransform.pan);

			activity.animate(true);

			if (track3.trackTransform.volume < 0.1 || track3.recordedData.length == 0)
				mix34 = wavWriter.monoToStereo(track4.recordedData, track4.trackTransform.volume, track4.trackTransform.pan);
			else if (track4.trackTransform.volume < 0.1 || track4.recordedData.length == 0)
				mix34 = wavWriter.monoToStereo(track3.recordedData, track3.trackTransform.volume, track3.trackTransform.pan);
			else
				mix34 = wavWriter.combineMonoTracks(track3.recordedData, track4.recordedData, track3.trackTransform.volume, track4.trackTransform.volume, track3.trackTransform.pan, track4.trackTransform.pan);

			activity.animate(true);

			if (mix12.length == 0)
				bigMix = mix34;
			else if (mix34.length == 0)
				bigMix = mix12;
			else
				bigMix = wavWriter.combineStereoTracks(mix12, mix34);
			activity.animate(true);

			var bytes:ByteArray = new ByteArray();

			// convert ByteArray to WAV
			wavWriter.addEventListener(WAVWriter.NODATA, cleanAfterRecord);
			wavWriter.addEventListener(WAVWriter.SAVE_COMPLETE, convertToMp3);
			wavWriter.processSamples( bytes, bigMix, 44100, 2 );

			var filename:String;

			function convertToMp3(event:Event):void
			{
				bytes.position = 0;

				mp3encoder = new ShineMP3Encoder(bytes);

				mp3encoder.addEventListener(Event.COMPLETE, onEncoded);
				mp3encoder.addEventListener(ProgressEvent.PROGRESS, onEncodingProgress);
				mp3encoder.start();
			}

			function onEncoded(event:Event):void
			{
				mp3encoder.mp3Data.position = 0;
				var myDate:Date = new Date();
				var theDate:String = myDate.monthUTC.toString()+myDate.dayUTC.toString()+myDate.hoursUTC.toString()+myDate.minutesUTC.toString()+myDate.secondsUTC.toString();

				filename = "playback"+theDate+".mp3";
				mp3encoder.saveAs(filename);
				cleanAfterRecord(new Event(""));
			}

			function onEncodingProgress(event:Event):void
			{
				activity.animate(true);
			}

			function cleanAfterRecord(event:Event):void
			{
				activity.animate(true);
				mix12.clear();
				mix34.clear();
				bigMix.clear();
				base.removeChild(waiting);
				waiting.alpha = 0;
				activity.animate(false);
				enableSaveOverlay(false);
				numbers.visible = false;
			}

		}
	}
}
