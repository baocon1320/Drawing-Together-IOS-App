//
//  CanvasDetail.swift
//  DrawApp
//
//  Created by Bao Nguyen on 2/12/19.
//  Copyright © 2019 Bao Nguyen. All rights reserved.
//

import Foundation
import Firebase

class CanvasGeneralInfo{
    var id : String?
    var title : String
    var owner : String
    var dateCreated : String
    var lastEdited : String
    let ref : DatabaseReference?
    
    init(title : String, owner : String, dateCreated : String, lastEdited : String){
        self.title = title
        self.owner = owner
        self.dateCreated = dateCreated
        self.lastEdited = lastEdited
        ref = nil
    }
    
    init(snapshot: DataSnapshot)
    {
        let snapValues = snapshot.value as! [String : AnyObject]
        id = snapshot.key
        title = snapValues["title"] as! String
        owner = snapValues["owner"] as! String
        dateCreated = snapValues["dateCreated"] as! String
        lastEdited = snapValues["lastEdited"] as! String
        ref = snapshot.ref
    }
    
    func toAnyObject() -> Any {
        return [
            "title": title,
            "owner": owner,
            "dateCreated": dateCreated,
            "lastEdited" : lastEdited
        ]
    }
    
}

