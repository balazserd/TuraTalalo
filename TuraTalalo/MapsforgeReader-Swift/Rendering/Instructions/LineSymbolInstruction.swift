//
//  LineSymbolInstruction.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 25..
//

import Foundation
import CoreGraphics
import SwiftyXMLParser
import UIKit

final class LineSymbolInstruction : RenderingInstruction {
    init(from xmlNode: XML.Element) {
        self.type = .lineSymbol

        let displayString = xmlNode.attributes["display"]
        let dyString = xmlNode.attributes["dy"]
        let symbolWidthString = xmlNode.attributes["symbol-width"]
        let symbolHeightString = xmlNode.attributes["symbol-height"]
        let symbolPercentString = xmlNode.attributes["symbol-percent"]
        let symbolScalingString = xmlNode.attributes["symbol-scaling"]
        let scaleString = xmlNode.attributes["scale"]
        let alignCenterString = xmlNode.attributes["align-center"]
        let priorityString = xmlNode.attributes["priority"]
        let repeatString = xmlNode.attributes["repeat"]
        let repeatGapString = xmlNode.attributes["repeat-gap"]
        let repeatStartString = xmlNode.attributes["repeat-start"]
        let rotateString = xmlNode.attributes["rotate"]
        
        self.category = xmlNode.attributes["cat"]
        self.display = displayString != nil ? Display(rawValue: displayString!)! : .ifspace
        self.dy = dyString != nil ? CGFloat(Double(dyString!)!) : 0
        self.source = XMLTypeCaster.stringToFileURL(urlString: xmlNode.attributes["src"])
        self.symbolWidth = symbolWidthString != nil ? CGFloat(Double(symbolWidthString!)!) : nil
        self.symbolHeight = symbolHeightString != nil ? CGFloat(Double(symbolHeightString!)!) : nil
        self.symbolPercent = symbolPercentString != nil ? CGFloat(Double(symbolPercentString!)!) : nil
        self.symbolScaling = symbolScalingString != nil ? SymbolScaling(rawValue: symbolScalingString!) : .defaultSize
        self.scale = scaleString != nil ? Scale(rawValue: scaleString!) : .stroke
        self.alignCenter = alignCenterString != nil ? Bool(alignCenterString!) : false
        self.priority = priorityString != nil ? Int32(priorityString!) : 0
        self.repeat = repeatString != nil ? Bool(repeatString!) : false
        self.repeatGap = repeatGapString != nil ? CGFloat(Double(repeatGapString!)!) : 200
        self.repeatStart = repeatStartString != nil ? CGFloat(Double(repeatStartString!)!) : 30
        self.rotate = rotateString != nil ? Bool(rotateString!) : true    }
}
