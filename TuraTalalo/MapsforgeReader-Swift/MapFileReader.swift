//
//  MapFileReader.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 23..
//

import Foundation
import MapKit

final class MapFileReader {
    typealias CacheKey = (UInt32, UInt32, UInt8, MapFileReader)
    typealias CacheValue = TileData
    typealias SubFileInfo = MapFileInfo.SubFileInfo

    var mapFileInputSerializer: MapFileInputSerializer

    var mapFileInfo = MapFileInfo()
    var debugInformationIsPresent: Bool = false
    var pointOfInterestTags = [String]()
    var wayTags = [String]()
    var subFileInfos = [SubFileInfo]()

    init(fileUrl: URL) throws {
        self.mapFileInputSerializer = try! MapFileInputSerializer(fileUrl: fileUrl)
    }

    func open() {
        readHeader()
        readTileIndex()
    }

    func readHeader() {
        let magicBytesBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 20)
        defer { magicBytesBuffer.deallocate() }
        guard mapFileInputSerializer.read(numberOfBytes: 20) == 20 else { fatalError() }

        let magicBytesString = String(cString: magicBytesBuffer)
        guard magicBytesString == "mapsforge binary OSM" else { fatalError("Invalid header!") }

        _ = mapFileInputSerializer.readUInt32() //header length
        readMapInfo()
        readTagList(for: .pointsOfInterest)
        readTagList(for: .ways)
        readSubFileInfo()
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
        var tagArray = self[keyPath: tagType.correspondingTagListArrayKeyPath]
        let tagCount = mapFileInputSerializer.readUInt16()

        for _ in 0..<tagCount {
            tagArray.append(try! mapFileInputSerializer.readUTF8EncodedString())
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

            var tileYMin = Int32(), tileYMax = Int32()
            Transformation.tilesWithinBounds(mapFileInfo.minimumLongitude, mapFileInfo.minimumLongitude,
                                             mapFileInfo.maximumLatitude, mapFileInfo.maximumLongitude,
                                             UInt32(sfi.baseZoomLevel),
                                             &sfi.tileXMin, &tileYMin, &sfi.tileXMax, &tileYMax)

            sfi.tileYMax = (1 << sfi.baseZoomLevel) - tileYMin - 1
            sfi.tileYMin = (1 << sfi.baseZoomLevel) - tileYMax - 1

            subFileInfos.append(sfi)
        }
    }

    func readTileIndex() {
        for var subFileInfo in subFileInfos {
            mapFileInputSerializer.movePointer(toFileOffset: subFileInfo.offset)

            if debugInformationIsPresent {
                guard mapFileInputSerializer.read(numberOfBytes: 16) == 16 else { fatalError() }
            }

            let rows = subFileInfo.tileYMax - subFileInfo.tileYMin + 1
            let columns = subFileInfo.tileXMax - subFileInfo.tileXMin + 1
            let tileCount = rows * columns

            for _ in 0..<tileCount {
                let offset = mapFileInputSerializer.readOffset()
                subFileInfo.tileOffsets.append(offset)
            }
        }
    }

    func readTile(keyed key: TileKey, offset: Int) -> VectorTile {
        var queryBox = CGRect()
        Transformation.tileBounds(key.x, key.y, UInt32(key.z),
                                  &queryBox.origin.x, &queryBox.origin.y,
                                  &queryBox.size.width, &queryBox.size.height,
                                  0)

        let gtk = key.toGoogle()
        var zoom = min(mapFileInfo.maximumZoomLevel, gtk.z)
        zoom = max(mapFileInfo.minimumZoomLevel, zoom)

        guard let sfi = subFileInfos.first(where: { zoom >= $0.minimumZoomLevel && zoom <= $0.maximumZoomLevel }) else {
            fatalError("No subFileInfo object found matching the zoom criteria!")
        }

        let rows = sfi.tileYMax - sfi.tileYMin + 1
        let columns = sfi.tileXMax - sfi.tileXMin + 1
        let tileCount = rows * columns

        var useBitmask = false

        for tx in (Int(gtk.x) - offset)...(Int(gtk.x) + offset) {
            for ty in (Int(gtk.y) - offset)...(Int(gtk.y) + offset) {
                var blockMinX = Int32(), blockMinY = Int32(), blockMaxX = Int32(), blockMaxY = Int32()

                if gtk.z < sfi.baseZoomLevel {
                    //Left work here.
                }
            }
        }
    }
}

//MARK:- Tag Types
extension MapFileReader {
    enum TagType {
        case ways
        case pointsOfInterest

        var correspondingTagListArrayKeyPath: KeyPath<MapFileReader, [String]> {
            switch self {
                case .ways: return \.wayTags
                case .pointsOfInterest: return \.pointOfInterestTags
            }
        }
    }
}

//MARK:- POI, Way, BaseTile, VectorTile
extension MapFileReader {
    struct PointOfInterest {
        var latitude: Double
        var longitude: Double
    }

    struct Way {
        var coordinates: [[CLLocationCoordinate2D]]
        var tags: Dictionary<String, String>
        var labelPosition: CLLocationCoordinate2D?
        var layer: Int
        var isClosed: Bool
    }

    struct BaseTile {
        var key: TileKey
        var isSea: Bool = false
        var pointsOfInterest: [PointOfInterest]
        var ways: [Way]
    }

    struct VectorTile {
        var baseTiles: [BaseTile]
    }

    struct TileData {
        var x: UInt32
        var y: UInt32
        var z: UInt32
        var isSea: Bool
        var pointsOfInterestPerLevel: [[PointOfInterest]]
        var waysPerLevel: [[Way]]
    }
}
