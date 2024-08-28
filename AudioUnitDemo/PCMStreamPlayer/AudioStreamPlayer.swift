//
//  AudioStreamPlayer.swift
//  AudioUnitDemo
//
//  Created by Will on 2024/8/28.
//

import Foundation
import AVFoundation

class AudioStreamPlayer {
    private var audioUnitManager: AudioUnitManager
    private var audioFileReader: AudioFileReader
    private var isPlaying = false

    init(filePaths: [String]) {
        audioFileReader = AudioFileReader(filePaths: filePaths)
        audioUnitManager = AudioUnitManager(reader: audioFileReader)
    }

    func play() {
        if !isPlaying {
            audioUnitManager.start()
            isPlaying = true
        }
    }

    func pause() {
        if isPlaying {
            audioUnitManager.stop()
            isPlaying = false
        }
    }
    
    func stop() {
        if isPlaying {
            audioUnitManager.stop()
            isPlaying = false
            audioFileReader.reset() // 重置读取器，释放资源
        }
    }

    func resume() {
        if !isPlaying {
            audioUnitManager.start()
            isPlaying = true
        }
    }

    func replay() {
        audioFileReader.reset()
        play()
    }
}
