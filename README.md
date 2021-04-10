# PoC Detect Screenshot events on iOS

_Tested on iOS 12, iOS 13 and iOS 14_

This makes use of a private accessibility-oriented SpringBoard server `AXSpringBoardServer` inside the private framework `AccessibilityUtilities.framework`, by instantiating the server in a non-SpringBoard process and supplying a callback function to detect the event type - not limited to screenshot events (`6` when screenshot will fire and `7` when screenshot did fire).

No hooks or tweaks are required, so you can even adapt this into your GUI application - **with these entitlements**:

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
        ...
		<key>com.apple.accessibility.AccessibilityUIServer</key>
		<true/>
		<key>com.apple.security.exception.mach-lookup.global-name</key>
		<array>
			<string>com.apple.accessibility.AXSpringBoardServer</string>
		</array>
		...
	</dict>
</plist>
```

`com.apple.security.exception.mach-lookup.global-name` may or may not be required, but I added this with feeling that this should prevent some unforseen issues.

## Code

```
@interface AXSpringBoardServer : AXServer
+ (instancetype)server;
- (void)registerSpringBoardActionHandler:(void (^)(int))handler withIdentifierCallback:(void (^)(int))idCallback;
@end

AXSpringBoardServer *server = [%c(AXSpringBoardServer) server];

// identifierCallback must not be null, just supply a dummy callback
[server registerSpringBoardActionHandler:^(int eventType) {
    if (eventType == 6) {
        // screenshot will fire
    } else if (eventType == 7) {
        // screenshot did fire
    }
} withIdentifierCallback:^(int a){}];
```

## Spoofing entitlements

If it is not feasible to add the entitlements to your target application, you can hook `SecTaskCopyValueForEntitlement` function **from inside SpringBoard process** and make it return `kCFBooleanTrue` when the request comes from your application. The example project demonstrates how-to.

## Remarks
- **Never** register an action handler inside SpringBoard process.
- It works inside an application if the application has the needed entitilements.
- This logic is the same one AssistiveTouch uses for hiding itself during screen capturing.
- The argument type of `handler` is accurate, while the argument type of `identifierCallback` is a guessed one - because I was lazy.
