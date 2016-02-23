package
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import mx.collections.ArrayList;


	public class TrackManager extends EventDispatcher {
		public static var PLAY:String = "play";
		public static var PREPARE_RECORD:String = "preparerecord";
		public static var RECORD:String = "record";
		public static var STOP_RECORDING:String = "stoprecording";
		public static var SAVE:String = "save";
		public static var STOP_PLAYING:String = "stopplaying";
		public static var PLAY_OR_RECORD:String = "playorrecord";

		public var tracks:ArrayList = new ArrayList();

		private var _isRecording:Boolean = false;

		public function get isRecording():Boolean {
			return _isRecording;
		}

		public function play(event:Event):void {
			dispatchEvent(new Event(TrackManager.PLAY));
		}

		public function stopPlaying(event:Event):void {
			dispatchEvent(new Event(TrackManager.STOP_PLAYING));
		}

		public function record(event:Event):void {
			_isRecording = true;
			dispatchEvent(new Event(TrackManager.RECORD));
		}

		public function playOrRecord(event:Event):void {
			dispatchEvent(new Event(TrackManager.PLAY_OR_RECORD));
		}

		public function stopRecording(event:Event):void {
			_isRecording = false;
			dispatchEvent(new Event(TrackManager.STOP_RECORDING));
		}

		public function save(file:File):void {
			dispatchEvent(new Event(TrackManager.SAVE));
		}
	}
}
