package net.lion123dev.data;
import net.lion123dev.data.db.DBadapter;
import net.lion123dev.data.db.SharedObjectAdapter;
import net.lion123dev.data.db.SQliteAdapter;

/**
 * ...
 * @author _lion123
 */
class DataStorageManager
{
	var _userId:String;
	var _sessionId:String;
	var _sessionNum:Int;
	var _transactionNum:Int;
	var _db:DBadapter;
	var _uniqueKey:String;
	public var userId(get, null):String;
	public var sessionId(get, null):String;
	public var sessionNum(get, null):Int;
	public var transactionNum(get, null):Int;
	public var db(get, null):DBadapter;
	
	public function new(uniqueKey:String)
	{
		_uniqueKey = uniqueKey;
		#if flash
		_db = new SharedObjectAdapter(_uniqueKey);
		#elseif neko
		_db = new SQliteAdapter();
		#elseif cpp
		_db = new SQliteAdapter();
		#else
		_db = new DBadapter();
		#end
	}
	
	public function Init():Void
	{
		if (_db.IsInitialized())
		{
			//load data
			_db.Load(_uniqueKey);
			_sessionNum = Std.parseInt(_db.LoadKeyValue(DBadapter.SESSION_NUM));
			_transactionNum = Std.parseInt(_db.LoadKeyValue(DBadapter.TRANSACTION_NUM));
			_userId = _db.LoadKeyValue(DBadapter.USER_ID);
		}else {
			//new data
			_db.InitNew(_uniqueKey);
			_sessionNum = 0;
			_transactionNum = 0;
			_userId = UID(12);
			SaveAll();
		}
	}
	
	public function NewSession():Void
	{
		_sessionNum++;
		_sessionId = UID(8) + "-" + UID(4) + "-" + UID(4) + "-" + UID(4) + "-" + UID(12);
		_db.UpdateKeyValue(DBadapter.SESSION_NUM, Std.string(_sessionNum));
	}
	
	public function NewTransaction():Void
	{
		_transactionNum++;
		_db.UpdateKeyValue(DBadapter.TRANSACTION_NUM, Std.string(_transactionNum));
	}
	
	public function NewAttempt(id:String):Int
	{
		var num:Int = _db.GetAttemptNum(id)+1;
		_db.UpdateAttemptNum(id, num);
		return num;
	}
	
	public function SendEvent(event:String):Void
	{
		_db.PushEvent(event);
	}
	
	function SaveAll():Void
	{
		_db.UpdateKeyValue(DBadapter.USER_ID, _userId);
		_db.UpdateKeyValue(DBadapter.SESSION_NUM, Std.string(_sessionNum));
		_db.UpdateKeyValue(DBadapter.TRANSACTION_NUM, Std.string(_transactionNum));
	}
	
	public function UID(length:Int):String
	{
		var uid:StringBuf = new StringBuf();
		for (i in 0...length)
		{
			uid.add(StringTools.hex(Math.floor(Math.random() * 16)));
		}
		return uid.toString().toLowerCase();
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
	
	public function get_sessionNum():Int
	{
		return _sessionNum;
	}
	
	public function get_transactionNum():Int
	{
		return _transactionNum;
	}
	
	public function get_db():DBadapter
	{
		return _db;
	}
}