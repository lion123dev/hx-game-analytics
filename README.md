# Haxe game analytics
How to install: `haxelib install gameanalytics`
Here's a quick code snippet, explaining how to use the library:
(For more info see documentation in code or wiki)
## Initialization:
```
//instantiate new GameAnalytics object with public and private keys
//if the third parameter is true, a sandbox gameanalytics server will be used, so set it to false
var ga:GameAnalytics = new GameAnalytics("0123456789abcdef0123456789abcdef", "0123456789abcdef0123456789abcdef01234567", false);
//now we need to initialize it with success and fail callbacks, platform, os version, device and manufacturer. Some of these parameters may be removed later and auto generated instead.
ga.Init(onSuccess, onFail, "windows", "windows 10", "unknown", "manufacturer"
function onSuccess():Void
{
  //Success callback is called every time the request succeeds, not only on init. So be careful and do not actually send events here (this also may change later)
}
function onFail(error:String):Void
{
  //Fail callback basically means that GameAnalytics can't work right now. Offline event caching is not yet available.
  //String parameter may contain useful information on why fail happened
  trace(error);
  //Fail callback is called every time something bad happens, not only on init
}
```
## Sending events
```
//Events are send by calling Send<Type>Event. They are locally stored and then are submitted in batches to the GA servers
//There are two ways to post events:
//1) call StartPosting() (only once), and all sent events will be periodically submitted to the server
ga.StartPosting();
//2) or call ForcePost() every time you want to submit events
ga.SendBusinessEvent("gems", "green_gem", 1, "USD");
ga.SendResourceEvent(FlowType.SINK, "coin", "upgrades", "max_helath_2", 350);
ga.ForcePost();
//Call Create<Type>Event if you want to get an event and further customize it (e.g. change default fields or set optional values), after that call SendEvent(event)
//Send<Type>Event is an alias for SendEvent(Create<Type>Event)
//For more information on event types and parameters, see documentation in the code
```
