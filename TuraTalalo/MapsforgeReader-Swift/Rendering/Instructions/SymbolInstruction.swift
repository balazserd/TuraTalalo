//
//  SymbolInstruction.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 25..
//

import Foundation
import CoreGraphics
import SwiftyXMLParser

final class SymbolInstruction : RenderingInstruction {
    init(from xmlNode: XML.Element, withContext context: inout RenderTheme.ThemeParseContext) {
        self.type = .symbol

        let displayString = xmlNode.attributes["display"]
        let priorityString = xmlNode.attributes["priority"]
        let symbolWidthString = xmlNode.attributes["symbol-width"]
        let symbolHeightString = xmlNode.attributes["symbol-height"]
        let symbolPercentString = xmlNode.attributes["symbol-percent"]
        let symbolScalingString = xmlNode.attributes["symbol-scaling"]

        self.category = xmlNode.attributes["cat"]
        self.id = xmlNode.attributes["id"]
        self.display = displayString != nil ? Display(rawValue: displayString!)! : .ifspace
        self.priority = priorityString != nil ? Int32(priorityString!) : 0
        self.source = XMLTypeCaster.stringToFileURL(urlString: xmlNode.attributes["src"])
        self.symbolWidth = symbolWidthString != nil ? CGFloat(Double(symbolWidthString!)!) : 0
        self.symbolHeight = symbolHeightString != nil ? CGFloat(Double(symbolHeightString!)!) : 0
        self.symbolPercent = symbolPercentString != nil ? CGFloat(Double(symbolPercentString!)!) : 0
        self.symbolScaling = symbolScalingString != nil ? SymbolScaling(rawValue: symbolScalingString!) : .defaultSize

        if self.id != nil {
            context.instructions[self.id!] = self
        }
    }
}
