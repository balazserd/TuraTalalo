//
//  MapFileReader.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 23..
//
//  Based on
//    https://github.com/mapsforge/mapsforge/blob/master/docs/Specification-Binary-Map-File.md#file-header
//    and
//    https://github.com/malasiot/maplite/blob/master/src/io/mapsforge_map_reader.cpp

import Foundation
import CoreGraphics

final class MapFileReader {
    typealias WrappedCacheKey = ValueTypeWrapper<CacheKey>
    typealias WrappedCacheValue = ValueTypeWrapper<TileData>
    typealias TileIndex = NSCache<WrappedCacheKey, WrappedCacheValue>
    typealias SubFileInfo = MapFileInfo.SubFileInfo

    var mapFileInputSerializer: MapFileInputSerializer
    var tileCache = TileIndex()

    let id = UUID()

    var mapFileInfo = MapFileInfo()
    var fileHeaderSize = UInt32()
    var debugInformationIsPresent: Bool = false
    var pointOfInterestTags = [String]()
    var wayTags = [String]()
    var subFileInfos = [SubFileInfo]()

    init(fileUrl: URL) {
        self.mapFileInputSerializer = try! MapFileInputSerializer(fileUrl: fileUrl)
    }

    func open() {
        readHeader()
        readTileIndex()
    }

    func initTileCache(withNumberOfBytes byteCount: Int) {
        tileCache.removeAllObjects()
        tileCache.totalCostLimit = byteCount
    }

    func readHeader() {
        //https://github.com/mapsforge/mapsforge/blob/master/docs/Specification-Binary-Map-File.md#file-header
        mapFileInputSerializer.skip(numberOfBytes: 20) //Magic bytes
        fileHeaderSize = mapFileInputSerializer.readUInt32() //header size
        readMapInfo()
        readTagList(for: .pointsOfInterest)
        readTagList(for: .ways)
        readSubFileInfo()
        if mapFileInputSerializer.currentPointerPosition() != fileHeaderSize + 20 + 4 {
            fatalError("Did not read all the header bytes!")
        }
    }

    func readMapInfo() {
        //https://github.com/mapsforge/mapsforge/blob/master/docs/Specification-Binary-Map-File.md#file-header

        mapFileInfo.version = mapFileInputSerializer.readUInt32()
        mapFileInfo.fileSize = mapFileInputSerializer.readUInt64()
        mapFileInfo.date = mapFileInputSerializer.readUInt64()

        mapFileInfo.minimumLatitude = CGFloat(mapFileInputSerializer.readInt32()) / 1_000_000
        mapFileInfo.minimumLongitude = CGFloat(mapFileInputSerializer.readInt32()) / 1_000_000
        mapFileInfo.maximumLatitude = CGFloat(mapFileInputSerializer.readInt32()) / 1_000_000
        mapFileInfo.maximumLongitude = CGFloat(mapFileInputSerializer.readInt32()) / 1_000_000

        mapFileInfo.tileSize = mapFileInputSerializer.readInt16()
        guard mapFileInfo.tileSize > 0 else { fatalError("Invalid tile size: \(mapFileInfo.tileSize)") }

        mapFileInfo.projection = try! mapFileInputSerializer.readUTF8EncodedString()
        mapFileInfo.flags = mapFileInputSerializer.readUInt8()

        debugInformationIsPresent = (mapFileInfo.flags & 0x80) != 0

        if mapFileInfo.flags & 0x40 != 0 {
            mapFileInfo.startLatitude = CGFloat(mapFileInputSerializer.readInt32()) / 1_000_000
            mapFileInfo.startLongitude = CGFloat(mapFileInputSerializer.readInt32()) / 1_000_000
        }

        if mapFileInfo.flags & 0x20 != 0 {
            mapFileInfo.startZoomLevel = mapFileInputSerializer.readUInt8()
        } else {
            mapFileInfo.startZoomLevel = 10
        }

        if mapFileInfo.flags & 0x10 != 0 {
            mapFileInfo.languagePreference = try! mapFileInputSerializer.readUTF8EncodedString()
        } else {
            mapFileInfo.languagePreference = "en"
        }

        if mapFileInfo.flags & 0x08 != 0 {
            mapFileInfo.comment = try! mapFileInputSerializer.readUTF8EncodedString()
        }

        if mapFileInfo.flags & 0x04 != 0 {
            mapFileInfo.createdBy = try! mapFileInputSerializer.readUTF8EncodedString()
        }
    }

    func readTagList(for tagType: TagType) {
        var tagArray = [String]()
        let tagCount = mapFileInputSerializer.readUInt16()

        for _ in 0..<tagCount {
            tagArray.append(try! mapFileInputSerializer.readUTF8EncodedString())
        }

        switch tagType {
            case .pointsOfInterest: self.pointOfInterestTags = tagArray
            case .ways: self.wayTags = tagArray
        }
    }

    func readSubFileInfo() {
        let zoomIntervalCount = Int(mapFileInputSerializer.readUInt8())

        mapFileInfo.minimumZoomLevel = UInt8.max
        mapFileInfo.maximumZoomLevel = UInt8.min

        for _ in 0..<zoomIntervalCount {
            var sfi = SubFileInfo()
            sfi.baseZoomLevel = mapFileInputSerializer.readUInt8()
            sfi.minimumZoomLevel = mapFileInputSerializer.readUInt8()
            sfi.maximumZoomLevel = mapFileInputSerializer.readUInt8()
            sfi.offset = mapFileInputSerializer.readUInt64()
            sfi.size = mapFileInputSerializer.readUInt64()

            mapFileInfo.minimumZoomLevel = min(mapFileInfo.minimumZoomLevel, sfi.minimumZoomLevel)
            mapFileInfo.maximumZoomLevel = max(mapFileInfo.maximumZoomLevel, sfi.maximumZoomLevel)

            var tileYMin = UInt32(), tileYMax = UInt32()
            Transformation.tilesWithinBounds(mapFileInfo.minimumLatitude, mapFileInfo.minimumLongitude,
                                             mapFileInfo.maximumLatitude, mapFileInfo.maximumLongitude,
                                             UInt32(sfi.baseZoomLevel),
                                             &sfi.tileXMin, &tileYMin, &sfi.tileXMax, &tileYMax)

            sfi.tileYMax = (1 << sfi.baseZoomLevel) - tileYMin - 1
            sfi.tileYMin = (1 << sfi.baseZoomLevel) - tileYMax - 1

            subFileInfos.append(sfi)
        }
    }

    func readTileIndex() {
        for i in 0..<subFileInfos.count {
            mapFileInputSerializer.movePointer(toFileOffset: subFileInfos[i].offset)

            if debugInformationIsPresent {
                mapFileInputSerializer.skip(numberOfBytes: 16)
            }

            let rows = subFileInfos[i].tileYMax - subFileInfos[i].tileYMin + 1
            let columns = subFileInfos[i].tileXMax - subFileInfos[i].tileXMin + 1
            let tileCount = rows * columns

            for _ in 0..<tileCount {
                // https://github.com/mapsforge/mapsforge/blob/master/docs/Specification-Binary-Map-File.md#tile-index-header
                let offset = mapFileInputSerializer.readOffset() //Tile index entry
                subFileInfos[i].tileOffsets.append(offset)
            }
        }
    }

    func readTile(keyed key: TileKey, offset: Int) -> VectorTile {
        var queryBox = CGRect()
        Transformation.tileBounds(key.x, key.y, UInt32(key.z), &queryBox, 0)

//        let gtk = key.toGoogle()
        let gtk = key
        var zoom = min(mapFileInfo.maximumZoomLevel, gtk.z)
        zoom = max(mapFileInfo.minimumZoomLevel, zoom)

        guard let sfi = subFileInfos.first(where: { zoom >= $0.minimumZoomLevel && zoom <= $0.maximumZoomLevel }) else {
            fatalError("No subFileInfo object found that matches the zoom criteria!")
        }

        var baseTileMinX = sfi.tileXMax, baseTileMinY = sfi.tileYMax
        var baseTileMaxX = sfi.tileXMin, baseTileMaxY = sfi.tileYMin

        let xRange = UInt32(max(Int(gtk.x) - offset, 0))...UInt32(Int(gtk.x) + offset)
        let yRange = UInt32(max(Int(gtk.y) - offset, 0))...UInt32(Int(gtk.y) + offset)
        for tx: UInt32 in xRange {
            for ty: UInt32 in yRange {
                var blockMinX = UInt32(), blockMinY = UInt32(), blockMaxX = UInt32(), blockMaxY = UInt32()

                if gtk.z < sfi.baseZoomLevel {
                    let zoomDiff = Int8(sfi.baseZoomLevel) - Int8(gtk.z)
                    blockMinX = tx << zoomDiff
                    blockMinY = ty << zoomDiff
                    blockMaxX = blockMinX + (1 << zoomDiff) - 1 //this tile has several subtiles.
                    blockMaxY = blockMinY + (1 << zoomDiff) - 1 //this tile has several subtiles.
                } else if gtk.z > sfi.baseZoomLevel {
                    let zoomDiff = Int8(gtk.z) - Int8(sfi.baseZoomLevel)
                    blockMinX = tx >> zoomDiff
                    blockMinY = ty >> zoomDiff
                    blockMaxX = blockMinX //this tile is in one parent tile.
                    blockMaxY = blockMinY //this tile is in one parent tile.
                } else {
                    //This is the very tile that we want to read.
                    blockMinX = tx
                    blockMinY = ty
                    blockMaxX = blockMinX
                    blockMaxY = blockMinY
                }

                baseTileMinX = min(baseTileMinX, blockMinX)
                baseTileMinY = min(baseTileMinY, blockMinY)
                baseTileMaxX = max(baseTileMaxX, blockMaxX)
                baseTileMaxY = max(baseTileMaxY, blockMaxY)
            }
        }

        var tile = VectorTile(baseTiles: [])
        for bty in baseTileMinY...baseTileMaxY {
            for btx in baseTileMinX...baseTileMaxX {
                //Check if this tile is outside of the subFileInfo's covered area.
                if bty < sfi.tileYMin || bty > sfi.tileYMax
                || btx < sfi.tileXMin || btx > sfi.tileXMax {
                    continue
                }

                var boundingBox = CGRect()
                let baseTileKey = TileKey(x: btx, y: bty, z: sfi.baseZoomLevel, isTopLeft: true)
                Transformation.tileBounds(baseTileKey.x, baseTileKey.y, UInt32(baseTileKey.z), &boundingBox, 0)

                let ignoreWays = boundingBox.intersects(queryBox)

                let row = bty - sfi.tileYMin
                let col = btx - sfi.tileXMin
                let columnCount = sfi.tileXMax - sfi.tileXMin + 1
                let tileIndex = Int(columnCount * row + col)
                var tileOffset = sfi.tileOffsets[tileIndex]

                let isSeaTile = tileOffset & 0x80_00_00_00 != 0
                tileOffset = tileOffset & 0x7f_ff_ff_ff

                var baseTile = BaseTile(key: TileKey(x: btx, y: bty, z: sfi.baseZoomLevel, isTopLeft: true),
                                        pointsOfInterest: [],
                                        ways: [])
                var tileData = TileData()
                let cacheKey = ValueTypeWrapper(CacheKey(x: btx, y: bty, z: sfi.baseZoomLevel, mapFileReader: self))

                if let wrappedTileData = tileCache.object(forKey: cacheKey) {
                    tileData = wrappedTileData.wrappedValue
                } else {
                    tileData = TileData(x: btx, y: bty, z: UInt32(sfi.baseZoomLevel), isSea: isSeaTile,
                                        pointsOfInterestPerLevel: [], waysPerLevel: [])
                    readTileData(subFileInfo: sfi, offset: tileOffset, data: &tileData)
                }

                for z in stride(from: zoom, through: sfi.minimumZoomLevel, by: -1) {
                    let index = z - sfi.minimumZoomLevel
                    baseTile.pointsOfInterest.append(contentsOf: tileData.pointsOfInterestPerLevel[Int(index)])
                    if !ignoreWays {
                        baseTile.ways.append(contentsOf: tileData.waysPerLevel[Int(index)])
                    }
                }

                if isSeaTile {
                    baseTile.isSea = true

                    var lBox = CGRect()
                    Transformation.tileLatLonBounds(baseTileKey.x, baseTileKey.y, UInt32(baseTileKey.z), &lBox)

                    var sea = Way()
                    sea.tags["natural"] = "sea"
                    sea.tags["area"] = "yes"
                    sea.tags["layer"] = "-5"
                    sea.layer = -5
                    sea.coordinates.append([])
                    sea.coordinates[0].append(CGPoint(x: lBox.minX, y: lBox.minY))
                    sea.coordinates[0].append(CGPoint(x: lBox.maxX, y: lBox.minY))
                    sea.coordinates[0].append(CGPoint(x: lBox.maxX, y: lBox.maxY))
                    sea.coordinates[0].append(CGPoint(x: lBox.minX, y: lBox.maxY))
                    sea.coordinates[0].append(CGPoint(x: lBox.minX, y: lBox.minY))

                    baseTile.ways.append(sea)
                }

                tile.baseTiles.append(baseTile)
            }
        }

        return tile
    }

    func readTileData(subFileInfo sfi: SubFileInfo, offset: Int64, data: inout TileData) {
        // https://github.com/mapsforge/mapsforge/blob/master/docs/Specification-Binary-Map-File.md#tile-header

        mapFileInputSerializer.movePointer(toFileOffset: sfi.offset + UInt64(offset))
        if debugInformationIsPresent {
            //Tile signature
            mapFileInputSerializer.skip(numberOfBytes: 32)
        }

        let zoomLevelCount = Int(sfi.maximumZoomLevel - sfi.minimumZoomLevel + 1)
        data.pointsOfInterestPerLevel = Array(repeating: [], count: zoomLevelCount)
        data.waysPerLevel = Array(repeating: [], count: zoomLevelCount)

        var numberOfPoisPerlevel = [UInt64](), numberOfWaysPerLevel = [UInt64]()
        var totalPois: UInt64 = 0, totalWays: UInt64 = 0

        for _ in 0..<zoomLevelCount {
            let poiCount = try! mapFileInputSerializer.readVarUInt64()
            let wayCount = try! mapFileInputSerializer.readVarUInt64()
            totalPois += poiCount
            totalWays += wayCount
            numberOfPoisPerlevel.append(poiCount)
            numberOfWaysPerLevel.append(wayCount)
        }

        let firstWayOffset = try! mapFileInputSerializer.readVarUInt64()
        let firstWayPosition = mapFileInputSerializer.currentPointerPosition() + firstWayOffset

        var latLonBounds = CGRect()
        Transformation.tileLatLonBounds(data.x, (1 << data.z) - data.y, data.z, &latLonBounds)

        //POIs
        for i in 0..<zoomLevelCount {
            for _ in 0..<Int(numberOfPoisPerlevel[i]) {
                let poi = readPointOfInterest(originalLatitude: latLonBounds.maxX,
                                              originalLongitude: latLonBounds.minY)
                data.pointsOfInterestPerLevel[i].append(poi)
            }
        }

        //Ways
        mapFileInputSerializer.movePointer(toFileOffset: firstWayPosition)
        for i in 0..<zoomLevelCount {
            for j in 0..<numberOfWaysPerLevel[i] {
                let ways = readWays(originalLatitude: latLonBounds.maxX, originalLongitude: latLonBounds.minY)
                data.waysPerLevel[i].append(contentsOf: ways)
                print(j)
            }
        }
    }

    func readPointOfInterest(originalLatitude: CGFloat, originalLongitude: CGFloat) -> PointOfInterest {
        // https://github.com/mapsforge/mapsforge/blob/master/docs/Specification-Binary-Map-File.md#poi-data

        if debugInformationIsPresent {
            mapFileInputSerializer.skip(numberOfBytes: 32) //POI signature
        }

        let latDiff = CGFloat(integerLiteral: Int(mapFileInputSerializer.readVarInt64()) / 1_000_000)
        let lonDiff = CGFloat(integerLiteral: Int(mapFileInputSerializer.readVarInt64()) / 1_000_000)

        var poi = PointOfInterest()
        poi.latitude = originalLatitude + latDiff
        poi.longitude = originalLongitude + lonDiff

        let specialByte = mapFileInputSerializer.readUInt8()
        let layer = Int8((specialByte & 0xf0) >> 4 - 5)
        let tagCount = specialByte & 0x0f

        for _ in 0..<tagCount {
            let tagId = try! mapFileInputSerializer.readVarUInt64()

            var tag = String(), value = String()
            Self.decodeKeyValue(codedKeyValue: pointOfInterestTags[Int(tagId)], key: &tag, value: &value)

            poi.tags[tag] = value
        }

        let flagsByte = mapFileInputSerializer.readUInt8()
        if flagsByte & 0x80 != 0 {
            poi.tags["name"] = try! mapFileInputSerializer.readUTF8EncodedString()
        }
        if flagsByte & 0x40 != 0 {
            poi.tags["addr:housenumber"] = try! mapFileInputSerializer.readUTF8EncodedString()
        }
        if flagsByte & 0x20 != 0 {
            poi.tags["ele"] = String(mapFileInputSerializer.readVarInt64())
        }

        if layer != 0 {
            poi.tags["layer"] = String(layer)
        }

        return poi
    }

    func readWays(originalLatitude: CGFloat, originalLongitude: CGFloat) -> [Way] {
        // https://github.com/mapsforge/mapsforge/blob/master/docs/Specification-Binary-Map-File.md#way-properties
        var ways = [Way]()

        if debugInformationIsPresent {
            mapFileInputSerializer.skip(numberOfBytes: 32) //Way signature
        }

        let dataSize = try! mapFileInputSerializer.readVarUInt64() //way data size
        let startingPointerPosition = mapFileInputSerializer.currentPointerPosition()

        print("way data size: \(dataSize) bytes")
        _ = mapFileInputSerializer.readUInt16() //subTile bitmap
        let specialByte = mapFileInputSerializer.readUInt8()
        let layer = Int8((specialByte & 0xf0) >> 4) - 5
        let tagCount = specialByte & 0x0f

        var tags = [String : String]()
        for _ in 0..<tagCount {
            let tagId = try! mapFileInputSerializer.readVarUInt64()

            var tag = String(), value = String()
            print(wayTags[Int(tagId)])
            Self.decodeKeyValue(codedKeyValue: wayTags[Int(tagId)], key: &tag, value: &value)

            tags[tag] = value
        }

        let flagsByte = mapFileInputSerializer.readUInt8()
        if flagsByte & 0x80 != 0 {
            tags["name"] = try! mapFileInputSerializer.readUTF8EncodedString()
        }
        if flagsByte & 0x40 != 0 {
            tags["addr:housenumber"] = try! mapFileInputSerializer.readUTF8EncodedString()
        }
        if flagsByte & 0x20 != 0 {
            tags["ref"] = try! mapFileInputSerializer.readUTF8EncodedString()
        }

        var labelPosition: CGPoint? = nil
        if flagsByte & 0x10 != 0 {
            let labelPosLatDiff = mapFileInputSerializer.readVarInt64() / 1_000_000
            let labelPosLonDiff = mapFileInputSerializer.readVarInt64() / 1_000_000
            labelPosition = CGPoint(x: CGFloat(labelPosLatDiff) + originalLatitude,
                                    y: CGFloat(labelPosLonDiff) + originalLongitude)
        }

        var dataBlockCount = 1
        if flagsByte & 0x08 != 0 {
            dataBlockCount = Int(try! mapFileInputSerializer.readVarUInt64())
        }

        for _ in 0..<dataBlockCount {
            var way = Way()
            way.tags = tags
            way.layer = layer
            way.labelPosition = labelPosition

            // https://github.com/mapsforge/mapsforge/blob/master/docs/Specification-Binary-Map-File.md#way-data

            let wayCoordBlockCount = try! mapFileInputSerializer.readVarUInt64()
            way.coordinates = Array(repeating: [], count: Int(wayCoordBlockCount))
            for i in 0..<wayCoordBlockCount {
                let wayNodeCount = try! mapFileInputSerializer.readVarUInt64()

                if flagsByte & 0x04 != 0 {
                    //Double-delta encoding
                    way.coordinates[Int(i)] = readWayNodesDoubleD(nodeCount: Int(wayNodeCount),
                                                                  tx0: originalLatitude, ty0: originalLongitude)
                } else {
                    //Single-delta encoding
                    way.coordinates[Int(i)] = readWayNodesSingleD(nodeCount: Int(wayNodeCount),
                                                                  tx0: originalLatitude, ty0: originalLongitude)
                }
            }

            let coords = way.coordinates[0]
            let latDiff = abs(coords.first!.x - coords.last!.x)
            let lonDiff = abs(coords.first!.y - coords.last!.y)
            way.isClosed = latDiff < 1e-5 && lonDiff < 1e-5

            ways.append(way)
        }

        guard startingPointerPosition + dataSize == mapFileInputSerializer.currentPointerPosition() else {
            fatalError("Did not read all bytes of the Way or read more bytes than needed for this Way!")
        }

        return ways
    }

    func readWayNodesDoubleD(nodeCount: Int, tx0: CGFloat, ty0: CGFloat) -> [CGPoint] {
        var lat = CGFloat(mapFileInputSerializer.readVarInt64()) / 1_000_000 + tx0
        var lon = CGFloat(mapFileInputSerializer.readVarInt64()) / 1_000_000 + ty0

        var coordList = [CGPoint]()
        coordList.append(CGPoint(x: lat, y: lon))

        var prevLatDelta = CGFloat(0), prevLonDelta = CGFloat(0)
        for _ in 1..<nodeCount {
            let latDelta = prevLatDelta + CGFloat(mapFileInputSerializer.readVarInt64()) / 1_000_000
            let lonDelta = prevLonDelta + CGFloat(mapFileInputSerializer.readVarInt64()) / 1_000_000

            lat += latDelta
            lon += lonDelta

            prevLatDelta = latDelta
            prevLonDelta = lonDelta

            coordList.append(CGPoint(x: lat, y: lon))
        }

        return coordList
    }

    func readWayNodesSingleD(nodeCount: Int, tx0: CGFloat, ty0: CGFloat) -> [CGPoint] {
        var lat = CGFloat(mapFileInputSerializer.readVarInt64()) / 1_000_000 + tx0
        var lon = CGFloat(mapFileInputSerializer.readVarInt64()) / 1_000_000 + ty0

        var coordList = [CGPoint]()
        coordList.append(CGPoint(x: lat, y: lon))

        for _ in 1..<nodeCount {
            lat += CGFloat(mapFileInputSerializer.readVarInt64()) / 1_000_000
            lon += CGFloat(mapFileInputSerializer.readVarInt64()) / 1_000_000

            coordList.append(CGPoint(x: lat, y: lon))
        }

        return coordList
    }

    static func decodeKeyValue(codedKeyValue: String, key: inout String, value: inout String) {
        //Assumes a "key=value" string.
        let codedKVComponents = codedKeyValue.components(separatedBy: "=")
        guard codedKVComponents.count == 2 else { fatalError("Found \(codedKVComponents.count) components instead of 2!") }

        key = codedKVComponents[0]
        value = codedKVComponents[1]
    }
}

//MARK:- Equatable conformance
extension MapFileReader : Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }

    static func ==(lhs: MapFileReader, rhs: MapFileReader) -> Bool {
        return lhs.id == rhs.id
    }
}

//MARK:- Tag Types
extension MapFileReader {
    enum TagType {
        case ways
        case pointsOfInterest
    }
}

//MARK:- POI, Way, BaseTile, VectorTile, TileData
extension MapFileReader {
    struct TileData : Hashable {
        var x: UInt32 = UInt32()
        var y: UInt32 = UInt32()
        var z: UInt32 = UInt32()
        var isSea: Bool = false
        var pointsOfInterestPerLevel: [[PointOfInterest]] = []
        var waysPerLevel: [[Way]] = []
    }

    struct CacheKey : Hashable {
        var x: UInt32
        var y: UInt32
        var z: UInt8
        var mapFileReader: MapFileReader
    }
}
