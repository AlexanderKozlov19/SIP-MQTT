//
//  AudioPlaying.h
//  SIP MQTT
//
//  Created by Alexander Kozlov on 30.12.2017.
//  Copyright © 2017 Alexander Kozlov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AudioToolbox/AudioQueue.h>

#define NUM_BUFFERS_RECORD 3

typedef struct
{
    AudioStreamBasicDescription audioStreamBasicDecription;
    AudioQueueRef               queue;
    AudioQueueBufferRef         buffers[NUM_BUFFERS_RECORD];
    SInt64                      currentPacket;
    bool                        playing;
}PlayState;

@interface AudioPlaying : NSObject {
    PlayState playState;
    NSMutableArray *bufferArray;
}

+(id)SharedAudioPlaying;

-(void)startPlaying;
-(void)stopPlaying;
-(BOOL)isPlaying;

-(void)addBuffer:(NSData*)buffer;



@property (nonatomic) Boolean mIsDone;
@property (nonatomic) UInt32 playFormat;
@property (nonatomic) SInt64 currentPacket;

@end
