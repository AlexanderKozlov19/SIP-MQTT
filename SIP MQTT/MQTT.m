//
//  MQTT.m
//  SIP MQTT
//
//  Created by Alexander Kozlov on 14.11.2017.
//  Copyright © 2017 Alexander Kozlov. All rights reserved.
//


#import "MQTT.h"
#import "MQTTClient.h"
#import "ViewController.h"

@implementation MQTTServiceMy

@synthesize passwordForHost;
@synthesize loginForHost;
@synthesize sessionMQQT;
@synthesize certificateName;

//---- создаем синглтон
+ (id)SharedCurrencyService {
    static MQTTServiceMy *sharedCurrencyService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCurrencyService = [[self alloc] init];
        sharedCurrencyService.sessionMQQT = [[MQTTSession alloc] init];
        //sharedCurrencyService.sessionMQQT.delegate = self;
      
    });
    return sharedCurrencyService;
    
    
}

-(void)connectToServer:(NSString*)address port:(int)portIn useTLS:(BOOL)useTLSIn {
  
  // self.sessionMQQT = [[MQTTSession alloc] init];
    
    self.sessionMQQT.delegate = self;
  
   /* self.sessionMQQT.subscriptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:MQTTQosLevelExactlyOnce]
                                                                forKey:@"topic/state"];
    
    [self.sessionMQQT connectTo:address port:portIn tls:useTLSIn keepalive:600 clean:true auth:(self.passwordForHost != nil && self.loginForHost != nil) user:self.loginForHost pass:self.passwordForHost willTopic:@"topic/state" will:[@"offline" dataUsingEncoding:NSUTF8StringEncoding] willQos:MQTTQosLevelExactlyOnce willRetainFlag:FALSE withClientId:nil ];
    */
    if ( useTLSIn ) {
        MQTTSSLSecurityPolicyTransport *transport = [[MQTTSSLSecurityPolicyTransport alloc] init];
        /*transport.securityPolicy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
        transport.securityPolicy.pinnedCertificates = @[ [NSData dataWithContentsOfFile:self.certificateName] ];
        */
        transport.securityPolicy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeNone];
        transport.securityPolicy.pinnedCertificates = @[ [NSData dataWithContentsOfFile:self.certificateName] ];
        
      //  transport.certificates = @[ [NSData dataWithContentsOfFile:self.certificateName] ];
        
        transport.securityPolicy.allowInvalidCertificates = YES;
        
        //     self.sessionMQQT.securityPolicy.allowInvalidCertificates = YES;
        transport.host = address;
        transport.port = portIn;
        transport.tls = YES;
        
        self.sessionMQQT.transport = transport;
       // self.sessionMQQT.certificates =@[ [NSData dataWithContentsOfFile:self.certificateName] ];
    }
    else {
        MQTTCFSocketTransport *transport = [[MQTTCFSocketTransport alloc] init];
        transport.host = address;
        transport.port = portIn;
    
        self.sessionMQQT.transport = transport;
    }
    
    self.sessionMQQT.transport.delegate = self;
    //session.keepAliveInterval = 30;
    self.sessionMQQT.cleanSessionFlag = YES;
    
    
    [self.sessionMQQT connect];
    
   // self.sessionMQQT.userName = self.loginForHost;
   // self.sessionMQQT.password = self.passwordForHost;
    
    //[self.sessionMQQT connectToHost:address port:portIn usingSSL:useTLSIn];

}

-(void)publishData:(NSString*)textData topic:(NSString*)topicIn retainedMsg:(BOOL)retained {
    if ( self.sessionMQQT != nil )
        [self.sessionMQQT publishAndWaitData:[textData dataUsingEncoding:NSUTF8StringEncoding] onTopic:topicIn retain:retained qos:0];
      //  [self.sessionMQQT publishAndWaitData:[textData dataUsingEncoding:NSUTF8StringEncoding] topic:topicIn  retain:retained qos:1];//qos:MQTTQosLevelExactlyOnce retain:retained];
        //[session publishData:[@"Sample Data" dataUsingEncoding:NSUTF8StringEncoding]
        //               topic:@"example/data"
         //             retain:NO
         //                qos:MQTTQosLevelAtMostOnce];

        
}

-(void)subscribeToTopic:(NSString*)topicName {
    
    if ( self.sessionMQQT != nil )
        [self.sessionMQQT subscribeToTopic:topicName atLevel:MQTTQosLevelExactlyOnce];
       // [self.sessionMQQT.subscriptions setObject:[NSNumber numberWithInt:MQTTQosLevelExactlyOnce]
       //                                   forKey:topicName];
//[self.sessionMQQT subscribeToTopic:topicName atLevel:MQTTQosLevelExactlyOnce];
    
}

-(void)unsubscribeFromTopic:(NSString*)topicName {
    if ( self.sessionMQQT != nil )
        [self.sessionMQQT unsubscribeTopic:topicName];
       // [self.sessionMQQT.subscriptions removeObjectForKey:[NSString stringWithFormat:topicName]];
//[self.sessionMQQT unsubscribeTopic:topicName];
}

-(void)disconnect {
      if ( self.sessionMQQT != nil )
          [self.sessionMQQT close];
}

- (void)newMessage:(MQTTSession *)session
              data:(NSData *)data
           onTopic:(NSString *)topic
               qos:(MQTTQosLevel)qos
          retained:(BOOL)retained
               mid:(unsigned int)mid {
    NSMutableString *dataString = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [dataString insertString:@":" atIndex:0];
    [dataString insertString:topic atIndex:0];
    [dataString appendString:@"\n"];
    NSDictionary *dictError = [NSDictionary dictionaryWithObject:dataString forKey:@"data"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"addTopicMessage" object:nil userInfo:dictError];
    // this is one of the delegate callbacks
}

- (void)handleEvent:(MQTTSession *)session
              event:(MQTTSessionEvent)eventCode
              error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *stringText = [[NSString alloc]init];
        switch ( eventCode )
        {
            case MQTTSessionEventConnected: stringText = @"connected"; break;
            case MQTTSessionEventConnectionRefused: stringText =@"connection refused"; break;
            case MQTTSessionEventConnectionClosed: stringText = @"connection closed"; break;
            case MQTTSessionEventConnectionError: stringText = @"connection error"; break;
            case MQTTSessionEventProtocolError: stringText = @"protocol error"; break;
            case MQTTSessionEventConnectionClosedByBroker: stringText = @"closed by broker";break;
            default: stringText = @"unknown";
        }
        NSDictionary *dictError = [NSDictionary dictionaryWithObject:stringText forKey:@"status"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateLabelStatus" object:nil userInfo:dictError];
    });
    NSLog(@"event %d", eventCode);
}


- (void)mqttTransport:(nonnull id<MQTTTransport>)mqttTransport didReceiveMessage:(nonnull NSData *)message {
   NSString *dataString = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
}

-(void)addCerteficate:(NSString*)nameCertificate {
    self.certificateName = nameCertificate;
    if ( self.sessionMQQT != nil ) {
        //self.sessionMQQT.
       // self.sessionMQQT = [MQTTSSLSecurityPolicy //policyWithPinningMode:MQTTSSLPinningModeCertificate];
   //     self.sessionMQQT.securityPolicy.pinnedCertificates = @[ [NSData dataWithContentsOfFile:nameCertificate] ];
        
   //     self.sessionMQQT.securityPolicy.allowInvalidCertificates = YES;
    }
    
}

/*
- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained {

    
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // NSString *senderString = [topic substringFromIndex:self.base.length + 1];
    
    //[self.chat insertObject:[NSString stringWithFormat:@"%@:\n%@", senderString, dataString] atIndex:0];
    //[self.tableView reloadData];
}*/
@end
