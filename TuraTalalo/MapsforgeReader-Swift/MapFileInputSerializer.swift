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
    private let _0x7fl: Int32 = 0x7f
    
    private var fileHandle: FileHandle

    init(fileUrl: URL) throws {
        let fh = try! FileHandle(forReadingFrom: fileUrl)
        fileHandle = fh
    }

    //MARK:- Stream handlers
    func closeStream() throws {
        try! fileHandle.close()
    }
    //MARK:- UInt readers
    func readUInt8() -> UInt8 {
        #if DEBUG
        printCurrentOffset()
        printAmountOfBytesThatShouldBeRead(byteCount: 1, forType: "UInt8")
        #endif

        guard let uInt8Data = try? fileHandle.read(upToCount: 1) else { fatalError() }
        let uInt8 = UInt8(bigEndian: uInt8Data.withUnsafeBytes { $0.load(as: UInt8.self) })

        #if DEBUG
        printCurrentOffset()
        #endif

        return uInt8
    }

    func readUInt16() -> UInt16 {
        #if DEBUG
        printCurrentOffset()
        printAmountOfBytesThatShouldBeRead(byteCount: 2, forType: "UInt16")
        #endif

        guard let uInt16Data = try? fileHandle.read(upToCount: 2) else { fatalError() }
        let uInt16 = UInt16(bigEndian: uInt16Data.withUnsafeBytes { $0.load(as: UInt16.self) })

        #if DEBUG
        printCurrentOffset()
        #endif

        return uInt16
    }

    func readUInt32() -> UInt32 {
        #if DEBUG
        printCurrentOffset()
        printAmountOfBytesThatShouldBeRead(byteCount: 4, forType: "UInt32")
        #endif

        guard let uInt32Data = try? fileHandle.read(upToCount: 4) else { fatalError() }
        let uInt32 = UInt32(bigEndian: uInt32Data.withUnsafeBytes { $0.load(as: UInt32.self) })

        #if DEBUG
        printCurrentOffset()
        #endif

        return uInt32
    }

    func readUInt64() -> UInt64 {
        #if DEBUG
        printCurrentOffset()
        printAmountOfBytesThatShouldBeRead(byteCount: 8, forType: "UInt64")
        #endif

        guard let uInt64Data = try? fileHandle.read(upToCount: 8) else { fatalError() }
        let uInt64 = UInt64(bigEndian: uInt64Data.withUnsafeBytes { $0.load(as: UInt64.self) })

        #if DEBUG
        printCurrentOffset()
        #endif

        return uInt64
    }

    //Variable byte encoded UnsignedInt64 reader
    func readVarUInt64() throws -> UInt64 {
        #if DEBUG
        printCurrentOffset()
        printAmountOfBytesThatShouldBeRead(byteCount: 0, forType: "VarUInt64")
        #endif

        var value: UInt64 = 0
        var shift: UInt = 0

        while true {
            guard let byteData = try? fileHandle.read(upToCount: 1) else { fatalError() }
            let byteValue = byteData.first!

            value |= (UInt64(byteValue) & _0x7full) << shift
            shift += 7

            if byteValue & 0x80 == 0 { break }
            if shift > 63 { throw Error.tooLongUInt64 }
        }

        #if DEBUG
        printCurrentOffset()
        #endif

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
        #if DEBUG
        printCurrentOffset()
        printAmountOfBytesThatShouldBeRead(byteCount: 0, forType: "VarInt64")
        #endif

        var value: Int64 = 0
        var shift: UInt = 0
        var byteValue: UInt8 = UInt8()

        while true {
            guard let byteData = try? fileHandle.read(upToCount: 1) else { fatalError() }
            byteValue = byteData.first!

            if byteValue & 0x80 == 0 { break } //0 at 128 means this is the last byte
            value |= Int64((UInt64(byteValue) & _0x7full) << shift)
            shift += 7
        }

        if byteValue & 0x40 != 0 { //0 at 64 means the number is positive, otherwise negative
            value = -(value | Int64(((UInt64(byteValue) & _0x3full) << shift)))
        } else {
            value |= Int64((UInt64(byteValue) & _0x3full) << shift)
        }

        #if DEBUG
        printCurrentOffset()
        #endif

        return value
    }
    //MARK:- String reader
    func readUTF8EncodedString() throws -> String {
        let length = Int(try! readVarUInt64())

        #if DEBUG
        printCurrentOffset()
        printAmountOfBytesThatShouldBeRead(byteCount: length, forType: "String")
        #endif

        guard let stringData = try? fileHandle.read(upToCount: length) else { fatalError() }
        guard let str = String(data: stringData, encoding: .utf8) else { fatalError() }

        #if DEBUG
        printCurrentOffset()
        #endif

        return str
    }
    func readOffset() -> Int64 {
        #if DEBUG
        printCurrentOffset()
        printAmountOfBytesThatShouldBeRead(byteCount: 5, forType: "CharArray[5]")
        #endif

        guard let charsData = try? fileHandle.read(upToCount: 5) else { fatalError() }
        var charArray = Array(repeating: UTF8Char(), count: 5)
        _  = charArray.withUnsafeMutableBytes { charsData.copyBytes(to: $0) }
        charArray = charArray.map { UTF8Char(bigEndian: $0) }

        let value =
            Int64((Int32(charArray[0]) & _0x7fl)) << 32
            | Int64((Int32(charArray[1]) & _0xffl)) << 24
            | Int64((Int32(charArray[2]) & _0xffl)) << 16
            | Int64((Int32(charArray[3]) & _0xffl)) << 8
            | Int64((Int32(charArray[4]) & _0xffl))

        #if DEBUG
        printCurrentOffset()
        #endif

        return value
    }
    //MARK:- Misc
    func skip(numberOfBytes n: Int) {
        #if DEBUG
        printCurrentOffset()
        printAmountOfBytesThatShouldBeRead(byteCount: n, forType: "Skippable bytes")
        #endif

        _ = try! fileHandle.read(upToCount: n)

        #if DEBUG
        printCurrentOffset()
        #endif
    }
    func movePointer(toFileOffset offset: UInt64) {
        try! fileHandle.seek(toOffset: offset)
    }
    func currentPointerPosition() -> UInt64 {
        try! fileHandle.offset()
    }
}

//MARK:- Error types
extension MapFileInputSerializer {
    enum Error : Swift.Error {
        case couldNotInitializeFileHandle
        case tooLongUInt64
    }
}


#if DEBUG
extension MapFileInputSerializer {
    func printCurrentOffset() {
        print("--- Current pointer position: \(try! fileHandle.offset())")
    }

    func printAmountOfBytesThatShouldBeRead(byteCount: Int, forType: String) {
        print("--- Supposed to read \(byteCount) byte - \(forType)")
    }
}
#endif
