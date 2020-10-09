//
//  MapRenderer.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 27..
//

import Foundation
import CoreGraphics
import UIKit

final class MapRenderer {
    var theme: RenderTheme
    var preferredLanguage: String

    init(theme: RenderTheme, preferredLanguage: String, debug: Bool = false) {
        self.theme = theme
        self.preferredLanguage = preferredLanguage
    }

    func renderTile(keyed key: TileKey, in graphicsRenderer: UIGraphicsImageRenderer, tile: VectorTile, layerId: String, queryBuffer: Int) throws -> UIImage {
        let targetRect = graphicsRenderer.format.bounds

        var boundingBox = CGRect()
        Transformation.tileLatLonBounds(key.x, key.y, UInt32(key.z), &boundingBox)

        var zoom = key.z
        var targetExtentsTopLeftPoint = CGPoint(), targetExtentsBottomRightPoint = CGPoint()
        Transformation.latLonToMeters(boundingBox.minY, boundingBox.minX, &targetExtentsTopLeftPoint)
        Transformation.latLonToMeters(boundingBox.maxY, boundingBox.maxX, &targetExtentsBottomRightPoint)
        let targetExtents = CGRect(topLeft: targetExtentsTopLeftPoint, bottomRight: targetExtentsBottomRightPoint)
        
//        let scale = targetExtents.width / targetRect.width
        let scale = targetExtents.height / targetRect.height
        let extraWidth = ((2 * CGFloat(queryBuffer) + targetRect.width) * scale - targetExtents.width) / 2
        let extraHeight = ((2 * CGFloat(queryBuffer) + targetRect.height) * scale - targetExtents.height) / 2

        var queryExtents = targetExtents.insetBy(dx: 2 * extraWidth, dy: 2 * extraHeight)

        let renderingTransformation = CGAffineTransform.identity
            .scaledBy(x: 1 / scale, y: 1 / scale)
            .translatedBy(x: -targetExtents.minX, y: -targetExtents.minY)

        let image = graphicsRenderer.image { uiGraphicsContext in
            let cgContext = uiGraphicsContext.cgContext

            cgContext.setFillColor(self.theme.mapBackground ?? UIColor.blue.cgColor)
            cgContext.fill(graphicsRenderer.format.bounds)

            cgContext.saveGState()

            cgContext.concatenate(renderingTransformation)
            cgContext.setStrokeColor(UIColor.black.cgColor)
            cgContext.setLineWidth(2 / cgContext.userSpaceToDeviceSpaceTransform.a)
            cgContext.stroke(targetExtents)

            cgContext.restoreGState()
        }

        return image
    }
}

extension MapRenderer {
    struct PointOfInterestInstruction {
        var x: CGFloat
        var y: CGFloat
        var angle: CGFloat
        var renderingInstruction: RenderingInstruction
        var index: Int = -1
        var itemIndex: Int = 0
        var label: String? = nil
    }
    
    struct WayInstruction {
        var coordinates: [[CGPoint]]
        var renderingInstruction: RenderingInstruction
        var index: Int
        var zOrder: Int
    }
}
