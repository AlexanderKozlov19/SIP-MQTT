//
//  AppDelegate.m
//  SIP MQTT
//
//  Created by Alexander Kozlov on 07.11.2017.
//  Copyright © 2017 Alexander Kozlov. All rights reserved.
//

#import "AppDelegate.h"
#import "MQTT.h"



#import <UserNotifications/UserNotifications.h>

#include <pjsua-lib/pjsua.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize provider;



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    /*CXProviderConfiguration *configuration = [[CXProviderConfiguration alloc] initWithLocalizedName:@"SIPMQTT"];
    
    configuration.supportsVideo = NO;
    configuration.supportedHandleTypes = [[NSSet alloc] initWithObjects:[NSNumber numberWithInt:(int)CXHandleTypeGeneric], nil];
    configuration.maximumCallGroups = 1;
    configuration.maximumCallsPerCallGroup = 5;
    self.provider = [[CXProvider alloc] initWithConfiguration:configuration];
    [self.provider setDelegate:self queue:NULL];
    self.callKitCallController = [[CXCallController alloc] init];
    */
   /* PKPushRegistry *pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    pushRegistry.delegate = self;
    pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    */
    /*
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:<#(UNAuthorizationOptions)#> completionHandler:<#^(BOOL granted, NSError * _Nullable error)completionHandler#>
    //UNUserNotificationCenter.current().requestAuthorization
    // Override point for customization after application launch.
    */
   // [[SIPpj SharedCurrencyService] startSIP:"iPhone" domain:"192.168.0.40"];
   // startPjsip(, );
    //makeCall("sip:192.168.43.106:5080");
   
    return YES;
}

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type{
    if([credentials.token length] == 0) {
        NSLog(@"voip token NULL");
        return;
    }
    
    NSLog(@"PushCredentials: %@", credentials.token);
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type
{
    NSLog(@"didReceiveIncomingPushWithPayload");
}



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)providerDidReset:(CXProvider *)provider {
    NSLog(@"providerDidReset:");
}

- (void)providerDidBegin:(CXProvider *)provider {
    NSLog(@"providerDidBegin:");
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
    NSLog(@"provider:didActivateAudioSession:");
    
   // [[VoiceClient sharedInstance] startAudioDevice];
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
    NSLog(@"provider:didDeactivateAudioSession:");
}

- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action {
    NSLog(@"provider:timedOutPerformingAction:");
}

- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action {
    NSLog(@"provider:performStartCallAction:");
    
   /* [[VoiceClient sharedInstance] configureAudioSession];
    
    self.call = [[VoiceClient sharedInstance] call:[self fetchAccessToken]
                                            params:@{}
                                          delegate:self];
    
    if (!self.call) {
        [action fail];
    } else {
        self.call.uuid = action.callUUID;
        [self toggleUIState:NO];
        [self startSpin];
        
        [action fulfillWithDateStarted:[NSDate date]];
    }*/
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    NSLog(@"provider:performAnswerCallAction:");
    
    // RCP: Workaround from https://forums.developer.apple.com/message/169511 suggests configuring audio in the
    //      completion block of the `reportNewIncomingCallWithUUID:update:completion:` method instead of in
    //      `provider:performAnswerCallAction:` per the WWDC examples.
    // [[VoiceClient sharedInstance] configureAudioSession];
    
   /* self.call = [self.callInvite acceptWithDelegate:self];
    if (self.call) {
        self.call.uuid = [action callUUID];
    }
    
    self.callInvite = nil;
    */
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
    NSLog(@"provider:performEndCallAction:");
    /*
    [[VoiceClient sharedInstance] stopAudioDevice];
    
    if (self.callInvite && self.callInvite.state == TVOCallInviteStatePending) {
        [self.callInvite reject];
        self.callInvite = nil;
    } else if (self.call) {
        [self.call disconnect];
    }
    */
    [action fulfill];
}

#pragma mark - CallKit Actions
- (void)performStartCallActionWithUUID:(NSUUID *)uuid handle:(NSString *)handle {
    if (uuid == nil || handle == nil) {
        return;
    }
    
    CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:handle];
    CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:uuid handle:callHandle];
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:startCallAction];
    /*
    [self.callKitCallController requestTransaction:transaction completion:^(NSError *error) {
        if (error) {
            NSLog(@"StartCallAction transaction request failed: %@", [error localizedDescription]);
        } else {
            NSLog(@"StartCallAction transaction request successful");
            
            CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
            callUpdate.remoteHandle = callHandle;
            callUpdate.supportsDTMF = YES;
            callUpdate.supportsHolding = NO;
            callUpdate.supportsGrouping = NO;
            callUpdate.supportsUngrouping = NO;
            callUpdate.hasVideo = NO;
            
            [self.callKitProvider reportCallWithUUID:uuid updated:callUpdate];
        }
    }];*/
}

- (void)reportIncomingCallFrom:(NSString *) from withUUID:(NSUUID *)uuid {
    CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:from];
    
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    callUpdate.remoteHandle = callHandle;
    callUpdate.supportsDTMF = YES;
    callUpdate.supportsHolding = NO;
    callUpdate.supportsGrouping = NO;
    callUpdate.supportsUngrouping = NO;
    callUpdate.hasVideo = NO;
    /*
    [self.callKitProvider reportNewIncomingCallWithUUID:uuid update:callUpdate completion:^(NSError *error) {
        if (!error) {
            NSLog(@"Incoming call successfully reported.");
            
            // RCP: Workaround per https://forums.developer.apple.com/message/169511
            [[VoiceClient sharedInstance] configureAudioSession];
        }
        else {
            NSLog(@"Failed to report incoming call successfully: %@.", [error localizedDescription]);
        }
    }];*/
}

- (void)performEndCallActionWithUUID:(NSUUID *)uuid {
    if (uuid == nil) {
        return;
    }
    
    CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:uuid];
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:endCallAction];
    /*
    [self.callKitCallController requestTransaction:transaction completion:^(NSError *error) {
        if (error) {
            NSLog(@"EndCallAction transaction request failed: %@", [error localizedDescription]);
        }
        else {
            NSLog(@"EndCallAction transaction request successful");
        }
    }];*/
}



@end
