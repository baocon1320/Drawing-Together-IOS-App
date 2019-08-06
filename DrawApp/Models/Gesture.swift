//
//  Gesture.swift
//  DrawApp
//
//  Created by Bao Nguyen on 2/16/19.
//  Copyright © 2019 Bao Nguyen. All rights reserved.
//

import Foundation
import Firebase
import UIKit

class Gesture {
    var id : String?
    var fromPoint_x : CGFloat
    var fromPoint_y : CGFloat
    var toPoint_x : CGFloat
    var toPoint_y : CGFloat
    var penInfo : PenInfo
    var ref : DatabaseReference?
    
    init(fromPoint_x : CGFloat, fromPoint_y : CGFloat, toPoint_x : CGFloat, toPoint_y : CGFloat, penInfo : PenInfo) {
        self.fromPoint_x = fromPoint_x
        self.fromPoint_y = fromPoint_y
        self.toPoint_x = toPoint_x
        self.toPoint_y = toPoint_y
        self.penInfo = PenInfo(width: penInfo.width, green: penInfo.green, red: penInfo.red, blue: penInfo.blue)
        self.ref = nil
    }
    
    init(snapshot : DataSnapshot) {
        let snapshotValues = snapshot.value as! [String : AnyObject]
        self.id = snapshot.key
        self.fromPoint_x = snapshotValues["fromPoint_x"] as! CGFloat
        self.fromPoint_y = snapshotValues["fromPoint_y"] as! CGFloat
        self.toPoint_x = snapshotValues["toPoint_x"] as! CGFloat
        self.toPoint_y = snapshotValues["toPoint_y"] as! CGFloat
        let width = snapshotValues["brushSize"] as! CGFloat
        let redColor = snapshotValues["redColor"] as! CGFloat
        let greenColor = snapshotValues["greenColor"] as! CGFloat
        let blueColor = snapshotValues["blueColor"] as! CGFloat
        self.penInfo = PenInfo(width: width, green: greenColor, red: redColor, blue: blueColor)
        self.ref = snapshot.ref
    }
    
    func toAnyObject() -> Any {
        return [
            "fromPoint_x" : fromPoint_x,
            "fromPoint_y" : fromPoint_y,
            "toPoint_x" : toPoint_x,
            "toPoint_y" : toPoint_y,
            "brushSize" : penInfo.width,
            "redColor" : penInfo.red,
            "greenColor" : penInfo.green,
            "blueColor" : penInfo.blue
        ]
    }
    
}
