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

    func renderTile(keyed key: TileKey, in graphicsRenderer: UIGraphicsImageRenderer, tile: VectorTile, layerId: String?, queryBuffer: Int) throws -> UIImage {
        let targetRect = graphicsRenderer.format.bounds

        var boundingBox = CGRect()
        Transformation.tileLatLonBounds(key.x, key.y, UInt32(key.z), &boundingBox)

        var zoom = key.z
        var targetExtentsTopLeftPoint = CGPoint(), targetExtentsBottomRightPoint = CGPoint()
        Transformation.latLonToMeters(boundingBox.minY, boundingBox.minX, &targetExtentsTopLeftPoint)
        Transformation.latLonToMeters(boundingBox.maxY, boundingBox.maxX, &targetExtentsBottomRightPoint)
        let targetExtents = CGRect(topLeft: targetExtentsTopLeftPoint, bottomRight: targetExtentsBottomRightPoint)
        
//        let scale = targetExtents.width / targetRect.width
        let scale = targetExtents.height / targetRect.height //TODO account for orientation! - whichever is smaller, should be the base for scale
        let extraWidth = ((2 * CGFloat(queryBuffer) + targetRect.width) * scale - targetExtents.width) / 2
        let extraHeight = ((2 * CGFloat(queryBuffer) + targetRect.height) * scale - targetExtents.height) / 2

        var queryExtents = targetExtents.insetBy(dx: 2 * extraWidth, dy: 2 * extraHeight)

        let renderingTransformation = CGAffineTransform.identity
            .scaledBy(x: 1 / scale, y: 1 / scale)
            .translatedBy(x: -targetExtents.minX, y: -targetExtents.minY)

        let image = graphicsRenderer.image { uiGraphicsContext in
            let cgContext = uiGraphicsContext.cgContext
            let mapRenderingContext = MapRenderingContext(underlyingGraphicsContext: cgContext,
                                                          scale: scale,
                                                          transformationMatrix: renderingTransformation)

            cgContext.setFillColor(self.theme.mapBackground ?? UIColor.blue.cgColor)
            cgContext.fill(targetExtents)

            //Bounding Rectangle
            cgContext.withNewSavedState {
                cgContext.concatenate(renderingTransformation)
                cgContext.setStrokeColor(UIColor.black.cgColor)
                cgContext.setLineWidth(2 / cgContext.userSpaceToDeviceSpaceTransform.a)
                cgContext.addRect(targetExtents)
                cgContext.drawPath(using: .stroke)
            }

            //Ways
            for baseTile in tile.baseTiles { //TODO middle tile never has ways!
                cgContext.withNewSavedState {
                    var tileExtents = CGRect()
                    Transformation.tileBounds(baseTile.key.x, baseTile.key.y, UInt32(baseTile.key.z), &tileExtents, 0)

                    cgContext.withNewSavedState {
                        cgContext.concatenate(renderingTransformation)
                        cgContext.setStrokeColor(UIColor.gray.cgColor)
                        cgContext.setLineWidth(1 / cgContext.userSpaceToDeviceSpaceTransform.a)
                        cgContext.stroke(tileExtents)
                        cgContext.addRect(tileExtents)
                    }

                    cgContext.clip()

                    let instructions = self.getFilteredWayInstructions(layer: layerId, zoom: zoom, ways: baseTile.ways)
                    for wi in instructions {
                        let renderingInstruction = wi.renderingInstruction
                        let coordinates = wi.coordinates

                        if renderingInstruction.type == .area { self.drawArea(in: mapRenderingContext, pointArrays: coordinates, instruction: renderingInstruction) }
                        if renderingInstruction.type == .line { self.drawLine(in: mapRenderingContext, pointArrays: coordinates, instruction: renderingInstruction) }
                    }
                }
            }
        }

        return image
    }

    func drawArea(in mapRenderingContext: MapRenderingContext, pointArrays: [[CGPoint]], instruction: RenderingInstruction) {
        let context = mapRenderingContext.underlyingGraphicsContext

        context.withNewSavedState {
            context.withNewSavedState {
                context.concatenate(mapRenderingContext.transformationMatrix)

                self.addPaths(in: context, by: pointArrays, shouldClose: true)
            }

            if instruction.sourceFileName == nil {
                let borderStrokeWidth = instruction.scale != RenderingInstruction.Scale.none
                    ? instruction.strokeWidth! * mapRenderingContext.scale
                    : instruction.strokeWidth!
                context.setLineWidth(borderStrokeWidth)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                context.setLineDash(phase: 0, lengths: [])
                context.setStrokeColor(instruction.stroke!)
                context.setFillColor(instruction.fill!)
                context.drawPath(using: .fillStroke)
            } else {
                fatalError()
            }
        }
    }

    func drawLine(in mapRenderingContext: MapRenderingContext, pointArrays: [[CGPoint]], instruction: RenderingInstruction) {
        let context = mapRenderingContext.underlyingGraphicsContext

        context.withNewSavedState {
            if instruction.sourceFileName == nil {
                context.withNewSavedState {
                    context.concatenate(mapRenderingContext.transformationMatrix)
                    let offsetVector = CGPoint(x: instruction.dy ?? 0, y: instruction.dy ?? 0)
                    context.convertToUserSpace(offsetVector)

                    let offsetTransformation = CGAffineTransform.identity
                        .translatedBy(x: offsetVector.x, y: offsetVector.y)

                    if instruction.dy == nil || instruction.dy == 0 {
                        self.addPaths(in: context, by: pointArrays, shouldClose: false)
                    } else {
                        let offsetPointArrays = pointArrays.map { cgPointArray in
                            cgPointArray.map { cgPoint in
                                cgPoint.applying(offsetTransformation)
                            }
                        }

                        self.addPaths(in: context, by: offsetPointArrays, shouldClose: false)
                    }
                }

                let lineStrokeWidth = instruction.scale != RenderingInstruction.Scale.none
                    ? instruction.strokeWidth! / mapRenderingContext.scale
                    : instruction.strokeWidth!

                context.setLineWidth(lineStrokeWidth)
                context.setLineCap(instruction.strokeLineCap ?? .round)
                context.setLineJoin(instruction.strokeLineJoin ?? .round)
                context.setLineDash(phase: 0, lengths: instruction.strokeDashArray ?? [])
                context.setStrokeColor(instruction.stroke!)
                context.drawPath(using: .stroke)
            } else {
                fatalError()
            }
        }
    }

    func addPaths(in context: CGContext, by pointArrays: [[CGPoint]], shouldClose: Bool) {
        for pathPoints in pointArrays {
            context.beginPath()
            let path = CGMutablePath()
            path.addLines(between: pathPoints.map { CGPoint(x: $0.x, y: $0.y - 39135) }) //TODO why??

            if shouldClose {
                path.closeSubpath()
            }

            context.addPath(path)
        }
    }

    func getFilteredWayInstructions(layer: String?, zoom: UInt8, ways: [Way]) -> [WayInstruction] {
        var wayInstructions = [WayInstruction]()

        for i in 0..<ways.count {
            let way = ways[i]
            var renderingInstructions = [RenderingInstruction]()

            if self.theme.match(layerId: layer,
                                tags: way.tags,
                                zoom: zoom,
                                isClosed: way.isClosed,
                                isWay: true,
                                renderingInstructionsOut: &renderingInstructions) {
                let coords: [[CGPoint]] = way.coordinates.map { cgPointArray in
                    cgPointArray.map { latLonCGPointIn in
                        var metersCGPointOut = CGPoint()
                        Transformation.latLonToMeters(latLonCGPointIn.y, latLonCGPointIn.x, &metersCGPointOut)
                        return metersCGPointOut
                    }
                }

                for ri in renderingInstructions {
                    if [.area, .line].contains(ri.type) {
                        wayInstructions.append(WayInstruction(coordinates: coords,
                                                              renderingInstruction: ri,
                                                              index: i,
                                                              zOrder: Int(ri.zOrder ?? 0)))
                    }
                }
            }
        }

        wayInstructions.sort(by: {
            if $0.zOrder == $1.zOrder { return ways[$0.index].layer < ways[$1.index].layer }

            return $0.zOrder < $1.zOrder
        })

        return wayInstructions
    }
}

extension MapRenderer {
    class MapRenderingContext {
        var underlyingGraphicsContext: CGContext
        var scale: CGFloat
        var transformationMatrix: CGAffineTransform

        internal init(underlyingGraphicsContext: CGContext, scale: CGFloat, transformationMatrix: CGAffineTransform) {
            self.underlyingGraphicsContext = underlyingGraphicsContext
            self.scale = scale
            self.transformationMatrix = transformationMatrix
        }
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
