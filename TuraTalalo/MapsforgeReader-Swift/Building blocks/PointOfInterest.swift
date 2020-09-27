//
//  PointOfInterest.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 27..
//

import Foundation
import CoreGraphics

struct PointOfInterest : Hashable {
    var id = UUID()
    var latitude: CGFloat = CGFloat()
    var longitude: CGFloat = CGFloat()
    var tags: [String : String] = [String : String]()

    static func ==(lhs: PointOfInterest, rhs: PointOfInterest) -> Bool {
        if lhs.latitude != rhs.latitude { return false }
        if lhs.longitude != rhs.longitude { return false }

        for tag in Set(lhs.tags.keys).union(Set(rhs.tags.keys)) {
            if lhs.tags[tag] != rhs.tags[tag] { return false }
        }

        return true
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
