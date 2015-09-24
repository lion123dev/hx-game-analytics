package src.net.lion123dev;
import haxe.crypto.Hmac;
import haxe.Http;
import haxe.Json;
import haxe.Timer;
import net.lion123dev.data.DataStorageManager;
import net.lion123dev.events.Events;
import net.lion123dev.events.Events.BaseEvent;
import src.net.lion123dev.url.RequestFactory;
import src.net.lion123dev.url.URLFactory;

/**
 * ...
 * @author _lion123
 */
class GameAnalytics
{
	public static inline var DEFAULT_TIMER:Int = 20000;
	static inline var VERSION_NUMBER:Int = 2;
	static inline var VERSION:String = "v2";
	static inline var SDK_VERSION:String = "rest api v2";
	static inline var PROTOCOL:String = "http://";
	
	static inline var PRODUCTION:String = "api.gameanalytics.com";
	static inline var SANDBOX:String = "sandbox-api.gameanalytics.com";
	
	static inline var ACTION_INIT:String = "init";
	static inline var ACTION_EVENT:String = "events";
	
	var _gameKey:String;
	var _secretKey:String;
	var _sandboxMode:Bool;
	var _gzip:Bool;
	var _inited:Bool;
	var _running:Bool;
	var _sessionPresent:Bool = false;
	var _sessionStartTime:Float;
	
	var _defaultValues:BaseEvent;
	
	var _storage:DataStorageManager;
	var _urlFactory:URLFactory;
	var _requestFactory:RequestFactory;
	var _callbackSuccess:Void->Void;
	var _callbackFail:String->Void;
	var _timer:Timer;
	var _timeOffset:Float;
	public var defaultValues(get, null):BaseEvent;
	public var sandboxMode(get, set):Bool;
	public var gzip(get, set):Bool;
	public var inited(get, null):Bool;
	public var serverTimestamp(get, null):Float;
	
	/**
	 * Create a new Game Analytics object. Only one should be created for each pair of game/secret keys.
	 * @param	gameKey A gameKey is an unique identifier for the game. Locate it in the game settings after you create the game in your Game Analytics account
	 * @param	secretKey The secret key is used to protect the events from being altered as they travel to Game Analytics servers. Locate it in the game settings after you create the game in your Game Analytics account
	 * @param	isSandboxMode Set to true if you want to use the sandbox endpoint.
	 */
	public function new(gameKey:String, secretKey:String, isSandboxMode:Bool) 
	{
		_running = false;
		_gameKey = gameKey;
		_secretKey = secretKey;
		_gzip = false;
		_sandboxMode = isSandboxMode;
		
		_urlFactory = new URLFactory(PROTOCOL, _sandboxMode?SANDBOX:PRODUCTION, VERSION, _gameKey);
		_requestFactory = new RequestFactory(_gzip, _secretKey);
		_storage = new DataStorageManager("game" + _gameKey);
	}
	
	/**
	 * Initialize current Game Analytics object.
	 * @param	platform A string representing the platform of the SDK, e.g. "ios".
	 * @param	osVersion A string representing the OS version, e.g. "ios 8.1".
	 * @param	onSuccess Function to be called when the init request succeds.
	 * @param	onFail Function to be called if the request fails or the server responses with enabled:false.
	 */
	public function Init(onSuccess:Void->Void, onFail:String->Void, platform:String, osVersion:String, device:String, manufacturer:String):Void
	{
		if (!_inited)
		{
			_storage.Init();
		}
		_defaultValues = {
			device: device,
			v: VERSION_NUMBER,
			user_id: _storage.userId,
			sdk_version: SDK_VERSION,
			os_version: osVersion,
			manufacturer: manufacturer,
			platform: platform,
			session_id: _storage.sessionId,
			session_num: _storage.sessionNum,
			client_ts: 0
		};
		if (_inited)
		{
			trace("Game Analytics already inited, not sending init request");
			return;
		}
		_callbackSuccess = onSuccess;
		_callbackFail = onFail;
		var initRequest:InitRequest = { platform: platform, os_version: osVersion, sdk_version: SDK_VERSION };
		trace(_urlFactory.BuildUrl(ACTION_INIT));
		var request:Http = _requestFactory.MakeRequest(_urlFactory.BuildUrl(ACTION_INIT), Json.stringify(initRequest));
		request.onError = onInitFail;
		request.onData = onInitSuccess;
		request.request(true);
	}
	
	/**
	 * Call this function to start automatically posting events on a given interval.
	 * @param	interval in millseconds, must be greater than 1000. Default is 20000
	 */
	public function StartPosting(interval:Int = DEFAULT_TIMER):Void
	{
		if (!inited)
		{
			trace("Game Analytics must be inited to start posting events.");
			return;
		}
		if (interval < 1000)
		{
			trace("Please don't spam Game Analytics servers!");
			return;
		}
		if (_running)
		{
			StopPosting();
		}
		_timer = new Timer(interval);
		_timer.run = doPostEvents;
		_running = true;
	}
	
	/**
	 * Call this function to stop automatically posting events.
	 */
	public function StopPosting():Void
	{
		if (!_running)
		{
			trace("Posting events is already stopped.");
			return;
		}
		_timer.run = null;
		_timer.stop();
		_running = false;
	}
	
	/**
	 * Force post events without waiting for the timer.
	 */
	public function ForcePost():Void
	{
		doPostEvents();
	}
	
	public function NewSession():Void
	{
		if (_sessionPresent)
		{
			EndSession();
		}
		_sessionPresent = true;
		_sessionStartTime = Date.now().getTime();
		_storage.NewSession();
		_defaultValues.session_id = _storage.sessionId;
		SendSessionStartEvent();
	}
	
	public function EndSession():Void
	{
		if (!_sessionPresent)
		{
			trace("No current session availbale");
			return;
		}
		SendSessionEndEvent(Math.ceil((_sessionStartTime-Date.now().getTime()) / 1000));
		_sessionPresent = false;
	}
	
	function doPostEvents():Void
	{
		//
	}
	
	function onInitSuccess(data:String):Void
	{
		var initResponse:InitResponse = Json.parse(data);
		if (!initResponse.enabled)
		{
			var error:String = "Game Analytics server doesn't want to work today :(";
			trace(error);
			if (_callbackFail != null)
				_callbackFail(error);
			return;
		}
		_timeOffset = initResponse.server_ts - Date.now().getTime();
		_callbackSuccess();
		_inited = true;
		NewSession();
	}
	function onInitFail(msg:String):Void
	{
		var error:String = "Send init request fail: " + msg;
		trace(error);
		if(_callbackFail != null)
			_callbackFail(error);
	}
	
	//Events creating/sending. SendDesignEvent is an alias for SendEvent(CreateDesignEvent(..params))
	function CreateSessionStartEvent():BaseEvent
	{
		return Events.GetUserEvent(_defaultValues);
	}
	function CreateSessionEndEvent(length:Int):SessionEndEvent
	{
		return Events.GetSessionEndEvent(_defaultValues, length);
	}
	public function CreateBusinessEvent(itemType:String, itemId:String, amount:Int, currency:String):BusinessEvent
	{
		_storage.NewTransaction();
		return Events.GetBusinessEvent(_defaultValues, itemType+":" + itemId, amount, currency, _storage.transactionNum);
	}
	public function CreateResourceEvent(flowType:String, virtualCurrency:String, itemType:String, itemId:String, amount:Float):ResourceEvent
	{
		return Events.GetResourceEvent(_defaultValues, [flowType, virtualCurrency, itemType, itemId].join(":"), amount);
	}
	public function CreateProgressionEvent(progressionStatus:String, progression1:String, progression2:String, progression3:String):ProgressionEvent
	{
		var event_id:String = progression1;
		if (progression2 != null) event_id += (":" + progression2);
		if (progression3 != null) event_id += (":" + progression3);
		var event:ProgressionEvent = Events.GetProgressionEvent(_defaultValues, progressionStatus + ":" + event_id);
		if (progressionStatus == ProgressionStatus.COMPLETE || progressionStatus == ProgressionStatus.FAIL)
		{
			event.attempt_num = _storage.NewAttempt(event_id);
		}
		return event;
	}
	public function CreateDesignEvent(part1:String, part2:String=null, part3:String=null, part4:String=null, part5:String=null, value:Null<Float> = null):DesignEvent
	{
		var event_id:String = part1;
		for (s in [part2, part3, part4, part5])
		{
			if (s != null) event_id += s;
		}
		var event:DesignEvent = Events.GetDesignEvent(_defaultValues, event_id);
		if (value != null) event.value = value;
		return event;
	}
	public function CreateErrorEvent(severity:String, message:String):ErrorEvent
	{
		return Events.GetErrorEvent(_defaultValues, severity, message);
	}
	function SendSessionStartEvent():Void
	{
		SendEvent(CreateSessionStartEvent());
	}
	function SendSessionEndEvent(length:Int):Void
	{
		SendEvent(CreateSessionEndEvent(length));
	}
	public function SendBusinessEvent(itemType:String, itemId:String, amount:Int, currency:String):Void
	{
		SendEvent(CreateBusinessEvent(itemType, itemId, amount, currency));
	}
	public function SendResourceEvent(flowType:String, virtualCurrency:String, itemType:String, itemId:String, amount:Float):Void
	{
		SendEvent(CreateResourceEvent(flowType, virtualCurrency, itemType, itemId, amount));
	}
	public function SendProgressionEvent(progressionStatus:String, progression1:String, progression2:String, progression3:String):Void
	{
		SendEvent(CreateProgressionEvent(progressionStatus, progression1, progression2, progression3));
	}
	public function SendDesignEvent(part1:String, part2:String = null, part3:String = null, part4:String = null, part5:String = null, value:Null<Float> = null):Void
	{
		SendEvent(CreateDesignEvent(part1, part2, part3, part4, part5, value));
	}
	public function SendErrorEvent(severity:String, message:String):Void
	{
		SendEvent(CreateErrorEvent(severity, message));
	}
	public function SendEvent(event:Dynamic):Void
	{
		if (!_sessionPresent)
		{
			trace("No session available");
			return;
		}
		_storage.SendEvent(Json.stringify(event));
	}
	/* Properties accessors */
	
	public function get_serverTimestamp():Float
	{
		return Date.now().getTime() + _timeOffset;
	}
	
	public function get_defaultValues():BaseEvent
	{
		return _defaultValues;
	}
	
	public function get_sandboxMode():Bool
	{
		return _sandboxMode;
	}
	
	public function set_sandboxMode(value:Bool):Bool
	{
		_sandboxMode = value;
		_urlFactory.SetHost(_sandboxMode?SANDBOX:PRODUCTION);
		return _sandboxMode;
	}
	
	public function get_gzip():Bool
	{
		return _gzip;
	}
	
	public function set_gzip(value:Bool):Bool
	{
		_gzip = value;
		_requestFactory.SetGzip(_gzip);
		return _gzip;
	}
	
	public function get_inited():Bool
	{
		return _inited;
	}
	
}