//
//  AudioUnitManager.swift
//  AudioUnitDemo
//
//  Created by Will on 2024/8/28.
//

import Foundation
import AudioToolbox

class AudioUnitManager {
    private var reader: AudioFileReader
    private var audioUnit: AudioComponentInstance?

    init(reader: AudioFileReader) {
        self.reader = reader
        setupAudioUnit()
    }

    private func setupAudioUnit() {
        var desc = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_RemoteIO,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )

        let component = AudioComponentFindNext(nil, &desc)
        AudioComponentInstanceNew(component!, &audioUnit)

        var callbackStruct = AURenderCallbackStruct(
            inputProc: renderCallback,
            inputProcRefCon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )

        AudioUnitSetProperty(
            audioUnit!,
            kAudioUnitProperty_SetRenderCallback,
            kAudioUnitScope_Input,
            0,
            &callbackStruct,
            UInt32(MemoryLayout<AURenderCallbackStruct>.size)
        )

        // 锁定设备采样率为 16000 Hz
        var audioFormat = AudioStreamBasicDescription(
            mSampleRate: 16000, // 与文件的采样率匹配
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
            mBytesPerPacket: 2,  // 每个包的字节数 (对于16-bit PCM，单声道，每帧2字节)
            mFramesPerPacket: 1,
            mBytesPerFrame: 2,  // 每帧的字节数
            mChannelsPerFrame: 1,  // 单声道
            mBitsPerChannel: 16,  // 每个通道的位深度
            mReserved: 0
        )

        AudioUnitSetProperty(
            audioUnit!,
            kAudioUnitProperty_StreamFormat,
            kAudioUnitScope_Input,
            0,
            &audioFormat,
            UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        )

        AudioUnitInitialize(audioUnit!)
    }

    func start() {
        AudioOutputUnitStart(audioUnit!)
    }

    func stop() {
        AudioOutputUnitStop(audioUnit!)
    }

    private let renderCallback: AURenderCallback = { (
        inRefCon,
        ioActionFlags,
        inTimeStamp,
        inBusNumber,
        inNumberFrames,
        ioData
    ) -> OSStatus in
        let manager = Unmanaged<AudioUnitManager>.fromOpaque(inRefCon).takeUnretainedValue()
        
        guard let ioData = ioData else {
            return noErr
        }

        guard let bufferData = manager.reader.readNextBuffer(), !bufferData.isEmpty else {
            return noErr
        }
        
        let audioBuffer = ioData.pointee.mBuffers
        memcpy(audioBuffer.mData, (bufferData as NSData).bytes, min(bufferData.count, Int(audioBuffer.mDataByteSize)))
        
        return noErr
    }
}
