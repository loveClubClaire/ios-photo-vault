//
//  Array+Extension.swift
//  Photo Vault
//
//  Created by Zachary Whitten on 2/27/17.
//  Copyright © 2017 16^2. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    //Remove first collection element that is equal to the given `object`:
    mutating func remove(object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}
