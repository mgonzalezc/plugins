// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTQuickActionsPlugin.h"

static NSString *const CHANNEL_NAME = @"plugins.flutter.io/quick_actions";

@interface FLTQuickActionsPlugin ()
@property(nonatomic, retain) FlutterMethodChannel *channel;
@property (nonatomic, strong) NSString *shortcutType;
@end

@implementation FLTQuickActionsPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:CHANNEL_NAME
                                  binaryMessenger:[registrar messenger]];
  FLTQuickActionsPlugin *instance = [[FLTQuickActionsPlugin alloc] init];
  instance.channel = channel;
  [registrar addMethodCallDelegate:instance channel:channel];
    [registrar addApplicationDelegate:instance];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([call.method isEqualToString:@"setShortcutItems"]) {
    setShortcutItems(call.arguments);
    result(nil);
  } else if ([call.method isEqualToString:@"clearShortcutItems"]) {
    if (@available(iOS 9.0, *)) {
        [UIApplication sharedApplication].shortcutItems = @[];
    }
    result(nil);
  } else if ([call.method isEqualToString:@"getLaunchAction"]) {
    result(self.shortcutType); // This is used when the app is killed and open the first time via quick actions
    self.shortcutType = nil;
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)dealloc {
  [self.channel setMethodCallHandler:nil];
  self.channel = nil;
}

- (BOOL)application:(UIApplication *)application
    performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
               completionHandler:(void (^)(BOOL succeeded))completionHandler API_AVAILABLE(ios(9.0)){
  NSLog(@"Called via shortcuts: %@", shortcutItem.type);
  self.shortcutType = shortcutItem.type;
  [self.channel invokeMethod:@"launch" arguments:shortcutItem.type];
  
  return YES;
    
}

- (BOOL)application:(UIApplication *)application
WillFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
    
    if (@available(iOS 9.0, *)) {
        UIApplicationShortcutItem *shortcutItem = launchOptions[UIApplicationLaunchOptionsShortcutItemKey];
        if(shortcutItem != NULL) {
            self.shortcutType = shortcutItem.type;
            [self.channel invokeMethod:@"launch" arguments:shortcutItem.type];
            return NO;
        } else {
            [self.channel invokeMethod:@"launch" arguments:nil];
            self.shortcutType = nil;
        }
    }
    
    return YES;
}

#pragma mark Private functions

static void setShortcutItems(NSArray *items) {
    if (@available(iOS 9.1, *)) {
        NSMutableArray *newShortcuts = [[NSMutableArray alloc] init];
        
        for (id item in items) {
            UIApplicationShortcutItem *shortcut = deserializeShortcutItem(item);
            [newShortcuts addObject:shortcut];
        }
        
        [UIApplication sharedApplication].shortcutItems = newShortcuts;
    }
}

API_AVAILABLE(ios(9.1))
static UIApplicationShortcutItem *deserializeShortcutItem(NSDictionary *serialized) {
    
    NSString *iconAsString = serialized[@"icon"];
    UIApplicationShortcutIcon *icon = nil;
    
    if ([iconAsString isEqualToString:@"icon_quick_action_search"]) {
        icon = [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeSearch];
    } else if ([iconAsString isEqualToString:@"icon_quick_action_play"]) {
        icon = [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypePlay];
    } else if ([iconAsString isEqualToString:@"icon_quick_action_favorites"]) {
        icon = [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeLove];
    } else {
        icon = [iconAsString isKindOfClass:[NSNull class]] ? nil
        : [UIApplicationShortcutIcon iconWithTemplateImageName:serialized[@"icon"]];
    }

    return [[UIApplicationShortcutItem alloc] initWithType:serialized[@"type"]
                                            localizedTitle:serialized[@"localizedTitle"]
                                         localizedSubtitle:nil
                                                      icon:icon
                                                  userInfo:nil];
}

@end
