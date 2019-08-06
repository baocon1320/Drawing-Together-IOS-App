//
//  User.swift
//  DrawApp
//
//  Created by Bao Nguyen on 2/16/19.
//  Copyright © 2019 Bao Nguyen. All rights reserved.
//

import Foundation

class User {
    var uid : String
    var name : String?
    var email : String
    
    init(uid : String, name : String, email : String) {
        self.uid = uid
        self.name = name
        self.email = email
    }
}
