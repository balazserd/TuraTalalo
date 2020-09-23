//
//  TileKey.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 23..
//

import Foundation

struct TileKey {
    var x: UInt32
    var y: UInt32
    var z: UInt8

    init(x: UInt32, y: UInt32, z: UInt8, isTopLeft: Bool = false) {
        self.x = x
        self.y = isTopLeft ? 1 << z - 1 - y : y
        self.z = z
    }

    func toString() -> String {
        return "\(z)/\(x)/\(y)"
    }

    func toGoogle() -> TileKey {
        TileKey(x: x, y: y, z: z, isTopLeft: true)
    }
}
