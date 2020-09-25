//
//  RenderingRule.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 25..
//

import Foundation

final class RenderingRule {
    init(category: String = String(), keys: [String] = [String](), values: [String] = [String](), element: RenderingRule.Element = Element.any, closed: RenderingRule.Closed = Closed.any, minimumZoomLevel: UInt8 = UInt8(), maximumZoomLevel: UInt8 = UInt8(), children: [RenderingRule]? = nil, parent: RenderingRule? = nil, instructions: [RenderingInstruction] = []) {
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

    var category = String()
    var keys = [String]()
    var values = [String]()
    var element = Element.any
    var closed = Closed.any
    var minimumZoomLevel = UInt8()
    var maximumZoomLevel = UInt8()
    var children: [RenderingRule]? = nil
    var parent: RenderingRule? = nil
    var instructions: [RenderingInstruction] = []

    func match(categories: [String], tags: [String : String], zoom: UInt8, isClosed: Bool, isWay: Bool,
               renderingInstructions: [RenderingInstruction]) -> Bool {
        
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
