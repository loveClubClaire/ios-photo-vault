//
//  CustomUIButton.swift
//  Photo Vault
//
//  Created by Zachary Whitten on 3/30/17.
//  Copyright © 2017 16^2. All rights reserved.
//
//  uibutton-making-the-hit-area-larger-than-the-default-hit-area
//  http://stackoverflow.com/a/13977921/3594256

import UIKit

class CustomUIButton: UIButton {

    override func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
        let margin: CGFloat = 5
        let area = self.bounds.insetBy(dx: -margin, dy: -margin)
        return area.contains(point)
    }

}
