//
//  FirebaseManager.swift
//  SoundNavigation
//
//  Created by Jason on 2023/9/12.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct DetectionCell: Identifiable, Codable {
    var id: Int
    var state: Bool
    var number: Int
}

class FirebaseManager: ObservableObject {
    static let databasePath: DatabaseReference = Database.database().reference()
    
    func observeDetectionChanges(audioEngine: SpatialAudioEngine) {
        FirebaseManager.databasePath.child("Detection").observe(.value, with: { snapshot in
            if let data = snapshot.value as? [String: Any] {
                if let boolValue = data["state"] as? Bool {
                    if(boolValue){
                        print(true)
                        SoundNavigationApp.playingAvailable = true
                    } else{
                        if(SoundNavigationApp.playingAvailable){
                            let soundInfo = audioEngine.soundMap[Int.random(in: 0...1)]!
                            audioEngine.soundPlay(soundInfo.soundSourceID, soundInfo.x, soundInfo.y, soundInfo.z)
                        }
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
        let temp = try? JSONEncoder().encode(DetectionCell(id: 0, state: state, number: soundNum))
        let json = try? JSONSerialization.jsonObject(with: temp!)
        FirebaseManager.databasePath.child("Detection").setValue(json)
//        updateRealmData(updateID: 0, data: json as Any)
        print("---Updated---", state)
    }
    
    func deleteAllData() {
        FirebaseManager.databasePath.removeValue()
    }
}
