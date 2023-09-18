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
    var sources: [String]
}

class FirebaseManager: ObservableObject {
    static let databasePath: DatabaseReference = Database.database().reference()
    
    static var detectionCell:DetectionCell = DetectionCell(id:0, state:false, number:0, sources:[])
    
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
    
    func sendData(state: Bool, soundNum: Int, sources: [String]) {
        let temp = try? JSONEncoder().encode(DetectionCell(id: 0, state: state, number: soundNum, sources: sources))
        let json = try? JSONSerialization.jsonObject(with: temp!)
        FirebaseManager.databasePath.child("Detection").setValue(json)
//        updateRealmData(updateID: 0, data: json as Any)
    }
    
    func deleteAllData() {
        FirebaseManager.databasePath.removeValue()
    }
}
