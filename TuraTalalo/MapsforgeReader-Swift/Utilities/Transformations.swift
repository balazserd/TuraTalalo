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
    static let originalShift: CGFloat = 2 * .pi * 6_378_137 / 2
    //MARK:- LatLon x SphericalMercator
    class func latLonToMeters(_ lat: CGFloat, _ lon: CGFloat, _ mx: inout CGFloat, _ my: inout CGFloat) {
        mx = lon * originalShift / 180.0
        my = log(tan((90 + lat) * .pi / 360.0)) / (.pi / 180.0)
        my = my * originalShift / 180.0
    }

    class func metersToLatLon(_ mx: CGFloat, _ my: CGFloat, _ lat: inout CGFloat, _ lon: inout CGFloat) {
        lon = mx / originalShift * 180
        lat = my / originalShift * 180
        lat = 180.0 / .pi * (2 * atan(exp(lat * .pi / 180.0)) - .pi / 2)
    }
    //MARK:- Zooming related conversions
    class func resolution(zoom: UInt32) -> CGFloat {
        initialResolution / pow(2, CGFloat(zoom))
    }

    class func pixelsToMeters(_ px: CGFloat, _ py: CGFloat, _ zoom: UInt32, _ mx: inout CGFloat, _ my: inout CGFloat) {
        let res = resolution(zoom: zoom)
        mx = px * res - originalShift
        my = py * res - originalShift
    }

    class func metersToPixels(_ mx: CGFloat, _ my: CGFloat, _ zoom: UInt32, _ px: inout CGFloat, _ py: inout CGFloat) {
        let res = resolution(zoom: zoom)
        px = (mx + originalShift) / res
        py = (my + originalShift) / res
    }
    //MARK:- Tile related conversions and calculations
    class func pixelsToTile(_ px: CGFloat, _ py: CGFloat, _ tx: inout UInt32, _ ty: inout UInt32) {
        tx = UInt32(ceil(px / CGFloat(tileSize)) - 1)
        ty = UInt32(ceil(py / CGFloat(tileSize)) - 1)
    }

    class func tileToPixels(_ tx: UInt32, _ ty: UInt32, _ px: inout CGFloat, _ py: inout CGFloat) {
        px = CGFloat(tx) * tileSize
        py = CGFloat(ty) * tileSize
    }

    class func metersToTile(_ mx: CGFloat, _ my: CGFloat, _ zoom: UInt32, _ tx: inout UInt32, _ ty: inout UInt32) {
        var px = CGFloat(), py = CGFloat()
        metersToPixels(mx, my, zoom, &px, &py)
        pixelsToTile(px, py, &tx, &ty)
    }

    class func tileBounds(_ tx: UInt32, _ ty: UInt32, _ zoom: UInt32,
                          _ minX: inout CGFloat, _ minY: inout CGFloat, _ maxX: inout CGFloat, _ maxY: inout CGFloat,
                          _ buffer: UInt32) {
        pixelsToMeters(CGFloat(tx) * tileSize - CGFloat(buffer), CGFloat(ty) * tileSize - CGFloat(buffer),
                       zoom, &minX, &minY)
        pixelsToMeters(CGFloat(tx + 1) * tileSize + CGFloat(buffer), CGFloat(ty + 1) * tileSize + CGFloat(buffer),
                       zoom, &maxX, &maxY)
    }

    class func tileLatLonBounds(_ tx: UInt32, _ ty: UInt32, _ zoom: UInt32,
                                _ minLat: inout CGFloat, _ minLon: inout CGFloat, _ maxLat: inout CGFloat, _ maxLon: inout CGFloat) {
        var minX = CGFloat(), minY = CGFloat(), maxX = CGFloat(), maxY = CGFloat()
        tileBounds(tx, ty, zoom, &minX, &minY, &maxX, &maxY, 0)
        metersToLatLon(minX, minY, &minLat, &minLon)
        metersToLatLon(maxX, maxY, &maxLat, &maxLon)
    }

    class func tilesWithinBounds(_ minLat: CGFloat, _ minLon: CGFloat, _ maxLat: CGFloat, _ maxLon: CGFloat,
                                 _ zoom: UInt32,
                                 _ txMin: inout UInt32, _ tyMin: inout UInt32, _ txMax: inout UInt32, _ tyMax: inout UInt32) {
        var minX = CGFloat(), minY = CGFloat(), maxX = CGFloat(), maxY = CGFloat()
        latLonToMeters(minLat, minLon, &minX, &minY)
        latLonToMeters(maxLat, maxLon, &maxX, &maxY)
        metersToTile(minX, minY, zoom, &txMin, &tyMin)
        metersToTile(maxX, maxY, zoom, &txMax, &tyMax)
    }
}
