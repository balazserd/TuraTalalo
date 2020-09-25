//
//  AreaInstruction.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 25..
//

import Foundation
import CoreGraphics
import SwiftyXMLParser
import UIKit

final class AreaInstruction : RenderingInstruction {
    init(from xmlNode: XML.Element) {
        self.type = .area
        
        let symbolWidthString = xmlNode.attributes["symbol-width"]
        let symbolHeightString = xmlNode.attributes["symbol-height"]
        let symbolPercentString = xmlNode.attributes["symbol-percent"]
        let symbolScalingString = xmlNode.attributes["symbol-scaling"]
        let scaleString = xmlNode.attributes["scale"]
        let strokeWidthString = xmlNode.attributes["stroke-width"]

        self.source = XMLTypeCaster.stringToFileURL(urlString: xmlNode.attributes["src"])
        self.symbolWidth = symbolWidthString != nil ? CGFloat(Double(symbolWidthString!)!) : nil
        self.symbolHeight = symbolHeightString != nil ? CGFloat(Double(symbolHeightString!)!) : nil
        self.symbolPercent = symbolPercentString != nil ? CGFloat(Double(symbolPercentString!)!) : nil
        self.symbolScaling = symbolScalingString != nil ? SymbolScaling(rawValue: symbolScalingString!) : nil
        self.fill = XMLTypeCaster.stringToCGColor(string: xmlNode.attributes["fill"]) ?? UIColor.black.cgColor
        self.stroke = XMLTypeCaster.stringToCGColor(string: xmlNode.attributes["stroke"]) ?? UIColor.black.cgColor
        self.scale = scaleString != nil ? Scale(rawValue: scaleString!) : nil
        self.strokeWidth = strokeWidthString != nil ? CGFloat(Double(strokeWidthString!)!) : 0.0
    }
}
