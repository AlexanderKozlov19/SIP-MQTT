//
//  UDPSocket.m
//  SIP MQTT
//
//  Created by Alexander Kozlov on 21.12.2017.
//  Copyright © 2017 Alexander Kozlov. All rights reserved.
//

#import "UDPSocket.h"
#import "AudioPlaying.h"


@interface UDPSocket()
@property (nonatomic, strong) GCDAsyncUdpSocket *socket;
@end



@implementation UDPSocket

int _udpPortNumber;
BOOL _binded;
int udpPortToNumber;
@synthesize udpIPTo;

 NSString * const udpID = @"UPDS";


//---- создаем(nonatomic)  синглтон
+ (id)SharedUDPSocket {
    static UDPSocket *sharedUDPSocket = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedUDPSocket = [[self alloc] init];
        sharedUDPSocket.socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:sharedUDPSocket delegateQueue:dispatch_get_main_queue()];
        sharedUDPSocket.udpPortNumber = 0;
        _binded = NO;
        sharedUDPSocket.udpIPTo = [[NSString alloc] init];

        
    });
    return sharedUDPSocket;
    
}

-(void)setUdpPortNumber:(int)udpPortNumber {
    _udpPortNumber = udpPortNumber;
   
}

-(BOOL)initUDPSocket {
    BOOL bResult = YES;
    
    NSError *error=nil;
    if (![self.socket bindToPort:_udpPortNumber error:&error])
    {
        NSLog(@"Error binding: %@", error);
        return NO;
    }
    if (![self.socket beginReceiving:&error])
    {
        NSLog(@"Error receiving: %@", error);
        return NO;
    }
    
    _binded = YES;
    return bResult;
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext{
    
    NSString *hostFrom = [GCDAsyncUdpSocket hostFromAddress:address];
    int portFrom = [GCDAsyncUdpSocket portFromAddress:address];
    
    bool bData = NO;
        
    if ( data.length > [udpID length]) {
        unsigned char arBytes[4];
        [data getBytes:&arBytes range:NSMakeRange(0, 4)];
        NSData *dataHeader = [NSData dataWithBytes:&arBytes length:4];
        
         NSString *header= [[NSString alloc]initWithData:dataHeader encoding:NSUTF8StringEncoding];
        
        if ( [header isEqualToString:udpID] ) {
            bData = YES;
            
        }
        
        
    }
    
    
    if ( bData ) {
        [[AudioPlaying SharedAudioPlaying] addBuffer:[ data subdataWithRange:NSMakeRange(4,[data length] - 4) ]];
        return;
    }
    
        
    
    NSString *addressString = [[NSString alloc] initWithFormat:@"%@ : %d", hostFrom, portFrom ];
    
    NSLog(@"Socket receiving data");
    NSString *receiveString= [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Remote Message:%@",receiveString);
     NSLog(@"Remote Message From:%@",addressString);
    
    NSDictionary *dictInfo = [NSDictionary dictionaryWithObjects:@[hostFrom, [NSNumber numberWithInt:portFrom], receiveString] forKeys:@[@"hostFrom", @"postFrom", @"message"]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"onUDPMessage" object:nil userInfo:dictInfo];
    
    if ( [receiveString isEqualToString:@"STOPP"] ) {
        [[AudioPlaying SharedAudioPlaying] stopPlaying];
    }
    
    if ( [receiveString isEqualToString:@"STARTT"] ) {
        [[AudioPlaying SharedAudioPlaying] startPlaying];
    }
    
    
}

-(int)askForBindedPort {
    return self.socket.localPort;
}

-(void)sendText:(NSString*)string toIP:(NSString*)ipTo toPort:(int)portTo {
    NSData *nsData = [string dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket sendData:nsData toHost:ipTo port:portTo withTimeout:-1 tag: 1 ];
}

-(bool)isBinded {
    return _binded;
}

-(void)sendData:(float*)data dataSize:(UInt32)size toIP:(NSString*)ipTo toPort:(int)portTo {
   
    NSMutableData *nsHeader = [[NSMutableData alloc] init];
    [nsHeader appendData:[udpID dataUsingEncoding:NSUTF8StringEncoding]];
    [nsHeader appendData:[NSData dataWithBytes:&size length:sizeof(UInt32)]];
    [nsHeader appendData:[NSData dataWithBytes:data length:size * sizeof( float )]];
    
    [self.socket sendData:[NSData dataWithData:nsHeader] toHost:ipTo port:portTo withTimeout:-1 tag: 1 ];
    
}

-(void)sendData:(float*)data dataSize:(UInt32)size  {
    [self sendData:data dataSize:size toIP:self.udpIPTo toPort:self.udpPortToNumber ];
}


@end
