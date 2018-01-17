//
//  AudioPlaying.m
//  SIP MQTT
//
//  Created by Alexander Kozlov on 30.12.2017.
//  Copyright © 2017 Alexander Kozlov. All rights reserved.
//

#import "AudioPlaying.h"

@implementation AudioPlaying

AudioQueueRef                    mQueue;
AudioQueueBufferRef              mBuffers[NUM_BUFFERS_RECORD];


int _playFormat;

+(id)SharedAudioPlaying {
    static AudioPlaying *sharedAudioPlaying= nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAudioPlaying = [[self alloc] init];
        sharedAudioPlaying->bufferArray = [[NSMutableArray alloc] init];
        sharedAudioPlaying.playFormat = kAudioFormatLinearPCM;
        sharedAudioPlaying->playState.playing = NO;
        
        
        
    });
    return sharedAudioPlaying;
}

-(void)setupPlaying{
    memset(&playState.audioStreamBasicDecription, 0, sizeof( playState.audioStreamBasicDecription));
    playState.audioStreamBasicDecription.mFormatID = self.playFormat;
    if ( playState.audioStreamBasicDecription.mFormatID == kAudioFormatLinearPCM ) {
        
        playState.audioStreamBasicDecription.mSampleRate = 44100;
        playState.audioStreamBasicDecription.mChannelsPerFrame = 1;
        playState.audioStreamBasicDecription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        playState.audioStreamBasicDecription.mBitsPerChannel = 16;
        playState.audioStreamBasicDecription.mBytesPerPacket = playState.audioStreamBasicDecription.mBytesPerFrame = (playState.audioStreamBasicDecription.mBitsPerChannel / 8) * playState.audioStreamBasicDecription.mChannelsPerFrame;
        playState.audioStreamBasicDecription.mFramesPerPacket = 1;
    }
    
}

void AQBufferCallback(void * inUserData, AudioQueueRef inAQ, AudioQueueBufferRef        inCompleteAQBuffer)
{
    AudioPlaying *THIS = (__bridge AudioPlaying*)inUserData;
    
    if (![THIS isPlaying]) return;
    
    

    
    inCompleteAQBuffer->mAudioDataByteSize = 1024;//numBytes;
    inCompleteAQBuffer->mPacketDescriptionCount = 1;//nPackets;
    
    if ( [THIS->bufferArray count] > 1 ) {
        dispatch_async(dispatch_get_main_queue(), ^{
        NSData *data = THIS->bufferArray[0];
            int iLen = [data length];
        [data getBytes:inCompleteAQBuffer->mAudioData range:NSMakeRange(4, [data length] - 4)];
            
            int iData2 = [THIS->bufferArray count];
        [THIS->bufferArray removeObjectAtIndex:0];
        }
                       );
        
    }
    
    
    AudioQueueEnqueueBuffer(inAQ, inCompleteAQBuffer, 0, NULL);
        //THIS->mCurrentPacket = (THIS->GetCurrentPacket() + nPackets);
    
    /*
    else
    {
        if (THIS->IsLooping())
        {
            THIS->mCurrentPacket = 0;
            AQBufferCallback(inUserData, inAQ, inCompleteAQBuffer);
        }
        else
        {
            // stop
            THIS->mIsDone = true;
            AudioQueueStop(inAQ, false);
        }
    }*/
}

-(void)setupNewQueue {
    
    AudioQueueNewOutput(&playState.audioStreamBasicDecription, &AQBufferCallback, (__bridge void *)(self), CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &mQueue);
    UInt32 bufferByteSize;
    // we need to calculate how many packets we read at a time, and how big a buffer we need
    // we base this on the size of the packets in the file and an approximate duration for each buffer
    // first check to see what the max size of a packet is - if it is bigger
    // than our allocation default size, that needs to become larger
    UInt32 maxPacketSize;
    UInt32 size = sizeof(maxPacketSize);
    
    // adjust buffer size to represent about a half second of audio based on this format
    
    bufferByteSize = 1024;
    //CalculateBytesForTime (playState.audioStreamBasicDecription, maxPacketSize, kBufferDurationSeconds, &bufferByteSize, &mNumPacketsToRead);
    
    //printf ("Buffer Byte Size: %d, Num Packets to Read: %d\n", (int)bufferByteSize, (int)mNumPacketsToRead);
    
    // (2) If the file has a cookie, we should get it and set it on the AQ
    /*size = sizeof(UInt32);
    OSStatus result = AudioFileGetPropertyInfo (mAudioFile, kAudioFilePropertyMagicCookieData, &size, NULL);
    
    if (!result && size) {
        char* cookie = new char [size];
        XThrowIfError (AudioFileGetProperty (mAudioFile, kAudioFilePropertyMagicCookieData, &size, cookie), "get cookie from file");
        XThrowIfError (AudioQueueSetProperty(mQueue, kAudioQueueProperty_MagicCookie, cookie, size), "set cookie on queue");
        delete [] cookie;
    }
    
    // channel layout?
    result = AudioFileGetPropertyInfo(mAudioFile, kAudioFilePropertyChannelLayout, &size, NULL);
    if (result == noErr && size > 0) {
        AudioChannelLayout *acl = (AudioChannelLayout *)malloc(size);
        
        result = AudioFileGetProperty(mAudioFile, kAudioFilePropertyChannelLayout, &size, acl);
        if (result) { free(acl); XThrowIfError(result, "get audio file's channel layout"); }
        
        result = AudioQueueSetProperty(mQueue, kAudioQueueProperty_ChannelLayout, acl, size);
        if (result){ free(acl); XThrowIfError(result, "set channel layout on queue"); }
        
        free(acl);
    }
    
    XThrowIfError(AudioQueueAddPropertyListener(mQueue, kAudioQueueProperty_IsRunning, isRunningProc, this), "adding property listener");
    
    bool isFormatVBR = (mDataFormat.mBytesPerPacket == 0 || mDataFormat.mFramesPerPacket == 0);
     */
    
    
    
    for (int i = 0; i < NUM_BUFFERS_RECORD; ++i) {
        AudioQueueAllocateBufferWithPacketDescriptions(mQueue, bufferByteSize, 0, &mBuffers[i]);
    }
    
    // set the volume of the queue
   // XThrowIfError (AudioQueueSetParameter(mQueue, kAudioQueueParam_Volume, 1.0), "set queue volume");
    
   // mIsInitialized = true;
}

-(void)startPlaying {
    
    [self setupPlaying];
    [self setupNewQueue];
    
    self.mIsDone = false;
    self->playState.playing = true;
    
    self.currentPacket = 0;
    
    for (int i = 0; i < NUM_BUFFERS_RECORD; ++i) {
        AQBufferCallback ((__bridge void *)(self), mQueue, mBuffers[i]);
    }
    
    AudioQueueStart(mQueue, NULL);
    
}

-(void)stopPlaying {
    
    AudioQueueStop(mQueue, true);
    self->playState.playing = false;

}

-(BOOL)isPlaying {
    return self->playState.playing;
    
}

-(void)setPlayFormat:(UInt32)inPlayFormat{
    _playFormat = inPlayFormat;
    
}

-(UInt32)getPlayFormat{
    return _playFormat;
    
}

-(void)addBuffer:(NSData*)buffer {
    dispatch_async( dispatch_get_main_queue(), ^ {
    
    
    [bufferArray addObject:buffer];

    });
    

    
}
@end
