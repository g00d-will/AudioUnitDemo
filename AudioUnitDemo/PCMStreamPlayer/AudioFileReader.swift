//
//  AudioFileReader.swift
//  AudioUnitDemo
//
//  Created by Will on 2024/8/28.
//

import Foundation

class AudioFileReader {
    private var filePaths: [String]
    private var currentFileIndex: Int = 0
    private var currentFileHandle: FileHandle?

    init(filePaths: [String]) {
        self.filePaths = filePaths
        openNextFile()
    }

    private func openNextFile() {
        currentFileHandle?.closeFile()
        
        if currentFileIndex < filePaths.count {
            currentFileHandle = FileHandle(forReadingAtPath: filePaths[currentFileIndex])
            currentFileIndex += 1
        } else {
            currentFileHandle = nil
        }
    }

    func readNextBuffer() -> Data? {
        guard let handle = currentFileHandle else {
            return nil
        }

        let data = handle.readData(ofLength: 1024)
        
        if data.isEmpty {
            openNextFile()
            return readNextBuffer()
        }

        return data
    }

    func reset() {
        currentFileIndex = 0
        openNextFile()
    }
}
