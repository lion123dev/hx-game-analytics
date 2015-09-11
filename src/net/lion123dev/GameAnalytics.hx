package src.net.lion123dev;
import haxe.crypto.Hmac;
import haxe.Http;
import haxe.Json;
import haxe.Timer;
import src.net.lion123dev.url.RequestFactory;
import src.net.lion123dev.url.URLFactory;

/**
 * ...
 * @author _lion123
 */
class GameAnalytics
{
	public static inline var DEFAULT_TIMER:Int = 20000;
	static inline var VERSION:String = "v2";
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
	
	var _urlFactory:URLFactory;
	var _requestFactory:RequestFactory;
	var _callbackSuccess:Void->Void;
	var _callbackFail:String->Void;
	var _timer:Timer;
	public var sandboxMode(get, set):Bool;
	public var gzip(get, set):Bool;
	public var inited(get, null):Bool;
	//TODO: use this timestamp
	public var timestamp:Int;
	
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
		
		_urlFactory = new URLFactory(PROTOCOL, VERSION, _sandboxMode?SANDBOX:PRODUCTION, _gameKey);
		_requestFactory = new RequestFactory(_gzip, _secretKey);
	}
	
	/**
	 * Initialize current Game Analytics object.
	 * @param	platform A string representing the platform of the SDK, e.g. "ios".
	 * @param	osVersion A string representing the OS version, e.g. "ios 8.1".
	 * @param	onSuccess Function to be called when the init request succeds.
	 * @param	onFail Function to be called if the request fails or the server responses with enabled:false.
	 */
	public function Init(platform:String, osVersion:String, onSuccess:Void->Void=null, onFail:String->Void=null):Void
	{
		if (_inited)
		{
			trace("Game Analytics already inited.");
			return;
		}
		_callbackSuccess = onSuccess;
		_callbackFail = onFail;
		var initRequest:InitRequest = { platform: platform, osVersion: osVersion, sdkVersion: "rest api v2" };
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
		_timer.run = onPostEvents;
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
		onPostEvents();
	}
	
	function onPostEvents():Void
	{
		
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
		timestamp = initResponse.server_ts;
		_callbackSuccess();
	}
	function onInitFail(msg:String):Void
	{
		var error:String = "Send init request fail: " + msg;
		trace(error);
		if(_callbackFail != null)
			_callbackFail(error);
	}
	
	
	/* Properties accessors */
	
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