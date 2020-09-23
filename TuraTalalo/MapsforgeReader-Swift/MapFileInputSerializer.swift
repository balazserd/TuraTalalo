//
//  MapFileInputSerializer.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 22..
//
//  Based on
//    https://github.com/mapsforge/mapsforge/blob/master/docs/Specification-Binary-Map-File.md
//    and
//    https://github.com/malasiot/maplite/blob/master/src/io/serializer.cpp

import Foundation

final class MapFileInputSerializer {
    private let _0x7full: UInt64 = 0x7f
    private let _0x3full: UInt64 = 0x3f
    private let _0x3fll: Int64 = 0x3f
    private let _0xffl: Int32 = 0xff
    
    private var fileHandle: FileHandle

    init(fileUrl: URL) throws {
        guard let fh = try? FileHandle(forReadingFrom: fileUrl) else { throw Error.couldNotInitializeFileHandle}
        fileHandle = fh
    }

    //MARK:- Stream handlers
    func closeStream() throws {
        try! fileHandle.close()
    }
    //MARK:- UInt readers
    func readUInt8() -> UInt8 {
        guard let uInt8Data = try? fileHandle.read(upToCount: 1) else { fatalError() }
        let uInt8 = UInt8(bigEndian: uInt8Data.withUnsafeBytes { $0.load(as: UInt8.self) })

        return uInt8
    }

    func readUInt16() -> UInt16 {
        guard let uInt16Data = try? fileHandle.read(upToCount: 2) else { fatalError() }
        let uInt16 = UInt16(bigEndian: uInt16Data.withUnsafeBytes { $0.load(as: UInt16.self) })

        return uInt16
    }

    func readUInt32() -> UInt32 {
        guard let uInt32Data = try? fileHandle.read(upToCount: 4) else { fatalError() }
        let uInt32 = UInt32(bigEndian: uInt32Data.withUnsafeBytes { $0.load(as: UInt32.self) })

        return uInt32
    }

    func readUInt64() -> UInt64 {
        guard let uInt64Data = try? fileHandle.read(upToCount: 8) else { fatalError() }
        let uInt64 = UInt64(bigEndian: uInt64Data.withUnsafeBytes { $0.load(as: UInt64.self) })

        return uInt64
    }

    //Variable byte encoded UnsignedInt64 reader
    func readVarUInt64() throws -> UInt64 {
        var value: UInt64 = 0
        var shift: UInt = 0

        while true {
            guard let byteData = try? fileHandle.read(upToCount: 1) else { fatalError() }
            let byteValue = byteData.withUnsafeBytes { $0.load(as: UInt8.self) }

            value |= (UInt64(byteValue) & _0x7full) << shift
            shift += 7

            if byteValue & 0x80 == 0 { break }
            if shift > 63 { throw Error.tooLongUInt64 }
        }

        return value
    }
    //MARK:- Int readers
    func readInt8() -> Int8 {
        Int8(bitPattern: self.readUInt8())
    }

    func readInt16() -> Int16 {
        Int16(bitPattern: self.readUInt16())
    }

    func readInt32() -> Int32 {
        Int32(bitPattern: self.readUInt32())
    }

    func readInt64() -> Int64 {
        Int64(bitPattern: self.readUInt64())
    }

    //Variable byte encoded SignedInt64 reader
    func readVarInt64() -> Int64 {
        var value: Int64 = 0
        var shift: UInt = 0
        var byteValue: UInt8 = UInt8()

        while true {
            guard let byteData = try? fileHandle.read(upToCount: 1) else { fatalError() }
            byteValue = byteData.withUnsafeBytes { $0.load(as: UInt8.self) }

            if byteValue & 0x80 == 0 { break } //0 at 128 means this is the last byte
            value |= Int64((UInt64(byteValue) & _0x7full) << shift)
            shift += 7
        }

        if byteValue & 0x40 != 0 { //0 at 64 means the number is positive, otherwise negative
            value = -(value | Int64(((UInt64(byteValue) & _0x3full) << shift)))
        } else {
            value |= (Int64(byteValue) & _0x3fll) << shift
        }

        return value
    }
    //MARK:- String reader
    func readUTF8EncodedString() throws -> String {
        let length = Int(try! readVarUInt64())
        let stringBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        defer { stringBuffer.deallocate() }

        guard let stringData = try? fileHandle.read(upToCount: length) else { fatalError() }
        guard let str = String(data: stringData, encoding: .utf8) else { fatalError() }

        return str
    }
    func readOffset() -> Int64 {
        guard let charsData = try? fileHandle.read(upToCount: 5) else { fatalError() }
        let charArray = charsData.withUnsafeBytes { $0.load(as: [UTF8Char].self)}

        let value =
            Int64((Int32(charArray[0]) & _0xffl)) << 32
            | Int64((Int32(charArray[1]) & _0xffl)) << 24
            | Int64((Int32(charArray[2]) & _0xffl)) << 16
            | Int64((Int32(charArray[3]) & _0xffl)) << 8
            | Int64((Int32(charArray[4]) & _0xffl))

        return value
    }
    //MARK:- Misc
    func read(numberOfBytes n: Int) -> Int {
        guard let _ = try? fileHandle.read(upToCount: n) else { fatalError() }
        return n
    }
    func movePointer(toFileOffset offset: UInt64) {
        try! fileHandle.seek(toOffset: offset)
    }
}

//MARK:- Error types
extension MapFileInputSerializer {
    enum Error : Swift.Error {
        case couldNotInitializeFileHandle
        case tooLongUInt64
    }
}
