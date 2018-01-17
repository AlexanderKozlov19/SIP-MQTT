//
//  MQTT.h
//  SIP MQTT
//
//  Created by Alexander Kozlov on 14.11.2017.
//  Copyright © 2017 Alexander Kozlov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MQTTClient.h"
#import "ViewController.h"
//#import "MQTTSessionManager"

//@interface MQTTServiceMy : NSObject<MQTTSessionManagerDelegate>
@interface MQTTServiceMy : NSObject<MQTTSessionDelegate,MQTTTransportDelegate>

+(id)SharedCurrencyService;

//@property( strong, nonatomic) MQTTSessionManager* sessionMQQT;
@property( strong, nonatomic) MQTTSession* sessionMQQT;


@property (strong,nonatomic)    NSString* loginForHost;
@property (strong,nonatomic)    NSString* passwordForHost;

@property (strong,nonatomic)    NSString* certificateName;

-(void)connectToServer:(NSString*)address port:(int)portIn useTLS:(BOOL)useTLSIn;
-(void)addCerteficate:(NSString*)nameCertificate;

-(void)publishData:(NSString*)textData topic:(NSString*)topicIn retainedMsg:(BOOL)retained;
-(void)subscribeToTopic:(NSString*)topicName;
-(void)unsubscribeFromTopic:(NSString*)topicName;

-(void)disconnect;

@end
