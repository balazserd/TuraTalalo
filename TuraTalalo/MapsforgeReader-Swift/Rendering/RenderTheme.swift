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
    var ruleMatchCache = NSCache<ValueTypeWrapper<String>, ValueTypeWrapper<[RenderingInstruction]>>()

    init(withFileUrl fileUrl: URL) {
        renderThemeXml = XML.parse(try! Data(contentsOf: fileUrl))
        self.fileUrl = fileUrl

        super.init()

        self.read()
    }

    func read() {
        var themeParseContext = ThemeParseContext(instructions: [:],
                                                  rootDirectory: fileUrl.deletingLastPathComponent(),
                                                  order: 0)
        let root = renderThemeXml.all![0].childElements[0]
        if root.name != "rendertheme" { fatalError("Rendertheme element not found!") }

        self.version = root.attributes["version"] ?? self.version
        self.mapBackground = XMLTypeCaster.stringToCGColor(string: root.attributes["map-background"]) ?? self.mapBackground
        self.mapOuterBackground = XMLTypeCaster.stringToCGColor(string: root.attributes["map-background-outside"]) ?? self.mapOuterBackground

        if let styleMenu = root.attributes["stylemenu"] {
            //my map has no stylemenu, so TODO
        }

        let ruleElements = root.childElements.filter({ $0.name == "rule" })
        for ruleElement in ruleElements {
            guard let renderingRule = XMLTypeCaster.xmlElementToRenderingRule(xmlElement: ruleElement, context: &themeParseContext) else {
                return
            }
            self.rules.append(renderingRule)
        }
    }

    func getCategories(forLayer layer: RenderingLayer?) -> [String]? {
        if layer == nil || !layer!.enabled { return nil }

        let parentCategories = layer!.parent?.categories
        let overlayCategories = layer!.overlays?.reduce(into: [String]()) {
            $0!.append(contentsOf: $1.categories)
        }

        var allCategories = layer!.categories
        if parentCategories != nil { allCategories.append(contentsOf: parentCategories!) }
        if overlayCategories != nil { allCategories.append(contentsOf: overlayCategories!) }

        return allCategories
    }

    func getVisibleLayerIds() -> [String] {
        return layers.filter { $0.value.visible }.map { $0.key }
    }

    func getSafeLayer(withId id: String) -> RenderingLayer? {
        return layers.first { $0.key == id }?.value
    }

    func getOverlayIds(withLayerId id: String) -> [String]? {
        let safeLayer = getSafeLayer(withId: id)
        return safeLayer?.overlays?.map { $0.id }
    }

    func match(layerId: String?, tags: [String : String], zoom: UInt8, isClosed: Bool, isWay: Bool, renderingInstructionsOut: inout [RenderingInstruction]) -> Bool {
        var categories = [String]()
        if layerId != nil {
            guard let layer = getSafeLayer(withId: layerId!) else { return false }
            categories = getCategories(forLayer: layer) ?? []
        }

        let matchKey = Self.makeMatchString(from: tags, layerId: layerId, zoom: zoom, isClosed: isClosed, isWay: isWay)
        if let instructions = ruleMatchCache.object(forKey: ValueTypeWrapper(matchKey)) {
            renderingInstructionsOut.append(contentsOf: instructions.wrappedValue)
        } else {
            rules.forEach { rule in
                if rule.match(categories: categories, tags: tags, zoom: zoom, isClosed: isClosed, isWay: isWay, renderingInstructions: &renderingInstructionsOut) {
                    ruleMatchCache.setObject(ValueTypeWrapper(renderingInstructionsOut), forKey: ValueTypeWrapper(matchKey))
                }
            }
        }

        return !renderingInstructionsOut.isEmpty
    }

    class func makeMatchString(from keyValueDictionary: [String : String], layerId: String?, zoom: UInt8, isClosed: Bool, isWay: Bool) -> String {
        var matchString = ""
        matchString += "\(layerId ?? "");"

        let unneededKeys = ["name", "addr:housenumber", "ref", "ele"]
        let kvDictWithoutNotNeededPairs = keyValueDictionary.filter { !unneededKeys.contains($0.key) }
        for kvp in kvDictWithoutNotNeededPairs {
            matchString += "\(kvp.key)=\(kvp.value);"
        }

        matchString += "\(zoom);\(isClosed);\(isWay)"

        return matchString
    }
}

extension RenderTheme {
    struct ThemeParseContext {
        var instructions: [String : RenderingInstruction]
        var rootDirectory: URL
        var order: UInt32
    }
}
