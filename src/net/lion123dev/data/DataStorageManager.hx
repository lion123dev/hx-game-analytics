package net.lion123dev.data;

/**
 * ...
 * @author _lion123
 */
class DataStorageManager
{
	var _userId:String;
	var _sessionId:String;
	var _sessionNum:UInt;
	public var userId(get, null):String;
	public var sessionId(get, null):String;
	public var sessionNum(get, null):UInt;
	
	public function new() { }
	
	public function Init():Void
	{
		//increment/ session_num
		//init user_id 
	}
	
	function newData():Void
	{
		//session_num=1, save session_num
		//session_id=rnd
		//user_id=rnd, save user_id
	}
	function loadData():Void
	{
		//session_num++, save session_num
		//session_id=rnd
		//user_id not changed
	}
	
	/* Properties accessors */
	
	public function get_userId():String
	{
		return _userId;
	}
	
	public function get_sessionId():String
	{
		return _sessionId;
	}
	
	public function get_sessionNum():UInt
	{
		return _sessionNum;
	}
}