# This library now uses OpenFL
For the longest time I tried to find a good cross-platform solution to save user Id, amount of sessions and other data.
Today I decided to go the easiest route and just stick a dependency on OpenFL. Let's see how it goes :)

# Haxe/OpenFL game analytics
How to install: `haxelib install gameanalytics`
Dependency: openfl http://www.openfl.org

Here's a quick code snippet, explaining how to use the library:
(For more info see documentation in code or use autocompletion)

## Initialization:
```haxe
// Instantiate new GameAnalytics object with public and private keys
// If the third parameter is true, a sandbox gameanalytics server will be used, so set it to false for production
var ga:GameAnalytics = new GameAnalytics("0123456789abcdef0123456789abcdef", "0123456789abcdef0123456789abcdef01234567", false);

// Now we need to initialize it with success and fail callbacks, platform, os version, device and manufacturer. Some of these parameters may be removed later and auto generated instead.
function onSuccess():Void
{
  // Success callback is called when init request return success.
}

function onFail(error:String):Void
{
  // Fail callback basically means that GameAnalytics can't work right now. Offline event caching is not yet available.
  // String parameter may contain useful information on why fail happened
  trace(error);
}

// IMPORTANT! Platform and os version must follow Game Analytics validation rules (see #1)
ga.Init(onSuccess, onFail, GAPlatform.WINDOWS, GAPlatform.WINDOWS + " 10", "unknown", "manufacturer");

// If you want a callback every time sending events fail or succeed, just rebind OnSubmitSuccess() and OnSubmitFail(reason:String) dynamic methods
function onSubmitFail(reason:String):Void
{
  trace(reason);
}

ga.OnSubmitFail = onSubmitFail;
```

## Sending events
```haxe
// Events are send by calling Send<Type>Event. They are locally stored and then are submitted in batches to the GA servers
// Call StartPosting() (only once), and all sent events will be periodically submitted to the server
ga.StartPosting();
ga.SendBusinessEvent("gems", "green_gem", 1, "USD");

// You can also call ForcePost(), but it's recommended only for a few situations
// For example, when your game is about to be closed you can do the following:
ga.EndSession();//send EndSession event
ga.ForcePost();

// For more information on event types and parameters, see documentation in the code
```

## Advanced stuff
```haxe
// Call Create<Type>Event if you want to get an event and further customize it (e.g. change default fields or set optional values), after that call SendEvent(event)
var e:DesignEvent = ga.CreateDesignEvent("world");
e.value = 4.2;
e.custom_01 = "ninja";
ga.SendEvent(e);
//Send<Type>Event is an alias for SendEvent(Create<Type>Event)
```
