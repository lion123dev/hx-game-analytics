package net.lion123dev.data.db;
import haxe.ds.StringMap;

/**
 * ...
 * @author _lion123
 */
class DBadapter
{

	public static inline var SESSION_NUM:String = "sessionNum";
	public static inline var TRANSACTION_NUM:String = "transactionNum";
	public static inline var USER_ID:String = "userId";
	
	var _keyValueMap:StringMap<String>;
	var _progressionMap:StringMap<Int>;
	var _events:Array<String>;
	
	var _inited:Bool;
	public function new() 
	{
		_keyValueMap = new StringMap<String>();
		_progressionMap = new StringMap<Int>();
		_events = [];
		_inited = false;
	}
	
	public function InitNew(uniqueKey:String):Void
	{
		_inited = true;
	}
	
	public function Load(uniqueKey:String):Void
	{
		_inited = true;
	}
	
	public function IsInitialized():Bool
	{
		return _inited;
	}
	
	//KeyValues
	public function LoadKeyValue(key:String):String
	{
		return _keyValueMap.get(key);
	}
	
	public function UpdateKeyValue(key:String, value:String):Void
	{
		_keyValueMap.set(key, value);
	}
	
	//Events
	public function GetNumEvents():Int
	{
		return _events.length;
	}
	
	public function PushEvent(event:String):Void
	{
		_events.push(event);
	}
	
	public function GetFirstNEvents(n:Int):Array<String>
	{
		var arr:Array<String>;
		if (n < _events.length)
			arr = _events.slice(0, n);
		else
			arr = _events.copy();
		return arr;
	}
	
	public function RemoveFirstNEvents(n:Int):Void
	{
		if (n >= _events.length)
		{
			_events = [];
		}else {
			_events = _events.slice(n);
		}
	}
	
	//Progression
	public function GetAttemptNum(progressionEventId:String):Int
	{
		if (!_progressionMap.exists(progressionEventId))
		{
			UpdateAttemptNum(progressionEventId, 0);
		}
		return _progressionMap.get(progressionEventId);
	}
	
	public function UpdateAttemptNum(progressionEventId:String, attemptNum:Int):Void
	{
		_progressionMap.set(progressionEventId, attemptNum);
	}
}