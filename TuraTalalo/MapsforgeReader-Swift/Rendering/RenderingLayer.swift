//
//  RenderingLayer.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 25..
//

import Foundation

final class RenderingLayer {
    var id: String = String()
    var names: [String : String] = [:]
    var categories: [String] = []
    var overlays: [RenderingLayer]? = nil
    var children: [RenderingLayer]? = nil
    var parent: RenderingLayer? = nil
    var visible: Bool = Bool()
    var enabled: Bool = Bool()
    var zOrder: UInt8 = UInt8()

    init(id: String = String(), names: [String : String] = [:], categories: [String] = [],
         overlays: [RenderingLayer]? = nil, children: [RenderingLayer]? = nil,
         parent: RenderingLayer? = nil, visible: Bool = Bool(), enabled: Bool = Bool(),
         zOrder: UInt8 = UInt8()) {
        self.id = id
        self.names = names
        self.categories = categories
        self.overlays = overlays
        self.children = children
        self.parent = parent
        self.visible = visible
        self.enabled = enabled
        self.zOrder = zOrder
    }

    func name(lang: String = "en") -> String? {
        return names[lang]
    }
}
