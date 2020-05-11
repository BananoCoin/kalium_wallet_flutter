#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import "Runner-Swift.h"

@implementation AppDelegate

- (void)lc_setAlternateIconName:(NSString*)iconName
{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(supportsAlternateIcons)] &&
        [[UIApplication sharedApplication] supportsAlternateIcons])
    {
        [[UIApplication sharedApplication] setAlternateIconName:iconName completionHandler:^(NSError * _Nullable error) {
                NSLog(@"Error...");
        }];
    }
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    FlutterViewController* controller = (FlutterViewController*)self.window.rootViewController;
    
    FlutterMethodChannel* appChannel = [FlutterMethodChannel
                                            methodChannelWithName:@"fappchannel"
                                            binaryMessenger:controller];
    
    [appChannel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
        if ([@"changeIcon" isEqualToString:call.method]) {
            NSDictionary *arguments = [call arguments];
            NSString *icon = arguments[@"icon"];
            if (icon == NULL || icon.length == 0) {
                result([FlutterError errorWithCode:@"error"
                                           message:@"Icon is required"
                                           details:nil]);
                return;
            }
            if ([@"kalium" isEqualToString:icon ]) {
                [self lc_setAlternateIconName:nil];
            } else if ([@"titanium" isEqualToString:icon]) {
                [self lc_setAlternateIconName:@"titanium"];
            } else if ([@"iridium" isEqualToString:icon]) {
                [self lc_setAlternateIconName:@"iridium"];
            } else if ([@"beryllium" isEqualToString:icon]) {
                [self lc_setAlternateIconName:@"beryllium"];
            } else if ([@"radium" isEqualToString:icon]) {
                [self lc_setAlternateIconName:@"radium"];
            }
        } else if ([@"setSecureClipboardItem" isEqualToString:call.method]) {
            NSDictionary *arguments = [call arguments];
            NSString *value = arguments[@"value"];
            [SecureClipboard setClipboardItem:value];
        } else {
            result(FlutterMethodNotImplemented);
        }
    }];
    
    [GeneratedPluginRegistrant registerWithRegistry:self];
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
