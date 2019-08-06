//
//  CanvasDetail.swift
//  DrawApp
//
//  Created by Bao Nguyen on 2/12/19.
//  Copyright © 2019 Bao Nguyen. All rights reserved.
//

import Foundation
import Firebase

class CanvasDetail {
    var id : String?
    var backgroundUrl : String
    var imagePath : String
    var roomkey : String
    var dateCreated : String
    var lastEdited : String
    var title : String
    let ref : DatabaseReference?
    
    
    init(backgroundUrl : String, imagePath : String, roomkey : String, dateCreated : String, lastEdited : String, title : String) {
        self.backgroundUrl = backgroundUrl
        self.imagePath = imagePath
        self.roomkey = roomkey
        self.dateCreated = dateCreated
        self.lastEdited = lastEdited
        self.title = title
        self.ref = nil
    }
    
    init(snapshot : DataSnapshot) {
        let snapshotValues = snapshot.value as! [String : AnyObject]
        self.id = snapshot.key
        self.backgroundUrl = snapshotValues["backgroundUrl"] as! String
        self.imagePath = snapshotValues["imagePath"] as! String
        self.roomkey = snapshotValues["roomkey"] as! String
        self.title = snapshotValues["title"] as! String
        self.dateCreated = snapshotValues["dateCreated"] as! String
        self.lastEdited = snapshotValues["lastEdited"] as! String
        self.ref = snapshot.ref
    }
    
    func toAnyObject() -> Any {
        return [
            "backgroundUrl" : backgroundUrl,
            "imagePath" : imagePath,
            "roomkey" : roomkey,
            "title": title,
            "dateCreated": dateCreated,
            "lastEdited" : lastEdited
        ]
    }
    
    
}
