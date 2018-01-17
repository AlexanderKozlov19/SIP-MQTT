//
//  SIPpj.h
//  SIP MQTT
//
//  Created by Alexander Kozlov on 16.11.2017.
//  Copyright © 2017 Alexander Kozlov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SIPpj : NSObject

+(id)SharedCurrencyService;
@property( strong, nonatomic) SIPpj* sessionSIP;

-(void)startSIP:(NSString*)stringUser domain:(NSString*)stringDomain useServer:(BOOL)bUseServer srvSTUN:(NSString*)stunServer useSTUN:(BOOL)bUseSTUN;
-(void)stopSIP;
-(void)answerCall;
-(void)hangUpCall;
-(void)makeCall:(NSString*)callTo;

@end
