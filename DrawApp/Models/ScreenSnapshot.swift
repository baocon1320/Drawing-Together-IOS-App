//
//  ScreenSnapshot.swift
//  DrawApp
//  Model for current snapshot of Screen for redo undo button
//  Created by Bao Nguyen on 3/15/19.
//  Copyright © 2019 Bao Nguyen. All rights reserved.
//

import Foundation
import UIKit

class ScreeenSnapshot {
    var currentGestureInfo : GestureInfo?
    var gestures = [String : Gesture]()
    
    init(currentGestureInfo : GestureInfo?, gestures : [String : Gesture]) {
        self.currentGestureInfo = currentGestureInfo
        self.gestures = gestures
    }
}
