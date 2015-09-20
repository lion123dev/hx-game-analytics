package src.net.lion123dev.url;
import haxe.crypto.Base64;
import haxe.crypto.BaseCode;
import haxe.crypto.Hmac;
import haxe.Http;
import haxe.io.Bytes;
import haxe.zip.Compress;

/**
 * ...
 * @author _lion123
 */
typedef InitRequest = {
	var platform:String;
	var os_version:String;
	var sdk_version:String;
}
typedef InitResponse = {
	var enabled:Bool;
	var server_ts:Int;
	@:optional var flags:Array<String>;
}
class RequestFactory
{

	var _gzip:Bool;
	var _secretKey:String;
	var _hmac:Hmac;
	
	public function new(gzip:Bool, secretKey:String) 
	{
		_secretKey = secretKey;
		SetGzip(gzip);
		_hmac = new Hmac(HashMethod.SHA256);
	}
	
	/**
	 * Get a new Http request object with headers and body, ready to be posted.
	 * @param	url full url to the endpoint, including protocol (http://).
	 * @param	data data to include in the post.
	 * @return Http Request, call .request(
	 */
	public function MakeRequest(url:String, data:String):Http
	{
		trace("data: " + data);
		var request:Http = new Http(url);
		var postData:String = data;
		request.addHeader("Content-Type", "application/json");
		if (_gzip)
		{
			//TODO: Not implemented yet
			//request.addHeader("Content-Encoding", "gzip");
			//postData = "";
		}
		var cryptoString:String = Base64.encode(_hmac.make(Bytes.ofString(_secretKey), Bytes.ofString(data)));
		request.addHeader("Authorization", cryptoString);
		request.setPostData(postData);
		return request;
	}
	
	public function SetGzip(value:Bool):Bool
	{
		_gzip = value;
		return _gzip;
	}
}