package net.lion123dev.data.db;
import haxe.ds.StringMap;

/**
 * ...
 * @author _lion123
 */
class DefaultAdapter extends DBadapter
{
	var _keyValueMap:StringMap<String>;
	var _progressionMap:StringMap<Int>;
	var _events:Array<String>;
	
	var _inited:Bool;
	public function new() 
	{
		super();
		_keyValueMap = new StringMap<String>();
		_progressionMap = new StringMap<Int>();
		_events = [];
		_inited = false;
	}
	override public function InitNew(uniqueKey:String):Void 
	{
		_inited = true;
	}
	override public function Load(uniqueKey:String):Void 
	{
		//Cannot load
	}
	override public function IsInitialized():Bool 
	{
		//DefaultAdapter cannot save stuff across sessions, so IsInitialized is always false at start
		return _inited;
	}
	
	//KeyValues
	override public function LoadKeyValue(key:String):String 
	{
		return _keyValueMap.get(key);
	}
	override public function UpdateKeyValue(key:String, value:String):Void 
	{
		_keyValueMap.set(key, value);
	}
	
	//Events
	override public function GetNumEvents():Int 
	{
		return _events.length;
	}
	override public function PushEvent(event:String):Void 
	{
		_events.push(event);
	}
	override public function GetFirstNEvents(n:Int):Array<String> 
	{
		var arr:Array<String>;
		if (n < _events.length)
			arr = _events.slice(0, n);
		else
			arr = _events.copy();
		return arr;
	}
	override public function RemoveFirstNEvents(n:Int):Void 
	{
		if (n >= _events.length)
		{
			_events = [];
		}else {
			_events = _events.slice(n);
		}
	}
	
	//Progression
	override public function GetAttemptNum(progressionEventId:String):Int 
	{
		if (!_progressionMap.exists(progressionEventId))
		{
			_progressionMap.set(progressionEventId, 0);
		}
		return _progressionMap.get(progressionEventId);
	}
	override public function UpdateAttemptNum(progressionEventId:String, attemptNum:Int):Void 
	{
		_progressionMap.set(progressionEventId, attemptNum);
	}
	
}