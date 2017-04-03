//
//  SSCheckMark.swift
//  
//
//  Created by Chris Vasselli on 10/12/13.
//  Converted to Swift 3 by 
//  http://stackoverflow.com/questions/18977527/how-do-i-display-the-standard-checkmark-on-a-uicollectionviewcell

import UIKit

enum SSCheckMarkStyle : UInt {
    case OpenCircle
    case GrayedOut
}

class SSCheckMark: UIView {
    
    private var checkedBool: Bool = false
    // choose whether you like open or grayed out non-selected items
    private var checkMarkStyleReal: SSCheckMarkStyle=SSCheckMarkStyle.GrayedOut
    
    var checked: Bool {
        get {
            return self.checkedBool
        }
        set(checked) {
            self.checkedBool = checked
            self.setNeedsDisplay()
        }
    }
    
    var checkMarkStyle: SSCheckMarkStyle {
        get {
            return self.checkMarkStyleReal
        }
        set(checkMarkStyle) {
            self.checkMarkStyleReal = checkMarkStyle
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if self.checked {
            self.drawRectChecked(rect: rect)
        } else {
            if self.checkMarkStyle == SSCheckMarkStyle.OpenCircle {
                self.drawRectOpenCircle(rect: rect)
            } else if self.checkMarkStyle == SSCheckMarkStyle.GrayedOut {
                self.drawRectGrayedOut(rect: rect)
            }
        }
    }
    
    func drawRectChecked(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let checkmarkBlue2 = UIColor(red: 0.078, green: 0.435, blue: 0.875, alpha: 1)
        let shadow2 = UIColor.black
        
        let shadow2Offset = CGSize(width: 0.1, height: -0.1)
        let shadow2BlurRadius = 2.5
        let frame = self.bounds
        let group = CGRect(x: frame.minX + 3, y: frame.minY + 3, width: frame.width - 6, height: frame.height - 6)
        
        let checkedOvalPath = UIBezierPath(ovalIn: CGRect(x: group.minX + floor(group.width * 0.00000 + 0.5), y: group.minY + floor(group.height * 0.00000 + 0.5), width: floor(group.width * 1.00000 + 0.5) - floor(group.width * 0.00000 + 0.5), height: floor(group.height * 1.00000 + 0.5) - floor(group.height * 0.00000 + 0.5)))
        
        context!.saveGState()
        context!.setShadow(offset: shadow2Offset, blur: CGFloat(shadow2BlurRadius), color: shadow2.cgColor)
        checkmarkBlue2.setFill()
        checkedOvalPath.fill()
        context!.restoreGState()
        UIColor.white.setStroke()
        checkedOvalPath.lineWidth = 1
        checkedOvalPath.stroke()
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: group.minX + 0.27083 * group.width, y: group.minY + 0.54167 * group.height))
        bezierPath.addLine(to: CGPoint(x: group.minX + 0.41667 * group.width, y: group.minY + 0.68750 * group.height))
        bezierPath.addLine(to: CGPoint(x: group.minX + 0.75000 * group.width, y: group.minY + 0.35417 * group.height))
        bezierPath.lineCapStyle = CGLineCap.square
        UIColor.white.setStroke()
        bezierPath.lineWidth = 1.3
        bezierPath.stroke()
    }
    
    func drawRectGrayedOut(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let grayTranslucent = UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)
        let shadow2 = UIColor.black
        let shadow2Offset = CGSize(width: 0.1, height: -0.1)
        let shadow2BlurRadius = 2.5
        let frame = self.bounds
        let group = CGRect(x: frame.minX + 3, y: frame.minY + 3, width: frame.width - 6, height: frame.height - 6)
        let uncheckedOvalPath = UIBezierPath(ovalIn: CGRect(x: group.minX + floor(group.width * 0.00000 + 0.5), y: group.minY + floor(group.height * 0.00000 + 0.5), width: floor(group.width * 1.00000 + 0.5) - floor(group.width * 0.00000 + 0.5), height: floor(group.height * 1.00000 + 0.5) - floor(group.height * 0.00000 + 0.5)))
        
        context!.saveGState()
        context!.setShadow(offset: shadow2Offset, blur: CGFloat(shadow2BlurRadius), color: shadow2.cgColor)
        grayTranslucent.setFill()
        uncheckedOvalPath.fill()
        context!.restoreGState()
        UIColor.white.setStroke()
        uncheckedOvalPath.lineWidth = 1
        uncheckedOvalPath.stroke()
        let bezierPath = UIBezierPath()
        
        bezierPath.move(to: CGPoint(x: group.minX + 0.27083 * group.width, y: group.minY + 0.54167 * group.height))
        bezierPath.addLine(to: CGPoint(x: group.minX + 0.41667 * group.width, y: group.minY + 0.68750 * group.height))
        bezierPath.addLine(to: CGPoint(x: group.minX + 0.75000 * group.width, y: group.minY + 0.35417 * group.height))
        bezierPath.lineCapStyle = CGLineCap.square
        UIColor.white.setStroke()
        bezierPath.lineWidth = 1.3
        bezierPath.stroke()
    }
    
    func drawRectOpenCircle(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let shadow = UIColor.black
        let shadowOffset = CGSize(width: 0.1, height: -0.1)
        let shadowBlurRadius = 0.5
        let shadow2 = UIColor.black
        let shadow2Offset = CGSize(width: 0.1, height: -0.1)
        let shadow2BlurRadius = 2.5
        let frame = self.bounds
        let group = CGRect(x: frame.minX + 3, y: frame.minY + 3, width: frame.width - 6, height: frame.height - 6)
        let emptyOvalPath = UIBezierPath(ovalIn: CGRect(x: group.minX + floor(group.width * 0.00000 + 0.5), y: group.minY + floor(group.height * 0.00000 + 0.5), width: floor(group.width * 1.00000 + 0.5) - floor(group.width * 0.00000 + 0.5), height: floor(group.height * 1.00000 + 0.5) - floor(group.height * 0.00000 + 0.5)))
        
        context!.saveGState()
        context!.setShadow(offset: shadow2Offset, blur: CGFloat(shadow2BlurRadius), color: shadow2.cgColor)
        
        context!.restoreGState()
        context!.saveGState()
        context!.setShadow(offset: shadowOffset, blur: CGFloat(shadowBlurRadius), color: shadow.cgColor)
        UIColor.white.setStroke()
        emptyOvalPath.lineWidth = 1
        emptyOvalPath.stroke()
        context!.restoreGState()
        
    }
}
