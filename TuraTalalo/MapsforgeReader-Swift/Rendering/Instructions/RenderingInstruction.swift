//
//  RenderingInstructions.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 25..
//

import Foundation
import CoreGraphics
import SwiftyXMLParser

class RenderingInstruction : Hashable {
    var type: InstructionType

    init(type: InstructionType) {
        self.type = type
    }

    func saveToContextInstructions(context: inout RenderTheme.ThemeParseContext) {
        guard self.id != nil else { return }

        context.instructions[self.id!] = self
    }

    var category: String? = nil
    var sourceFileName: String? = nil
    var key: String? = nil
    var id: String? = nil

    var zOrder: UInt32? = nil
    var priority: Int32? = nil

    var symbolWidth: CGFloat? = nil
    var symbolHeight: CGFloat? = nil
    var symbolPercent: CGFloat? = nil
    var symbolScaling: SymbolScaling? = nil

    var fill: CGColor? = nil
    var stroke: CGColor? = nil
    var strokeWidth: CGFloat? = nil
    var dy: CGFloat? = nil

    var scale: Scale? = nil
    var display: Display? = nil
    var strokeLineCap: CGLineCap? = nil
    var strokeLineJoin: CGLineJoin? = nil
    var strokeDashArray: [CGFloat]? = nil

    var repeatGap: CGFloat? = nil
    var repeatStart: CGFloat? = nil
    var radius: CGFloat? = nil

    var symbolId: String? = nil
    var symbol: RenderingInstruction? = nil

    var fontSize: CGFloat? = nil
    var fontFamily: FontFamily? = nil
    var fontPosition: FontPosition? = nil
    var fontStyle: FontStyle? = nil

    var alignCenter: Bool? = nil
    var rotate: Bool? = nil
    var `repeat`: Bool? = nil
    var scaleRadius: Bool? = nil

    func hash(into hasher: inout Hasher) {
        hasher.combine(key!)
    }

    static func ==(lhs: RenderingInstruction, rhs: RenderingInstruction) -> Bool {
        return lhs.id == rhs.id
    }
}

//MARK:- Enumerations
extension RenderingInstruction {
    enum InstructionType : String, CaseIterable {
        case area, line, caption, circle, lineSymbol, pathText, symbol
    }

    enum Scale : String {
        case all, none, stroke
    }

    enum SymbolScaling : String {
        case defaultSize, customSize, percent
    }

    enum Display : String {
        case always, never, ifspace
    }

    enum FontFamily : String {
        case `default`, monospace, sans_serif, serif
    }

    enum FontStyle : String {
        case bold, bold_italic, italic, normal
    }

    enum FontPosition : String {
        case auto, center, below, below_left, below_right, above, above_left, above_right, left, right
    }
}

extension CGLineJoin {
    static func fromString(str: String) -> CGLineJoin {
        if str == "miter" { return .miter }
        if str == "round" { return .round }
        if str == "bevel" { return .bevel }

        fatalError()
    }
}
extension CGLineCap {
    static func fromString(str: String) -> CGLineCap {
        if str == "butt"    { return .butt }
        if str == "round"   { return .round }
        if str == "square"  { return .square }

        fatalError()
    }
}
