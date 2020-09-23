//
//  MapFileInfo.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 23..
//

import Foundation
import CoreGraphics

struct MapFileInfo {
    var version: UInt32 = UInt32()
    var fileSize: UInt64 = UInt64()
    var headerSize: UInt64 = UInt64()
    var date: UInt64 = UInt64()

    var minimumLatitude: CGFloat = CGFloat()
    var maximumLatitude: CGFloat = CGFloat()
    var minimumLongitude: CGFloat = CGFloat()
    var maximumLongitude: CGFloat = CGFloat()

    var startZoomLevel: UInt8 = UInt8()
    var startLatitude: CGFloat = CGFloat()
    var startLongitude: CGFloat = CGFloat()

    var tileSize: Int16 = Int16()

    var minimumZoomLevel: UInt8 = UInt8()
    var maximumZoomLevel: UInt8 = UInt8()

    var projection: String = String()
    var languagePreference: String = String()
    var comment: String = String()
    var createdBy: String = String()

    var flags: UInt8 = UInt8()

    struct SubFileInfo {
        var baseZoomLevel: UInt8 = UInt8()
        var minimumZoomLevel: UInt8 = UInt8()
        var maximumZoomLevel: UInt8 = UInt8()

        var offset: UInt64 = UInt64()
        var size: UInt64 = UInt64()

        var tileOffsets: [Int64] = [Int64]()
        var tileXMin: Int32 = Int32()
        var tileYMin: Int32 = Int32()
        var tileXMax: Int32 = Int32()
        var tileYMax: Int32 = Int32()
    }
}
