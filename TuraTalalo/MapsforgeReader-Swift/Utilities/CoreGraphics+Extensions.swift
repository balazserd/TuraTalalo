//
//  CoreGraphics+Extensions.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 27..
//

import Foundation
import CoreGraphics

extension CGRect {
    init(topLeft: CGPoint, bottomRight: CGPoint) {
        self = CGRect(x: topLeft.x, y: topLeft.y,
                      width: bottomRight.x - topLeft.x, height: bottomRight.y - topLeft.y)
    }
}

extension CGContext {
    func withNewSavedState(action: () -> ()) {
        self.saveGState()
        action()
        self.restoreGState()
    }
}
