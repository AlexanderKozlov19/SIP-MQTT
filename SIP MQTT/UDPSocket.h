//
//  UDPSocket.h
//  SIP MQTT
//
//  Created by Alexander Kozlov on 21.12.2017.
//  Copyright © 2017 Alexander Kozlov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"


@interface UDPSocket : NSObject<GCDAsyncUdpSocketDelegate>

+(id)SharedUDPSocket;

@property (nonatomic) int udpPortNumber;

@property (nonatomic) int udpPortToNumber;
@property (nonatomic) NSString* udpIPTo;

-(BOOL)initUDPSocket;

-(int)askForBindedPort;
-(void)sendText:(NSString*)string toIP:(NSString*)ipTo toPort:(int)portTo;
-(void)sendData:(float*)data dataSize:(UInt32)size toIP:(NSString*)ipTo toPort:(int)portTo;
-(void)sendData:(float*)data dataSize:(UInt32)size;

-(bool)isBinded;



@end
