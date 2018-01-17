//
//  AudioRecording.h
//  SIP MQTT
//
//  Created by Alexander Kozlov on 26.12.2017.
//  Copyright © 2017 Alexander Kozlov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AudioToolbox/AudioQueue.h>

#define NUM_BUFFERS 1

typedef struct
{
    AudioStreamBasicDescription audioStreamBasicDecription;
    AudioQueueRef               queue;
    AudioQueueBufferRef         buffers[NUM_BUFFERS];
    SInt64                      currentPacket;
    bool                        recording;
}RecordState;

@interface AudioRecording : NSObject {
    RecordState recordState;
}

+(id)SharedAudioRecord;

-(void)startRecord;
-(void)stopRecord;
-(BOOL)isRecording;

@property (nonatomic) UInt32 recordFormat;


@end
