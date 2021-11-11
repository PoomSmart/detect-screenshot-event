#import "../PS.h"

typedef struct __SecTask *SecTaskRef;

CGFloat backlightLevel = 0.5;

@interface AXServer : NSObject
@end

@interface AXSpringBoardServer : AXServer
+ (instancetype)server;
- (void)registerSpringBoardActionHandler:(void (^)(int))handler withIdentifierCallback:(void (^)(int))idCallback;
@end

extern CFTypeRef SecTaskCopyValueForEntitlement(SecTaskRef task, CFStringRef entitlement, CFErrorRef *error);
extern CFStringRef SecTaskCopySigningIdentifier(SecTaskRef task, CFErrorRef *error);

void (*AXPerformBlockAsynchronouslyOnMainThread)(void (^)(void));

%group SB

// Spoof needed entitlement
%hookf(CFTypeRef, SecTaskCopyValueForEntitlement, SecTaskRef task, CFStringRef entitlement, CFErrorRef *error) {
	if (CFStringEqual(entitlement, CFSTR("com.apple.accessibility.AccessibilityUIServer"))) {
		CFStringRef identifier = SecTaskCopySigningIdentifier(task, NULL);
		if (identifier) {
			CFRelease(identifier);
			// Whitelist only Settings app, for example
			if (CFStringEqual(identifier, CFSTR("com.apple.Preferences")))
				return kCFBooleanTrue;
		}
	}
	return %orig(task, entitlement, error);
}

%end

%ctor {
	if (IN_SPRINGBOARD) {
		%init(SB);
	} else {
		// NEVER register SpringBoard action handlers inside SpringBoard itself
		dlopen("/System/Library/PrivateFrameworks/AccessibilityUtilities.framework/AccessibilityUtilities", RTLD_NOW);
		MSImageRef axc = MSGetImageByName("/System/Library/PrivateFrameworks/AXCoreUtilities.framework/AXCoreUtilities");
		AXPerformBlockAsynchronouslyOnMainThread = (void (*)(void (^)(void)))_PSFindSymbolCallable(axc, "_AXPerformBlockAsynchronouslyOnMainThread");
		AXSpringBoardServer *server = [%c(AXSpringBoardServer) server];
		[server registerSpringBoardActionHandler:^(int eventType) {
			AXPerformBlockAsynchronouslyOnMainThread(^{
				if (eventType == 6) {
					backlightLevel = UIScreen.mainScreen.brightness;
					UIScreen.mainScreen.brightness = 1.0;
				} else if (eventType == 7) {
					UIScreen.mainScreen.brightness = backlightLevel;
				}
			});
		} withIdentifierCallback:^(int a){}];
	}
}