package net.lion123dev;
import haxe.crypto.Hmac;
import haxe.Http;
import haxe.Json;
import haxe.Timer;
import net.lion123dev.data.DataStorageManager;
import net.lion123dev.events.Events;
import net.lion123dev.events.Events.BaseEvent;
import net.lion123dev.url.RequestFactory;
import net.lion123dev.url.URLFactory;

/**
 * ...
 * @author _lion123
 */
class GameAnalytics
{
	public static inline var MAX_ERRORS:Int = 10;
	public static inline var EVENTS_THRESHOLD:Int = 50;
	public static inline var BIG_EVENTS_THRESHOLD:Int = 10000;
	public static inline var DEFAULT_TIMER:Int = 20000;
	public static inline var MAX_MESSAGE_LENGTH:Int = 100000;
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
	var _amountEvents:Int;
	var _amountErrors:Int;
	var _waitingForResponse:Bool = false;
	
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
		_amountErrors = 0;
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
	 * @param	onSuccess Function to be called when requests succeed.
	 * @param	onFail Function to be called when requests fail, with the reason message.
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
		_callbackSuccess = onSuccess;
		_callbackFail = onFail;
		if (_inited)
		{
			trace("Game Analytics already inited, not sending init request");
			return;
		}
		var initRequest:InitRequest = { platform: platform, os_version: osVersion, sdk_version: SDK_VERSION };
		var request:Http = _requestFactory.MakeRequest(_urlFactory.BuildUrl(ACTION_INIT), Json.stringify(initRequest));
		request.onError = onInitFail;
		request.onData = onInitSuccess;
		_waitingForResponse = true;
		request.request(true);
	}
	
	/**
	 * Call this function to start automatically posting events on a given interval.
	 * @param	interval in millseconds, must be greater than 1000, default is 20000
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
	
	/**
	 * Start a new playing session - a time period of user actively playing the game. Events can not be sent if no session is present. Called automatically on Init.
	 */
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
		_defaultValues.session_num = _storage.sessionNum;
		SendSessionStartEvent();
	}
	
	/**
	 * End current session - call this before exitiing the game or if detected that user went afk or paused the game for a long period of time.
	 */
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
		var numEvents:Int = _storage.GetNumEvents();
		if (numEvents == 0)
			return;
		if (numEvents >= BIG_EVENTS_THRESHOLD)
		{
			trace("More than " + BIG_EVENTS_THRESHOLD + " events in queue. Trimming...");
			_storage.RemoveFirstNEvents(numEvents - BIG_EVENTS_THRESHOLD);
		}
		_amountEvents = EVENTS_THRESHOLD;
		var success:Bool = false;
		var message:String = "";
		var events:Array<String> = null;
		while(!success)
		{
			events = _storage.GetFirstNEvents(_amountEvents);
			message = "[" + events.join(",") + "]";
			if (message.length > MAX_MESSAGE_LENGTH)
			{
				_amountEvents = Math.floor(_amountEvents / 2);
			}else{
				success = true;
			}
		}
		var request:Http = _requestFactory.MakeRequest(_urlFactory.BuildUrl(ACTION_EVENT), message);
		request.onStatus = onEventsRequestStatus;
		request.onError = onEventsRequestError;
		request.onData = onEventsRequestData;
		_waitingForResponse = true;
		request.request(true);
	}
	
	function onEventsRequestData(data:String):Void
	{
		
	}
	
	function onEventsRequestError(message:String):Void
	{
		if(OnSubmitFail != null)
			OnSubmitFail(message);
	}
	
	function onEventsRequestStatus(status:Int):Void
	{
		_waitingForResponse = false;
		_storage.RemoveFirstNEvents(_amountEvents);
		if (status == 200)
		{
			if (OnSubmitSuccess != null)
				OnSubmitSuccess();
		}else {
			if (OnSubmitFail != null)
				OnSubmitFail("Error status: " + Std.string(status));
		}
	}
	
	function onInitSuccess(data:String):Void
	{
		_waitingForResponse = false;
		var initResponse:InitResponse = Json.parse(data);
		if (!initResponse.enabled)
		{
			var error:String = "Game Analytics server doesn't want to work today :(";
			trace(error);
			if (_callbackFail != null)
				_callbackFail(error);
			return;
		}
		_timeOffset = initResponse.server_ts - Math.floor(Date.now().getTime()/1000);
		_inited = true;
		NewSession();
		if(_callbackSuccess != null)
			_callbackSuccess();
	}
	function onInitFail(msg:String):Void
	{
		_waitingForResponse = false;
		var error:String = "Send init request fail: " + msg;
		trace(error);
		if(_callbackFail != null)
			_callbackFail(error);
	}
	
	//Events creating/sending. SendDesignEvent is an alias for SendEvent(CreateDesignEvent(..params))
	function CreateSessionStartEvent():BaseEvent
	{
		updateClientTimestamp();
		return Events.GetUserEvent(_defaultValues);
	}
	function CreateSessionEndEvent(length:Int):SessionEndEvent
	{
		updateClientTimestamp();
		return Events.GetSessionEndEvent(_defaultValues, length);
	}
	/**
	 * Create a new Business event (real money purchase), but do not send it yet
	 * @param	itemType A category/folder for the item bought (ex.: GemPack)
	 * @param	itemId Identifier for the item bought (ex.: gems_50)
	 * @param	amount Amount of items bought
	 * @param	currency Three letter uppercase representation of REAL currency spent
	 * @return BusinessEvent, can be further customized
	 */
	public function CreateBusinessEvent(itemType:String, itemId:String, amount:Int, currency:String):BusinessEvent
	{
		updateClientTimestamp();
		_storage.NewTransaction();
		return Events.GetBusinessEvent(_defaultValues, itemType+":" + itemId, amount, currency, _storage.transactionNum);
	}
	/**
	 * Create a new Resource event (for tracking the flow of virtual currency), but do not send it yet
	 * @param	flowType Use FlowType.[SINK|SOURCE], where Sink means spending virtual currency on something
	 * @param	virtualCurrency The type of resource spent/gained
	 * @param	itemType A category/folder of where the resource was spent/gained
	 * @param	itemId Identificator of where the resource was spent/gained
	 * @param	amount Amount of resource spent/gained
	 * @return ResourceEvent, can be further customized
	 */
	public function CreateResourceEvent(flowType:String, virtualCurrency:String, itemType:String, itemId:String, amount:Float):ResourceEvent
	{
		updateClientTimestamp();
		return Events.GetResourceEvent(_defaultValues, [flowType, virtualCurrency, itemType, itemId].join(":"), amount);
	}
	/**
	 * Create a new Progression event (for tracking user attempts at completing levels), but do not send it yet
	 * @param	progressionStatus Status of progression, use ProgressionStatus.[START|FAIL|COMPLETE]
	 * @param	progression1 Part of event id (ex.:levelset_0)
	 * @param	progression2 Second part of event id (ex.:PirateIsland), optional
	 * @param	progression3 Third part of event id (ex.:SandyHills), optional
	 * @return ProgressionEvent, can be further customized
	 */
	public function CreateProgressionEvent(progressionStatus:String, progression1:String, progression2:String=null, progression3:String=null):ProgressionEvent
	{
		updateClientTimestamp();
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
	/**
	 * Create a new custom Design event, but do not send it yet
	 * @param	part1 First part of event id
	 * @param	part2 Optional part of event id
	 * @param	part3 Optional part of event id
	 * @param	part4 Optional part of event id
	 * @param	part5 Optional part of event id
	 * @param	value Optional value parameter, null by default
	 * @return DesignEvent, can be further customized
	 */
	public function CreateDesignEvent(part1:String, part2:String=null, part3:String=null, part4:String=null, part5:String=null, value:Null<Float> = null):DesignEvent
	{
		updateClientTimestamp();
		var event_id:String = part1;
		for (s in [part2, part3, part4, part5])
		{
			if (s != null) event_id += s;
		}
		var event:DesignEvent = Events.GetDesignEvent(_defaultValues, event_id);
		if (value != null) event.value = value;
		return event;
	}
	/**
	 * Create a new Error event, but do not send it yet
	 * @param	severity Use ErrorSeverity.[DEBUG|INFO|WARNING|ERROR|CRITICAL]
	 * @param	message Error message
	 * @return ErrorEvent, can be further customized
	 */
	public function CreateErrorEvent(severity:String, message:String):ErrorEvent
	{
		updateClientTimestamp();
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
	function updateClientTimestamp():Void
	{
		_defaultValues.client_ts = serverTimestamp;
	}
	/**
	 * Send a BusinessEvent (see CreateBusinessEvent for more info)
	 */
	public function SendBusinessEvent(itemType:String, itemId:String, amount:Int, currency:String):Void
	{
		SendEvent(CreateBusinessEvent(itemType, itemId, amount, currency));
	}
	/**
	 * Send a ResourceEvent (see CreateResourceEvent for more info)
	 */
	public function SendResourceEvent(flowType:String, virtualCurrency:String, itemType:String, itemId:String, amount:Float):Void
	{
		SendEvent(CreateResourceEvent(flowType, virtualCurrency, itemType, itemId, amount));
	}
	/**
	 * Send a ProgressionEvent (see CreateProgressionEvent for more info)
	 */
	public function SendProgressionEvent(progressionStatus:String, progression1:String, progression2:String, progression3:String):Void
	{
		SendEvent(CreateProgressionEvent(progressionStatus, progression1, progression2, progression3));
	}
	/**
	 * Send a DesignEvent (see CreateDesignEvent for more info)
	 */
	public function SendDesignEvent(part1:String, part2:String = null, part3:String = null, part4:String = null, part5:String = null, value:Null<Float> = null):Void
	{
		SendEvent(CreateDesignEvent(part1, part2, part3, part4, part5, value));
	}
	/**
	 * Send an ErrorEvent (see CreateErrorEvent for more info)
	 */
	public function SendErrorEvent(severity:String, message:String):Void
	{
		SendEvent(CreateErrorEvent(severity, message));
	}
	/**
	 * Send a premade event
	 * @param	event
	 */
	public function SendEvent(event:Dynamic):Void
	{
		if (!_sessionPresent)
		{
			trace("No session available");
			return;
		}
		if (Reflect.field(event, "category") == Events.ERROR_CATEGORY)
		{
			_amountErrors++;
			if (_amountErrors >= MAX_ERRORS) return;
		}
		_storage.SendEvent(Json.stringify(event));
	}
	
	public dynamic function OnSubmitSuccess():Void
	{
		
	}
	
	public dynamic function OnSubmitFail(reason:String):Void
	{
		
	}
	
	/* Properties accessors */
	
	public function get_serverTimestamp():Float
	{
		return Math.floor(Date.now().getTime()/1000) + _timeOffset;
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