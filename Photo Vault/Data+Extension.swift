//
//  Data+Extension.swift
//  Photo Vault
//
//  Created by Zachary Whitten on 4/3/17.
//  Copyright © 2017 16^2. All rights reserved.
//
//Functions for adding and removing 50 bytes of junk to the front of any Data object. Yes this really should be a subclass with a bool indicating if a junk header has been added or not. I was lazy, sorry. Becuase, yes, there is no safe guard here. If you call removeJunkHeader and there's no junk header, you're just gonna delete the first fifty bytes of your data object, and now it's all junk. If you're for serious about using this, just make it a subclass and save everyone the headache.
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
