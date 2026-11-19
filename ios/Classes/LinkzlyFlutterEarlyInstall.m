#import <Foundation/Foundation.h>
#if __has_include(<linkzly_flutter_sdk/linkzly_flutter_sdk-Swift.h>)
#import <linkzly_flutter_sdk/linkzly_flutter_sdk-Swift.h>
#elif __has_include("linkzly_flutter_sdk-Swift.h")
#import "linkzly_flutter_sdk-Swift.h"
#endif

/// Starts the iOS SDK's automatic capture of notification taps when the app's code is loaded,
/// before `main`. Plugins register in alphabetical order and the app's `AppDelegate` may set the
/// notification center's delegate before the Linkzly plugin registers; the tap that launched the
/// app is delivered before Dart can call configure. Hooking the delegate setter this early
/// catches all of them.
@interface LinkzlyFlutterEarlyInstall : NSObject
@end

@implementation LinkzlyFlutterEarlyInstall

+ (void)load {
  [LinkzlyFlutterSdkPlugin installNotificationOpenCapture];
}

@end
