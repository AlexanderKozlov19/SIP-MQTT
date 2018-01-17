//
//  AppDelegate.h
//  SIP MQTT
//
//  Created by Alexander Kozlov on 07.11.2017.
//  Copyright © 2017 Alexander Kozlov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CallKit/CallKit.h>
#import <PushKit/PushKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, PKPushRegistryDelegate, CXProviderDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) CXProvider *provider;
@property (nonatomic, strong) CXCallController *callKitCallController;


@end

