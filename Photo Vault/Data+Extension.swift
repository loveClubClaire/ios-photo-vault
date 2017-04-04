//
//  Data+Extension.swift
//  Photo Vault
//
//  Created by Zachary Whitten on 4/3/17.
//  Copyright © 2017 16^2. All rights reserved.
//

import Foundation

extension Data{
    
    mutating func addJunkHeader(){
        for _ in 1...50{
            self.insert(Data.Iterator.Element(255), at: 0)
        }
    }
    
    mutating func removeJunkHeader(){
        for _ in 1...50{
            self.remove(at: 0)
        }
    }
    
    
}
