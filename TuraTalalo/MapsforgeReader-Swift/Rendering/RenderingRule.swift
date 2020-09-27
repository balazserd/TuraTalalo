//
//  RenderingRule.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 25..
//

import Foundation

final class RenderingRule {
    init(category: String? = nil, keys: [String] = [String](), values: [String] = [String](), element: RenderingRule.Element = Element.any, closed: RenderingRule.Closed = Closed.any, minimumZoomLevel: UInt8 = 0, maximumZoomLevel: UInt8 = 127, children: [RenderingRule]? = nil, parent: RenderingRule? = nil, instructions: [RenderingInstruction] = []) {
        self.category = category
        self.keys = keys
        self.values = values
        self.element = element
        self.closed = closed
        self.minimumZoomLevel = minimumZoomLevel
        self.maximumZoomLevel = maximumZoomLevel
        self.children = children
        self.parent = parent
        self.instructions = instructions
    }

    var category: String? = nil
    var keys = [String]()
    var values = [String]()
    var element = Element.any
    var closed = Closed.any
    var minimumZoomLevel: UInt8 = 0
    var maximumZoomLevel: UInt8 = 12
    var children: [RenderingRule]? = nil
    var parent: RenderingRule? = nil
    var instructions: [RenderingInstruction] = []

    func match(categories: [String], tags: [String : String], zoom: UInt8, isClosed: Bool, isWay: Bool,
               renderingInstructions: inout [RenderingInstruction]) -> Bool {
        if category == nil && categories.first(where: { $0 == category }) == nil { return false }
        if zoom < minimumZoomLevel || zoom > maximumZoomLevel { return false }
        if (closed == .yes && !isClosed) || (closed == .no && isClosed) { return false }
        if (element == .way && !isWay) || (element == .node && isWay) { return false }

        var keyValueMatching = false
        for key in keys {
            // https://github.com/mapsforge/mapsforge/blob/master/docs/Rendertheme.md#rules
            if key == "*" {
                keyValueMatching = true
                break
            }

            let value = tags.keys.contains(key) ? tags[key]! : "~"

            keyValueMatching = values.contains { $0 == value || ($0 == "*" && value != "~") }
            if keyValueMatching { break } //breaks outer 'for'
        }

        if !keyValueMatching { return false }

        let matchingInstructions = instructions.filter { $0.category == nil || categories.contains($0.category!) }
        renderingInstructions.append(contentsOf: matchingInstructions)

        children?.forEach {
            _ = $0.match(categories: categories, tags: tags, zoom: zoom, isClosed: isClosed, isWay: isWay, renderingInstructions: &renderingInstructions)
        }

        return !instructions.isEmpty
    }
}

extension RenderingRule {
    enum Element : String {
        case node
        case way
        case any
    }

    enum Closed : String {
        case yes
        case no
        case any
    }
}
