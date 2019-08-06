//
//  GestureInfo.swift
//  DrawApp
//
//  Created by Bao Nguyen on 3/18/19.
//  Copyright © 2019 Bao Nguyen. All rights reserved.
// This file includes infomation of a drawing (gesture) include time and editor
//

import Foundation
import Firebase

class GestureInfo : Hashable {
    var id : String
    var time : Int
    var editor : String
    var ref : DatabaseReference?
    
    init(id: String, time : Int, editor : String) {
        self.id = id
        self.time = time
        self.editor = editor
        self.ref = nil
    }
    
    init(snapshot : DataSnapshot) {
        let snapshotValues = snapshot.value as! [String : AnyObject]
        self.time = snapshotValues["time"] as! Int
        self.editor = snapshotValues["editor"] as! String
        self.ref = snapshot.ref
        self.id = snapshot.key
    }
    
    
    func toAnyObject() -> Any {
        return [
            "time" : self.time,
            "editor" : self.editor,
            "gestures" : "null"
        ]
    }
    
    static func == (lhs: GestureInfo, rhs: GestureInfo) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
