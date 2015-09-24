package net.lion123dev.data.db;

/**
 * ...
 * @author _lion123
 */
import flash.net.SharedObject;
class SharedObjectAdapter extends DBadapter
{
	#if flash
	var _sharedObject:SharedObject;
	var _events:Array<String>;
	public function new(uniqueKey:String) 
	{
		super();
		_sharedObject = SharedObject.getLocal(uniqueKey);
	}
	override public function InitNew(uniqueKey:String):Void 
	{
		_sharedObject.data.initialized = true;
		_sharedObject.data.keyvalue = { };
		_sharedObject.data.progression = { };
		_sharedObject.flush();
		_events = [];
	}
	override public function Load(uniqueKey:String):Void 
	{
		_events = _sharedObject.data.events;
		if (_events == null) _events = [];
	}
	override public function IsInitialized():Bool 
	{
		return _sharedObject.data.initialized == true;
	}
	
	//KeyValues
	override public function LoadKeyValue(key:String):String 
	{
		return Reflect.field(_sharedObject.data.keyvalue, key);
	}
	override public function UpdateKeyValue(key:String, value:String):Void 
	{
		Reflect.setField(_sharedObject.data.keyvalue, key, value);
		_sharedObject.flush();
	}
	
	//Events
	override public function GetNumEvents():Int 
	{
		return _events.length;
	}
	override public function PushEvent(event:String):Void 
	{
		_events.push(event);
		_sharedObject.data.events = _events;
		_sharedObject.flush();
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
		_sharedObject.data.events = _events;
		_sharedObject.flush();
	}
	
	//Progression
	override public function GetAttemptNum(progressionEventId:String):Int 
	{
		if (!Reflect.hasField(_sharedObject.data.progression, progressionEventId))
		{
			Reflect.setField(_sharedObject.data.progression, progressionEventId, 0);
			_sharedObject.flush();
		}
		return Reflect.field(_sharedObject.data.progression, progressionEventId);
	}
	override public function UpdateAttemptNum(progressionEventId:String, attemptNum:Int):Void 
	{
		Reflect.setField(_sharedObject.data.progression, progressionEventId, attemptNum);
		_sharedObject.flush();
	}
	#end
}