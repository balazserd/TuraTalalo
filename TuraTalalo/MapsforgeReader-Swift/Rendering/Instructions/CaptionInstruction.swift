//
//  CaptionInstruction.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 25..
//

import Foundation
import CoreGraphics
import SwiftyXMLParser
import UIKit

final class CaptionInstruction : RenderingInstruction {
    init(from xmlNode: XML.Element, withContext context: inout RenderTheme.ThemeParseContext) {
        self.type = .caption

        let priorityString = xmlNode.attributes["priority"]
        let displayString = xmlNode.attributes["display"]
        let dyString = xmlNode.attributes["dy"]
        let fontFamilyString = xmlNode.attributes["font-family"]
        let fontStyleString = xmlNode.attributes["font-style"]
        let fontSizeString = xmlNode.attributes["font-size"]
        let fillString = xmlNode.attributes["fill"]
        let strokeString = xmlNode.attributes["stroke"]
        let strokeWidthString = xmlNode.attributes["stroke-width"]
        let fontPositionString = xmlNode.attributes["position"]

        self.category = xmlNode.attributes["cat"]
        self.priority = priorityString != nil ? Int32(priorityString!) : 0
        self.key = xmlNode.attributes["k"]
        self.display = displayString != nil ? Display(rawValue: displayString!)! : .ifspace
        self.dy = dyString != nil ? CGFloat(Double(dyString!)!) : 0
        self.fontFamily = fontFamilyString != nil ? FontFamily(rawValue: fontFamilyString!)! : .default
        self.fontStyle = fontStyleString != nil ? FontStyle(rawValue: fontStyleString!)! : .normal
        self.fontSize = fontSizeString != nil ? CGFloat(Double(fontSizeString!)!) : 0
        self.fill = XMLTypeCaster.stringToCGColor(string: fillString) ?? UIColor.black.cgColor
        self.stroke = XMLTypeCaster.stringToCGColor(string: strokeString) ?? UIColor.black.cgColor
        self.strokeWidth = strokeWidthString != nil ? CGFloat(Double(strokeWidthString!)!) : 0
        self.fontPosition = fontPositionString != nil ? FontPosition(rawValue: fontPositionString!)! : .auto
        self.symbolId = xmlNode.attributes["symbol-id"]

        if self.symbolId != nil, let instruction = context.instructions[self.symbolId!] {
            self.symbol = instruction
        }
    }
}
