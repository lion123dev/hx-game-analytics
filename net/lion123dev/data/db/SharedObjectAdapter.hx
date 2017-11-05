package net.lion123dev.data.db;
import openfl.net.SharedObject;

/**
 * ...
 * @author _lion123
 */

class SharedObjectAdapter extends DBadapter
{
	var _sharedObject:SharedObject;
	public function new(uniqueKey:String) 
	{
		super();
		_sharedObject = SharedObject.getLocal(uniqueKey);
	}
	override public function InitNew(uniqueKey:String):Void 
	{
		super.InitNew(uniqueKey);
		_sharedObject.data.initialized = true;
		_sharedObject.data.keyvalue = { };
		_sharedObject.data.progression = { };
		_sharedObject.data.events = "";
		_sharedObject.flush();
	}
	override public function Load(uniqueKey:String):Void 
	{
		super.Load(uniqueKey);
		_events = _sharedObject.data.events;
		if (_events == null) _events = [];
		var progressionValues:Dynamic = _sharedObject.data.progression;
		if (progressionValues != null)
		{
			for (k in Reflect.fields(progressionValues))
			{
				_progressionMap.set(k, cast(Reflect.field(progressionValues, k), Int));
			}
		}
		var keyValues:Dynamic = _sharedObject.data.keyvalue;
		if (keyValues != null)
		{
			for (k in Reflect.fields(keyValues))
			{
				_keyValueMap.set(k, cast(Reflect.field(keyValues, k), String));
			}
		}
	}
	override public function IsInitialized():Bool 
	{
		return _sharedObject.data.initialized == true;
	}
	
	//KeyValues
	override public function UpdateKeyValue(key:String, value:String):Void 
	{
		super.UpdateKeyValue(key, value);
		Reflect.setField(_sharedObject.data.keyvalue, key, value);
		_sharedObject.flush();
	}
	
	//Events
	override public function PushEvent(event:String):Void 
	{
		super.PushEvent(event);
		_sharedObject.data.events = _events;
		_sharedObject.flush();
	}
	override public function RemoveFirstNEvents(n:Int):Void 
	{
		super.RemoveFirstNEvents(n);
		_sharedObject.data.events = _events;
		_sharedObject.flush();
	}
	
	//Progression
	override public function UpdateAttemptNum(progressionEventId:String, attemptNum:Int):Void 
	{
		Reflect.setField(_sharedObject.data.progression, progressionEventId, attemptNum);
		_sharedObject.flush();
	}
}