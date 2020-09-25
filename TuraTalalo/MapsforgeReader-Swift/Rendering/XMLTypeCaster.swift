//
//  XMLTypeCaster.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 25..
//

import Foundation
import SwiftyXMLParser
import CoreGraphics

final class XMLTypeCaster {
    static let colorRegExp = try! NSRegularExpression(pattern: "(?:([0-9a-f])([0-9a-f]))?([0-9a-f])([0-9a-f])([0-9a-f])([0-9a-f])([0-9a-f])([0-9a-f])")

    class func stringToCGColor(string: String?) -> CGColor? {
        guard string != nil else { return nil }

        var str = string! //get a mutable copy
        guard colorRegExp.numberOfMatches(in: str, range: NSRange(0..<str.count)) == 1 else {
            return nil
        }

        var colorRGB: UInt64 = 0
        str.remove(at: str.startIndex) //remove # at start
        Scanner(string: str).scanHexInt64(&colorRGB)

        return CGColor(red: CGFloat((colorRGB & 0xff0000) >> 16) / 255,
                       green: CGFloat((colorRGB & 0x00ff00) >> 8) / 255,
                       blue: CGFloat(colorRGB & 0x0000ff) / 255,
                       alpha: 1)
    }

    class func xmlElementToRenderingRule(xmlElement: XML.Element, context: inout RenderTheme.ThemeParseContext) -> RenderingRule? {
        var instructions = [RenderingInstruction]()
        let instructionTypeNames = RenderingInstruction.InstructionType.allCases.map { $0.rawValue }
        for pie in xmlElement.childElements { //P(ossible) I(nstruction) E(lement) = pie
            guard instructionTypeNames.contains(pie.name) else { continue }

            let name = pie.name

            if name == "area"       { instructions.append(AreaInstruction(from: pie)) }
            if name == "line"       { instructions.append(LineInstruction(from: pie)) }
            if name == "caption"    { instructions.append(CaptionInstruction(from: pie, withContext: &context)) }
            if name == "circle"     { instructions.append(CircleInstruction(from: pie)) }
            if name == "symbol"     { instructions.append(SymbolInstruction(from: pie, withContext: &context)) }
            if name == "pathText"   { instructions.append(PathTextInstruction(from: pie)) }
            if name == "lineSymbol" { instructions.append(LineSymbolInstruction(from: pie)) }

            instructions.last!.zOrder = context.order
            context.order += 1
        }

        let rule = RenderingRule(category: xmlElement.attributes["cat"]!,
                                 keys: xmlElement.attributes["k"]!.components(separatedBy: "|"),
                                 values: xmlElement.attributes["v"]!.components(separatedBy: "|"),
                                 element: RenderingRule.Element(rawValue: xmlElement.attributes["e"]!)!,
                                 closed: RenderingRule.Closed(rawValue: xmlElement.attributes["closed"]!)!,
                                 minimumZoomLevel: UInt8(xmlElement.attributes["zoom-min"]!)!,
                                 maximumZoomLevel: UInt8(xmlElement.attributes["zoom-max"]!)!,
                                 children: nil,
                                 parent: nil,
                                 instructions: instructions)

        let childRuleElements = xmlElement.childElements.filter { $0.name == "rule" }
        var childRules = [RenderingRule]()
        for childElement in childRuleElements {
            if let childRule = xmlElementToRenderingRule(xmlElement: childElement, context: &context) {
                childRules.append(childRule)
                childRule.parent = rule
            }
        }
        rule.children = childRules

        return rule
    }

    class func stringToFileURL(urlString: String?) -> URL? {
        guard urlString != nil else { return nil }

        return URL(fileURLWithPath: urlString!)
    }

    class func stringToDashArray(dashArrayString: String?) -> [CGFloat]? {
        guard dashArrayString != nil else { return nil }

        let copyString = dashArrayString!
        let dashArray = copyString.components(separatedBy: ",")
            .map { CGFloat(Double($0)!) }

        return dashArray
    }
}
