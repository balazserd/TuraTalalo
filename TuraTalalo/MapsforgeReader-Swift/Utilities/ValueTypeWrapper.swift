//
//  ValueTypeWrapper.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 24..
//

import Foundation

final class ValueTypeWrapper<S: Hashable> : NSObject {
    let wrappedValue: S
    init(_ structValue: S) {
        self.wrappedValue = structValue
    }

    override var hash: Int { wrappedValue.hashValue }

    override func isEqual(_ object: Any?) -> Bool {
        guard let otherValueTypeWrapper = object as? ValueTypeWrapper<S> else { return false }
        return self.wrappedValue == otherValueTypeWrapper.wrappedValue
    }
}
