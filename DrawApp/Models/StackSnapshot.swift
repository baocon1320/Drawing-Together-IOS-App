//
//  StackSnapshot.swift
//  DrawApp
//  Implement a stack of screen snapshot to redo undo button
//  Created by Bao Nguyen on 3/15/19.
//  Copyright © 2019 Bao Nguyen. All rights reserved.
//

import Foundation

class StackSnapshot {
    let stackSize = 5
    var stackCur : Int
    var stackFirst : Int
    var stackEnd : Int
    var items = [ScreeenSnapshot?](repeating: nil, count: 5)
    
    init() {
        self.stackCur = -1
        self.stackFirst = 0
        self.stackEnd = 0
    }
    
    func push(newSnapshot : ScreeenSnapshot) {
        if(stackCur >= 0 && (stackCur + 1) % stackSize == stackFirst) {
            stackFirst = (stackFirst + 1) % stackSize
        }
        stackCur = (stackCur + 1) % stackSize
        items[stackCur] = newSnapshot
        
        stackEnd = stackCur
    }
    
    func undo() -> ScreeenSnapshot?{
        if stackCur == stackFirst {
            return items[stackCur]
        }
        
        let cur = stackCur
        stackCur = (stackCur - 1 + stackSize) % stackSize
        return items[cur]
    }
    
    func redo() -> ScreeenSnapshot? {
        if stackCur == stackEnd {
            return items[stackCur]
        }
        stackCur = (stackCur + 1) % stackSize
        return items[stackCur]
    }
}
