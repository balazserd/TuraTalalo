//
//  PathTextInstruction.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 25..
//

import Foundation
import CoreGraphics
import SwiftyXMLParser
import UIKit

final class PathTextInstruction : RenderingInstruction {
    init(from xmlNode: XML.Element) {
        self.type = .pathText

        let priorityString = xmlNode.attributes["priority"]
        let displayString = xmlNode.attributes["display"]
        let dyString = xmlNode.attributes["dy"]
        let fontFamilyString = xmlNode.attributes["font-family"]
        let fontStyleString = xmlNode.attributes["font-style"]
        let fontSizeString = xmlNode.attributes["font-size"]
        let fillString = xmlNode.attributes["fill"]
        let strokeString = xmlNode.attributes["stroke"]
        let strokeWidthString = xmlNode.attributes["stroke-width"]
        let scaleString = xmlNode.attributes["scale"]
        let repeatString = xmlNode.attributes["repeat"]
        let repeatGapString = xmlNode.attributes["repeat-gap"]
        let repeatStartString = xmlNode.attributes["repeat-start"]
        let rotateString = xmlNode.attributes["rotate"]

        self.category = xmlNode.attributes["cat"]
        self.priority = priorityString != nil ? Int32(priorityString!) : 0
        self.display = displayString != nil ? Display(rawValue: displayString!)! : .ifspace
        self.key = xmlNode.attributes["k"]
        self.dy = dyString != nil ? CGFloat(Double(dyString!)!) : 0
        self.fontFamily = fontFamilyString != nil ? FontFamily(rawValue: fontFamilyString!)! : .default
        self.fontStyle = fontStyleString != nil ? FontStyle(rawValue: fontStyleString!)! : .normal
        self.fontSize = fontSizeString != nil ? CGFloat(Double(fontSizeString!)!) : 0
        self.fill = XMLTypeCaster.stringToCGColor(string: fillString) ?? UIColor.black.cgColor
        self.stroke = XMLTypeCaster.stringToCGColor(string: strokeString) ?? UIColor.black.cgColor
        self.strokeWidth = strokeWidthString != nil ? CGFloat(Double(strokeWidthString!)!) : 0
        self.scale = scaleString != nil ? Scale(rawValue: scaleString!) : .stroke
        self.repeat = repeatString != nil ? Bool(repeatString!) : false
        self.repeatGap = repeatGapString != nil ? CGFloat(Double(repeatGapString!)!) : 200
        self.repeatStart = repeatStartString != nil ? CGFloat(Double(repeatStartString!)!) : 30
        self.rotate = rotateString != nil ? Bool(rotateString!) : true
    }
}
