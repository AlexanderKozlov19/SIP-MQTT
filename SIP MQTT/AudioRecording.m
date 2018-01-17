//
//  AudioRecording.m
//  SIP MQTT
//
//  Created by Alexander Kozlov on 26.12.2017.
//  Copyright © 2017 Alexander Kozlov. All rights reserved.
//

#import "AudioRecording.h"
#import "UDPSocket.h"


@implementation AudioRecording

int _recordFormat;

+(id)SharedAudioRecord {
    static AudioRecording *sharedAudioRecord = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAudioRecord = [[self alloc] init];
        sharedAudioRecord.recordFormat = kAudioFormatLinearPCM;
        sharedAudioRecord->recordState.recording = NO;
        
        
        
    });
    return sharedAudioRecord;
}

-(void)setupRecord {
    memset(&recordState.audioStreamBasicDecription, 0, sizeof( recordState.audioStreamBasicDecription));
    recordState.audioStreamBasicDecription.mFormatID = self.recordFormat;
    if ( recordState.audioStreamBasicDecription.mFormatID == kAudioFormatLinearPCM ) {
        
        recordState.audioStreamBasicDecription.mSampleRate = 44100;
        recordState.audioStreamBasicDecription.mChannelsPerFrame = 1;
        recordState.audioStreamBasicDecription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        recordState.audioStreamBasicDecription.mBitsPerChannel = 16;
        recordState.audioStreamBasicDecription.mBytesPerPacket = recordState.audioStreamBasicDecription.mBytesPerFrame = (recordState.audioStreamBasicDecription.mBitsPerChannel / 8) * recordState.audioStreamBasicDecription.mChannelsPerFrame;
        recordState.audioStreamBasicDecription.mFramesPerPacket = 1;
    }
    
}

void audioInputCallback(void * inUserData,  // Custom audio metadata
                        AudioQueueRef inAQ,
                        AudioQueueBufferRef inBuffer,
                        const AudioTimeStamp * inStartTime,
                        UInt32 inNumberPacketDescriptions,
                        const AudioStreamPacketDescription * inPacketDescs) {
    
    RecordState * recordState = (RecordState*)inUserData;
    
    if ( [[UDPSocket SharedUDPSocket] isBinded] == YES) {
        int sampleCount = inBuffer->mAudioDataBytesCapacity / sizeof(float);
        float *samples = (float*)inBuffer->mAudioData;
        
        [[UDPSocket SharedUDPSocket] sendData:samples dataSize:sampleCount];
        
    }
    
    AudioQueueEnqueueBuffer(recordState->queue, inBuffer, 0, NULL);
    
}

-(void)startRecord {
    [self setupRecord];
    
    recordState.currentPacket = 0;
    
    OSStatus status;
    status = AudioQueueNewInput(&recordState.audioStreamBasicDecription,
                                audioInputCallback,
                                &recordState,
                                CFRunLoopGetCurrent(),
                                kCFRunLoopCommonModes,
                                0,
                                &recordState.queue);
    
  
    
    if (status == 0) {
        
        for (int i = 0; i < NUM_BUFFERS; i++) {
            AudioQueueAllocateBuffer(recordState.queue, 1024, &recordState.buffers[i]);
            AudioQueueEnqueueBuffer(recordState.queue, recordState.buffers[i], 0, nil);
        }
        
        recordState.recording = true;
        
        status = AudioQueueStart(recordState.queue, NULL);
    }

}

-(void)setRecordFormat:(UInt32)inRecordFormat{
    _recordFormat = inRecordFormat;
    
}

-(UInt32)getRecordFormat{
    return _recordFormat;
    
}

- (void)stopRecord{
    recordState.recording = false;
    
    AudioQueueStop(recordState.queue, true);

    for (int i = 0; i < NUM_BUFFERS; i++) {
        AudioQueueFreeBuffer(recordState.queue, recordState.buffers[i]);
    }
    
    AudioQueueDispose(recordState.queue, true);
   
}

-(BOOL)isRecording {
    return self->recordState.recording;
}

@end
