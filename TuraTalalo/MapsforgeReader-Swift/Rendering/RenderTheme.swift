//
//  RenderThemeReader.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 25..
//

import Foundation
import SwiftyXMLParser
import CoreGraphics

final class RenderTheme : NSObject {
    private let renderThemeXml: XML.Accessor
    private let fileUrl: URL

    var layers = [String : RenderingLayer]()
    var rules = [RenderingRule]()
    var defaultLayerName: String? = nil
    var defaultLanguageName: String? = nil

    var version: String? = nil
    var mapBackground: CGColor? = nil
    var mapOuterBackground: CGColor? = nil

    var resourceDirectory: String = String()
    var ruleMatchCache = [String : [RenderingInstruction]]()

    init(withFileUrl fileUrl: URL) {
        renderThemeXml = XML.parse(try! Data(contentsOf: fileUrl))
        self.fileUrl = fileUrl

        super.init()

        self.read()
    }

    func read() {
        let themeParseContext = ThemeParseContext(instructions: [:],
                                                  rootDirectory: fileUrl.deletingLastPathComponent(),
                                                  order: 0)
        let root = renderThemeXml.first
        if root.name != "rendertheme" { fatalError("Rendertheme element not found!") }

        self.version = root.attributes["version"] ?? self.version
        self.mapBackground = XMLTypeCaster.stringToCGColor(string: root.attributes["map-background"]) ?? self.mapBackground
        self.mapOuterBackground = XMLTypeCaster.stringToCGColor(string: root.attributes["map-background-outside"]) ?? self.mapOuterBackground

        let styleMenu = root["stylemenu"]
        if styleMenu.error == nil {
            //my map has no stylemenu, so TODO
        }

        if let rules = root.all?.filter({ $0.name == "rule" }) {
            for rule in rules {
                var renderingRule = 
            }
        }
    }
}

extension RenderTheme {
    struct ThemeParseContext {
        var instructions: [String : RenderingInstruction]
        var rootDirectory: URL
        var order: UInt32
    }
}
