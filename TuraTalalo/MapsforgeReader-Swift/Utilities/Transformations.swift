//
//  Transformation.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 23..
//
//  Based on https://github.com/malasiot/maplite/blob/master/src/util/tms.cpp

import Foundation
import MapKit

final class Transformation {
    //MARK:- Constants
    static let tileSize: CGFloat = 256
    static let initialResolution: CGFloat = 2 * .pi * 6_378_137 / tileSize
    static let originShift: CGFloat = 2 * .pi * 6_378_137 / 2
    //MARK:- LatLon x SphericalMercator
    class func latLonToMeters(_ lat: CGFloat, _ lon: CGFloat, _ mPoint: inout CGPoint) {
        let mx = lon * originShift / 180.0
        var my = log(tan((90 + lat) * .pi / 360.0)) / (.pi / 180.0)
        my = my * originShift / 180.0
        mPoint = CGPoint(x: mx, y: my)
    }

    class func metersToLatLon(_ mx: CGFloat, _ my: CGFloat, _ lat: inout CGFloat, _ lon: inout CGFloat) {
        lon = mx / originShift * 180
        lat = my / originShift * 180
        lat = 180.0 / .pi * (2 * atan(exp(lat * .pi / 180.0)) - .pi / 2)
    }
    //MARK:- Zooming related conversions
    class func resolution(zoom: UInt32) -> CGFloat {
        initialResolution / pow(2, CGFloat(zoom))
    }

    class func pixelsToMeters(_ px: CGFloat, _ py: CGFloat, _ zoom: UInt32, _ mPoint: inout CGPoint) {
        let res = resolution(zoom: zoom)
        let mx = px * res - originShift
        let my = py * res - originShift
        mPoint = CGPoint(x: mx, y: my)
    }

    class func metersToPixels(_ mPoint: CGPoint, _ zoom: UInt32, _ pPoint: inout CGPoint) {
        let res = resolution(zoom: zoom)
        let px = (mPoint.x + originShift) / res
        let py = (mPoint.y + originShift) / res
        pPoint = CGPoint(x: px, y: py)
    }
    //MARK:- Tile related conversions and calculations
    class func pixelsToTile(_ pPoint: CGPoint, _ tx: inout UInt32, _ ty: inout UInt32) {
        tx = UInt32(ceil(pPoint.x / CGFloat(tileSize)) - 1)
        ty = UInt32(ceil(pPoint.y / CGFloat(tileSize)) - 1)
    }

    class func tileToPixels(_ tx: UInt32, _ ty: UInt32, _ pPoint: inout CGPoint) {
        let px = CGFloat(tx) * tileSize
        let py = CGFloat(ty) * tileSize
        pPoint = CGPoint(x: px, y: py)
    }

    class func metersToTile(_ mPoint: CGPoint, _ zoom: UInt32, _ tx: inout UInt32, _ ty: inout UInt32) {
        var pPoint = CGPoint()
        metersToPixels(mPoint, zoom, &pPoint)
        pixelsToTile(pPoint, &tx, &ty)
    }

    class func tileBounds(_ tx: UInt32, _ ty: UInt32, _ zoom: UInt32, _ bounds: inout CGRect, _ buffer: UInt32) {
        var topLeftPoint = CGPoint(), bottomRightPoint = CGPoint()
        pixelsToMeters(CGFloat(tx) * tileSize - CGFloat(buffer), CGFloat(ty) * tileSize - CGFloat(buffer),
                       zoom, &topLeftPoint)
        pixelsToMeters(CGFloat(tx + 1) * tileSize + CGFloat(buffer), CGFloat(ty + 1) * tileSize + CGFloat(buffer),
                       zoom, &bottomRightPoint)

        bounds = CGRect(x: topLeftPoint.x, y: topLeftPoint.y,
                        width: bottomRightPoint.x - topLeftPoint.x, height: bottomRightPoint.y - topLeftPoint.y)
    }

    class func tileLatLonBounds(_ tx: UInt32, _ ty: UInt32, _ zoom: UInt32, _ latLonBounds: inout CGRect) {
        var bounds = CGRect(), minLat = CGFloat(), minLon = CGFloat(), maxLat = CGFloat(), maxLon = CGFloat()
        tileBounds(tx, ty, zoom, &bounds, 0)
        metersToLatLon(bounds.minX, bounds.minY, &minLat, &minLon)
        metersToLatLon(bounds.maxX, bounds.maxY, &maxLat, &maxLon)
        latLonBounds = CGRect(x: minLat, y: minLon,
                              width: maxLat - minLat, height: maxLon - minLon)
    }

    class func tilesWithinBounds(_ minLat: CGFloat, _ minLon: CGFloat, _ maxLat: CGFloat, _ maxLon: CGFloat,
                                 _ zoom: UInt32,
                                 _ txMin: inout UInt32, _ tyMin: inout UInt32, _ txMax: inout UInt32, _ tyMax: inout UInt32) {
        var minPoint = CGPoint(), maxPoint = CGPoint()
        latLonToMeters(minLat, minLon, &minPoint)
        latLonToMeters(maxLat, maxLon, &maxPoint)
        metersToTile(minPoint, zoom, &txMin, &tyMin)
        metersToTile(maxPoint, zoom, &txMax, &tyMax)
    }
}
