//
//  LineInstruction.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 25..
//

import Foundation
import CoreGraphics
import SwiftyXMLParser
import UIKit

final class LineInstruction : RenderingInstruction {
    init(from xmlNode: XML.Element) {
        self.type = .line

        let symbolWidthString = xmlNode.attributes["symbol-width"]
        let symbolHeightString = xmlNode.attributes["symbol-height"]
        let symbolPercentString = xmlNode.attributes["symbol-percent"]
        let dyString = xmlNode.attributes["dy"]
        let scaleString = xmlNode.attributes["scale"]
        let symbolScalingString = xmlNode.attributes["symbol-scaling"]
        let strokeString = xmlNode.attributes["stroke"]
        let strokeWidthString = xmlNode.attributes["stroke-width"]
        let strokeDashArrayString = xmlNode.attributes["stroke-dasharray"]
        let strokeLineCapString = xmlNode.attributes["stroke-linecap"]
        let strokeLineJoinString = xmlNode.attributes["stroke-linejoin"]

        self.category = xmlNode.attributes["cat"]
        self.source = XMLTypeCaster.stringToFileURL(urlString: xmlNode.attributes["src"])
        self.symbolWidth = symbolWidthString != nil ? CGFloat(Double(symbolWidthString!)!) : nil
        self.symbolHeight = symbolHeightString != nil ? CGFloat(Double(symbolHeightString!)!) : nil
        self.symbolPercent = symbolPercentString != nil ? CGFloat(Double(symbolPercentString!)!) : nil
        self.dy = dyString != nil ? CGFloat(Double(dyString!)!) : 0
        self.scale = scaleString != nil ? Scale(rawValue: scaleString!) : .stroke
        self.symbolScaling = symbolScalingString != nil ? SymbolScaling(rawValue: symbolScalingString!) : .defaultSize
        self.stroke = XMLTypeCaster.stringToCGColor(string: strokeString) ?? UIColor.black.cgColor
        self.strokeWidth = strokeWidthString != nil ? CGFloat(Double(strokeWidthString!)!) : 0
        self.strokeDashArray = XMLTypeCaster.stringToDashArray(dashArrayString: strokeDashArrayString) ?? []
        self.strokeLineCap = strokeLineCapString != nil ? CGLineCap.fromString(str: strokeLineCapString!) : .round
        self.strokeLineJoin = strokeLineJoinString != nil ? CGLineJoin.fromString(str: strokeLineJoinString!) : .round
    }
}
