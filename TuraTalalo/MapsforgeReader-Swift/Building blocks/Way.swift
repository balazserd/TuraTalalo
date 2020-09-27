//
//  Way.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 27..
//

import Foundation
import CoreGraphics

struct Way : Hashable {
    var id = UUID()
    var coordinates: [[CGPoint]] = []
    var tags: Dictionary<String, String> = [:]
    var labelPosition: CGPoint? = nil
    var layer: Int8 = Int8()
    var isClosed: Bool = false

    static func ==(lhs: Way, rhs: Way) -> Bool {
        if lhs.coordinates != rhs.coordinates { return false }
        if lhs.tags != rhs.tags { return false }
        if lhs.labelPosition != rhs.labelPosition { return false }
        if lhs.layer != rhs.layer { return false }
        if lhs.isClosed != rhs.isClosed { return false }

        return true
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
