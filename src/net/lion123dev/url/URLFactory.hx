package src.net.lion123dev.url;

/**
 * ...
 * @author _lion123
 */
class URLFactory
{
	var _protocol:String;
	var _prefix:String;
	var _host:String;
	var _controller:String;
	
	var _result:String;
	
	public function new(protocol:String, prefix:String=null, host:String=null, controller:String=null) 
	{
		_protocol = protocol;
		_prefix = prefix;
		_host = host;
		_controller = controller;
		Update();
	}
	
	public function SetProtocol(value:String):Void
	{
		_protocol = value;
		Update();
	}
	public function SetPrefix(value:String):Void
	{
		_prefix = value;
		Update();
	}
	public function SetHost(value:String):Void
	{
		_host = value;
		Update();
	}
	public function SetController(value:String):Void
	{
		_controller = value;
		Update();
	}
	
	function Update():Void
	{
		var result:StringBuf = new StringBuf();
		result.add(_protocol);
		for (s in [_prefix, _host, _controller])
		{
			if (s != null && s != "")
			{
				result.add(s);
				result.add("/");
			}
		}
		_result = result.toString();
	}
	
	/**
	 * Get a new url, fast.
	 * @param	action action name (init, events).
	 * @return url
	 */
	public function BuildUrl(action:String):String
	{
		return _result + action;
	}
	
}