package
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SampleDataEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.media.Microphone;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.utils.ByteArray;

	public class Track extends EventDispatcher
	{
		public static var PLAY_FINISH:String = "playfinish";
		public static var RECORD_READY:String = "recordready";
		public static var RECORD_FINISH:String = "recordfinish";
		public static var SAVE_COMPLETE:String = "savecomplete";

		public var recordedData:ByteArray = new ByteArray();
		public var isPlaying:Boolean = false;

		private var mic:Microphone;
		private var sound:Sound;

		public var recordEnabled:Boolean = false;
		private var _recording:Boolean = false;
		private var id:String;

		public var trackTransform:SoundTransform = new SoundTransform();
		private var channel:SoundChannel;

		public function Track(trackId:String)
		{
			id = trackId;
			trackTransform.volume = 0;
		}

		public function get ID():String
		{
			return id;
		}

		public function setPan(value:Number):void
		{
			trackTransform.pan = value;
		}

		public function setVolume(value:Number):void
		{
			trackTransform.volume = value / 100;
		}

		public function writeWav(file:File):Boolean
		{
			if (recordedData == null)
				return false;

			var wavWriter:WAVWriter = new WAVWriter();
			var stream:FileStream = new FileStream();

			// Set settings
			recordedData.position = 0;
			wavWriter.numOfChannels = 1;
			wavWriter.sampleBitRate = 16;
			wavWriter.samplingRate = 44100;

			stream.open(file, FileMode.WRITE);

			// convert ByteArray to WAV
			wavWriter.processSamples( stream, recordedData,	44100, 1 );
			stream.close();

			recordedData.position = 0;

			return true;
		}

		public function prepareRecord(event:Event):void
		{
			if(!recordEnabled)
				return;

			_recording = true;

			recordedData.clear();

			mic = Microphone.getMicrophone();
			mic.rate = 44;
			mic.gain = 10;
			mic.setSilenceLevel(0, -1);

			dispatchEvent(new Event(Track.RECORD_READY));
		}

		public function stopRecording(event:Event):void
		{
			if (!mic || !_recording)
				return;

			mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, dataHandler);
			_recording = false;
			recordedData.position = 0;
			dispatchEvent(new Event(Track.RECORD_FINISH));
		}

		private function dataHandler(event:SampleDataEvent):void
		{
			recordedData.writeBytes(event.data);
		}

		public function stop(event:Event):void
		{
			if (isPlaying)
			{
				channel.stop();
				isPlaying = false;
				recordedData.position = 0;
				dispatchEvent(new Event(Track.PLAY_FINISH));
			}
		}

		public function playOrRecord(event:Event):void
		{
			if(_recording)
			{
				mic.addEventListener(SampleDataEvent.SAMPLE_DATA, dataHandler);
			}
			else
				play(null);
		}

		public function play(event:Event):void
		{
			if (null == recordedData)
			{
				dispatchEvent(new Event(Track.PLAY_FINISH));
				return;
			}

			recordedData.position = 0;

			if (!(recordedData.bytesAvailable > 0))
			{
				dispatchEvent(new Event(Track.PLAY_FINISH));
				return;
			}

			if (trackTransform.volume < 0.1)
			{
				return;
			}

			isPlaying = true;

			sound = new Sound();
			sound.addEventListener(SampleDataEvent.SAMPLE_DATA,	playSoundHandler);

			channel = sound.play(0, 0, trackTransform);
			channel.addEventListener(Event.SOUND_COMPLETE, function():void {isPlaying = false; dispatchEvent(new Event(Track.PLAY_FINISH))});
		}

		private function playSoundHandler(event:SampleDataEvent):void
		{
			if (!recordedData.bytesAvailable > 0)
			{
				channel.dispatchEvent(new Event(Event.SOUND_COMPLETE));
				return;
			}

			var length:int = 2048;
			for (var i:int = 0; i < length; i++)
			{
				var sample:Number = 0;

				if (recordedData.bytesAvailable > 0)
					sample = recordedData.readFloat();

				event.data.writeFloat(sample);
				event.data.writeFloat(sample);
			}
		}
	}
}
