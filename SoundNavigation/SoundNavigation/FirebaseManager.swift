//
//  FirebaseManager.swift
//  SoundNavigation
//
//  Created by Jason on 2023/9/12.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import SwiftUI
import FirebaseDatabase

struct DetectionCell: Identifiable, Codable {
    var id: Int
    var state: Bool
    var number: Int
    var sources: [String]
}

class FirebaseManager: ObservableObject {
    static let databasePath: DatabaseReference = Database.database().reference()
    
    func observeDetectionChanges(audioEngine: SpatialAudioEngine, soundList: Binding<[String]>, message: Binding<String>, currentID: Binding<Int>) {
        FirebaseManager.databasePath.child("Detection").observe(.value, with: { snapshot in
            if let data = snapshot.value as? [String: Any] {
                if let boolValue = data["state"] as? Bool {
                    if(boolValue){
                        print(true)
                        SoundNavigationApp.playingAvailable = true
                        soundList.wrappedValue = data["sources"] as! [String]
                        if(soundList.wrappedValue.contains("speech")) {
                            SoundNavigationApp.someoneSpeeching = true
                        }
                        print(soundList.wrappedValue)
                    } else{
                        if(SoundNavigationApp.playingAvailable){
                            var index: Int
//                            if(currentID.wrappedValue == -1){
//                                index = Int.random(in: 1...1)
//                                message.wrappedValue = audioEngine.soundMap[index]!.message
//                            }
                            if(currentID.wrappedValue != -1) {
//                            else{
//                                index = currentID.wrappedValue
//                                audioEngine.currentID = -1
//                                currentID.wrappedValue = -1
//                            }
                                index = currentID.wrappedValue
                                audioEngine.currentID = -1
                                currentID.wrappedValue = -1
                                let soundInfo = audioEngine.soundMap[index]!
                                audioEngine.soundPlay(soundInfo.soundSourceID, soundInfo.x, soundInfo.y, soundInfo.z)
                                SoundNavigationApp.isPlaying = true
                                SoundNavigationApp.someoneSpeeching = false
                                
                                let varTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false)
                                { (varTimer) in
                                    message.wrappedValue = ""
                                    SoundNavigationApp.isPlaying = false
                                    print("---------------Speech-----------:  " + String(SoundNavigationApp.someoneSpeeching))
                                    if(SoundNavigationApp.someoneSpeeching) {
                                        audioEngine.soundPlay(audioEngine.speechSourceID, 1, 1, 0)
                                    }
                                    SoundNavigationApp.someoneSpeeching = false
                                }
                            }
                        }
                        soundList.wrappedValue = []
                        SoundNavigationApp.playingAvailable = false;
                    }
                }
            }
        })
    }
    
    func updateRealmData(updateID: Int, data: Any) {
        FirebaseManager.databasePath.queryOrdered(byChild: "id")
                                  .queryEqual(toValue: updateID)
                                  .observeSingleEvent(of: .value, with: { snapshot in
                                      if(snapshot.value! is NSNull) {
                                          FirebaseManager.databasePath.childByAutoId().setValue(data)
                                      }
                                      else {
                                          let childSnapshot = snapshot.children.allObjects.first as? DataSnapshot
                                          FirebaseManager.databasePath.child(childSnapshot!.key).setValue(data)
                                      }
                                  })
    }
    
    func sendData(state: Bool, soundNum: Int) {
        let temp = try? JSONEncoder().encode(DetectionCell(id: 0, state: state, number: soundNum, sources: []))
        let json = try? JSONSerialization.jsonObject(with: temp!)
        FirebaseManager.databasePath.child("Detection").setValue(json)
//        updateRealmData(updateID: 0, data: json as Any)
        print("---Updated---", state)
    }
    
    func deleteAllData() {
        FirebaseManager.databasePath.removeValue()
    }
}
