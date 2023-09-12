//
//  SpatialAudioEngine.swift
//  ClassifySound
//
//  Created by Jason on 2023/8/22.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import AVFoundation
import SoundAnalysis
import Combine

struct SoundInfo: Identifiable, Codable {
    var id: Int
    var soundSourceID: Int32
    var x: Float
    var y: Float
    var z: Float
}

class SpatialAudioEngine: NSObject {
    var audioController = GVRAudioEngine(renderingMode: kRenderingModeBinauralHighQuality)
    var soundSourceID : Int32 = 0
    
    var soundMap = [0: SoundInfo(id: 0, soundSourceID: 0, x: -1, y: 1, z: 0), 1: SoundInfo(id: 1, soundSourceID: 1, x: 3, y: 1, z: 0)]
    
    init(audioController: GVRAudioEngine = GVRAudioEngine(renderingMode: kRenderingModeBinauralHighQuality), soundSourceID : Int32 = 0) {
        self.audioController = audioController
        self.audioController?.preloadSoundFile(String("left.mp3"))
        soundMap[0]?.soundSourceID =  (self.audioController?.createSoundObject(String("left.mp3")))!
        self.audioController?.preloadSoundFile(String("right.mp3"))
        soundMap[1]?.soundSourceID =  (self.audioController?.createSoundObject(String("right.mp3")))!
    }
    
    func stop(){
        audioController?.stop()
    }
    
    func reloadSound() {
//        self.audioController?.stopSound(soundMap[0]!.soundSourceID)
//        self.audioController?.stopSound(soundMap[1]!.soundSourceID)
        soundMap[0]?.soundSourceID =  (self.audioController?.createSoundObject(String("left.mp3")))!
        soundMap[1]?.soundSourceID =  (self.audioController?.createSoundObject(String("right.mp3")))!
    }
    
    func soundPlay(_ soundSourceID: Int32, _ x: Float, _ y: Float, _ z: Float){
        audioController?.start()
        setAudioVolume(soundSourceID,volume: 0.8)
        print("now play: \(soundSourceID)")
        audioController?.enableRoom(false)
        setAudioPosition(soundSourceID, x, y, z)
        playAudio(soundSourceID)
        print("have sound: \(String(describing: audioController?.isSoundPlaying(soundSourceID)))")
        reloadSound()
    }
    
    func setAudioPosition(_ soundSource:Int32, _ x: Float, _ y: Float, _ z: Float) {
        audioController?.setSoundObjectPosition(
            soundSource,
            x: x,
            y: y,
            z: z)
        audioController?.update()
    }
    
    func setAudioVolume(_ soundSource:Int32, volume: Float) {
        audioController?.setSoundVolume(soundSource, volume: volume)
        audioController?.update()
    }
    
    func playAudio(_ soundSource:Int32) {
        print("Playing")
        audioController?.playSound(soundSource, loopingEnabled: false)
    }
    
    func pauseAudio(_ soundSource:Int32) {
        audioController?.pauseSound(soundSource)
    }
    
    func isPlaying() -> Bool {
        for i in 0...1 {
            if let boolValue = (audioController?.isSoundPlaying(soundMap[i]!.soundSourceID)) {
                print(soundMap[i]!.soundSourceID, boolValue)
                if(boolValue){
                    return true
                }
            }
        }
        return false
    }
}
