package net.lion123dev.data;

/**
 * ...
 * @author _lion123
 */
class DBlite
{

	public static inline var SESSION_NUM:String = "sessionNum";
	public static inline var TRANSACTION_NUM:String = "transactionNum";
	public static inline var USER_ID:String = "userId";
	public function new() 
	{
		
	}
	
	public function InitNew():Void
	{
		
	}
	
	public function IsInitialized():Bool
	{
		return false;
	}
	
	//KeyValues
	public function LoadKeyValue(key:String):String
	{
		return "1";
	}
	
	public function UpdateKeyValue(key:String, value:String):Void
	{
		
	}
	
	//Events
	public function GetNumEvents():Int
	{
		return 0;
	}
	
	public function PushEvent(event:String):Void
	{
		
	}
	
	public function GetFirstNEvents(n:Int):Array<String>
	{
		return null;
	}
	
	public function RemoveFirstNEvents(n:Int):Void
	{
		
	}
	
	//Progression
	public function GetAttemptNum(progressionEventId:String):Int
	{
		return 0;
	}
	
	public function UpdateAttemptNum(progressionEventId:String, attemptNum:Int):Void
	{
		
	}
}