package net.lion123dev.events;

/**
 * ...
 * @author _lion123
 */
typedef BaseEvent = {
	public var device:String;
	public var v:Int;
	public var user_id:String;
	public var sdk_version:String;
	public var os_version:String;
	public var manufacturer:String;
	public var platform:String;
	public var session_id:String;
	public var session_num:UInt;
	public var client_ts:Float;
	@:optional public var limit_ad_tracking:Bool;
	@:optional public var logon_gamecenter:Bool;
	@:optional public var logon_googleplay:Bool;
	@:optional public var jailbroken:Bool;
	@:optional public var android_id:String;
	@:optional public var googleplus_id:String;
	@:optional public var facebook_id:String;
	@:optional public var gender:String;
	@:optional public var birth_year:Int;
	@:optional public var custom_01:String;
	@:optional public var custom_02:String;
	@:optional public var custom_03:String;
	@:optional public var build:String;
	@:optional public var engine_version:String;
	@:optional public var ios_idfv:String;
	@:optional public var connection_type:String;
	@:optional public var progression:String;
	@:optional public var ios_idfa:String;
	@:optional public var google_aid:String;
	
	@:optional public var category:String;
}
typedef SessionEndEvent = {> BaseEvent,
	public var length:Int;
}
typedef BusinessEvent = {> BaseEvent,
	public var event_id:String;
	public var amount:Int;
	public var currency:String;
	public var transaction_num:Int;
	@:optional public var cart_type:String;
	@:optional public var receipt_info:ReceiptInfo;
}
typedef ResourceEvent = {> BaseEvent,
	public var event_id:String;
	public var amount:Float;
}
typedef ProgressionEvent = {> BaseEvent,
	public var event_id:String;
	@:optional public var attempt_num:Int;
	@:optional public var score:Int;
}
typedef DesignEvent = {> BaseEvent,
	public var event_id:String;
	@:optional public var value:Float;
}
typedef ErrorEvent = {> BaseEvent,
	public var severity:String;
	public var message:String;
}
typedef ReceiptInfo = {
	public var store:String;
	public var receipt:String;
	public var signature:String;
}
class Events
{
	static var OPTIONAL_PARAMS:Array<String> = ["limit_ad_tracking", "logon_gamecenter", "logon_googleplay", "jailbroken", "android_id", "googleplus_id", "facebook_id", "gender", "birth_year", "custom_01", "custom_02", "custom_03", "build", "engine_version", "ios_idfv", "connection_type", "progression", "ios_idfa", "google_aid"];
	static inline var USER_CATEGORY:String = "user";
	static inline var SESSION_END_CATEGORY:String = "session_end";
	static inline var BUSINESS_CATEGORY:String = "business";
	static inline var RESOURCE_CATEGORY:String = "resource";
	static inline var PROGRESSION_CATEGORY:String = "progression";
	static inline var DESIGN_CATEGORY:String = "design";
	static inline var ERROR_CATEGORY:String = "error";
	
	public static function GetUserEvent(base:BaseEvent):BaseEvent
	{
		return getCopyWithCategory(base, USER_CATEGORY);
	}
	public static function GetSessionEndEvent(base:BaseEvent, length:Int):SessionEndEvent
	{
		var event:SessionEndEvent = { length: length, category: SESSION_END_CATEGORY, device:base.device, v:base.v, user_id:base.user_id, sdk_version:base.sdk_version, os_version:base.os_version, manufacturer: base.manufacturer, platform:base.platform, session_id:base.session_id, session_num:base.session_num, client_ts:base.client_ts };
		moveOptionalParams(event, base);
		return event;
	}
	public static function GetBusinessEvent(base:BaseEvent, eventId:String, amount:Int, currency:String, transactionNum:Int):BusinessEvent
	{
		var event:BusinessEvent = { event_id: eventId, amount: amount, currency: currency, transaction_num: transactionNum, category: BUSINESS_CATEGORY, device:base.device, v:base.v, user_id:base.user_id, sdk_version:base.sdk_version, os_version:base.os_version, manufacturer: base.manufacturer, platform:base.platform, session_id:base.session_id, session_num:base.session_num, client_ts:base.client_ts };
		moveOptionalParams(event, base);
		return event;
	}
	public static function GetResourceEvent(base:BaseEvent, eventId:String, amount:Float):ResourceEvent
	{
		var event:ResourceEvent = { event_id: eventId, amount: amount, category: RESOURCE_CATEGORY, device:base.device, v:base.v, user_id:base.user_id, sdk_version:base.sdk_version, os_version:base.os_version, manufacturer: base.manufacturer, platform:base.platform, session_id:base.session_id, session_num:base.session_num, client_ts:base.client_ts };
		moveOptionalParams(event, base);
		return event;
	}
	public static function GetProgressionEvent(base:BaseEvent, eventId:String):ProgressionEvent
	{
		var event:ProgressionEvent = { event_id: eventId, category: PROGRESSION_CATEGORY, device:base.device, v:base.v, user_id:base.user_id, sdk_version:base.sdk_version, os_version:base.os_version, manufacturer: base.manufacturer, platform:base.platform, session_id:base.session_id, session_num:base.session_num, client_ts:base.client_ts };
		moveOptionalParams(event, base);
		return event;
	}
	public static function GetDesignEvent(base:BaseEvent, eventId:String):DesignEvent
	{
		var event:DesignEvent = { event_id: eventId, category: DESIGN_CATEGORY, device:base.device, v:base.v, user_id:base.user_id, sdk_version:base.sdk_version, os_version:base.os_version, manufacturer: base.manufacturer, platform:base.platform, session_id:base.session_id, session_num:base.session_num, client_ts:base.client_ts };
		moveOptionalParams(event, base);
		return event;
	}
	public static function GetErrorEvent(base:BaseEvent, severity:String, message:String):ErrorEvent
	{
		var event:ErrorEvent = { severity: severity, message:message, category: ERROR_CATEGORY, device:base.device, v:base.v, user_id:base.user_id, sdk_version:base.sdk_version, os_version:base.os_version, manufacturer: base.manufacturer, platform:base.platform, session_id:base.session_id, session_num:base.session_num, client_ts:base.client_ts };
		moveOptionalParams(event, base);
		return event;
	}
	static function getCopyWithCategory(base:BaseEvent, category:String):BaseEvent
	{
		var copy:BaseEvent = Reflect.copy(base);
		copy.category = category;
		return copy;
	}
	static function moveOptionalParams(leftSide:Dynamic, rightSide:BaseEvent):Void
	{
		for (param in OPTIONAL_PARAMS)
		{
			if (Reflect.field(rightSide, param) != null)
				Reflect.setField(leftSide, param, Reflect.field(rightSide, param));
		}
	}
}
class GenderString
{
	public static inline var MALE:String = "male";
	public static inline var FEMALE:String = "female";
}
class ConnectionType
{
	public static inline var OFFLINE:String = "offline";
	public static inline var WWAN:String = "wwan";
	public static inline var WIFI:String = "wifi";
	public static inline var LAN:String = "lan";
}
class ErrorSeverity
{
	public static inline var DEBUG:String = "debug";
	public static inline var INFO:String = "info";
	public static inline var WARNING:String = "warning";
	public static inline var ERROR:String = "error";
	public static inline var CRITICAL:String = "critical";
}