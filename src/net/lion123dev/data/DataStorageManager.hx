package net.lion123dev.data;
import net.lion123dev.data.db.DBadapter;
import net.lion123dev.data.db.SharedObjectAdapter;

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
	
	/**
	 * Choose an adapter based on current target
	 * @param	uniqueKey A unique Id for this game, use of gameKey is advised
	 */
	public function new(uniqueKey:String)
	{
		_uniqueKey = uniqueKey;
		#if flash
		_db = new SharedObjectAdapter(_uniqueKey);
		#else
		_db = new DBadapter();
		#end
	}
	
	/**
	 * Load data from the database (if it exists), else initialize database with default values
	 */
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
	
	/**
	 * Increment session number and generate new session id
	 */
	public function NewSession():Void
	{
		_sessionNum++;
		_sessionId = UID(8) + "-" + UID(4) + "-" + UID(4) + "-" + UID(4) + "-" + UID(12);
		_db.UpdateKeyValue(DBadapter.SESSION_NUM, Std.string(_sessionNum));
	}
	
	/**
	 * Increment transaction number, get it by accssing transactionNum property
	 */
	public function NewTransaction():Void
	{
		_transactionNum++;
		_db.UpdateKeyValue(DBadapter.TRANSACTION_NUM, Std.string(_transactionNum));
	}
	
	/**
	 * Increment an attempt number for a given event id
	 * @param	id Id of the event
	 * @return Incremented number
	 */
	public function NewAttempt(id:String):Int
	{
		var num:Int = _db.GetAttemptNum(id)+1;
		_db.UpdateAttemptNum(id, num);
		return num;
	}
	
	/**
	 * Add an event to the database
	 * @param	event Event to be added
	 */
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
	
	/**
	 * Get a new hex string of random data
	 * @param	length length of the string that should be created
	 * @return Hex string (ex.: a2863eab387b with length=12)
	 */
	public function UID(length:Int):String
	{
		var uid:StringBuf = new StringBuf();
		for (i in 0...length)
		{
			uid.add(StringTools.hex(Math.floor(Math.random() * 16)));
		}
		return uid.toString().toLowerCase();
	}
	
	/**
	 * Method delegated to the database adapter
	 * @return
	 */
	public function GetNumEvents():Int
	{
		return _db.GetNumEvents();
	}
	
	/**
	 * Method delegated to the database adapter
	 * @param	n
	 * @return
	 */
	public function GetFirstNEvents(n:Int):Array<String>
	{
		return _db.GetFirstNEvents(n);
	}
	
	/**
	 * Method delegated to the database adapter
	 * @param	n
	 */
	public function RemoveFirstNEvents(n:Int):Void
	{
		_db.RemoveFirstNEvents(n);
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
}