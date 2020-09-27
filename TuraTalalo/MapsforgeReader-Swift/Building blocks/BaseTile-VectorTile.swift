//
//  BaseTile-VectorTile.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 27..
//

import Foundation
import CoreGraphics

struct BaseTile {
    var key: TileKey
    var isSea: Bool = false
    var pointsOfInterest: [PointOfInterest]
    var ways: [Way]
}

struct VectorTile {
    var baseTiles: [BaseTile]
}
