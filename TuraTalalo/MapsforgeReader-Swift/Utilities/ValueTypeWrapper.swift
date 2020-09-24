//
//  ValueTypeWrapper.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 24..
//

import Foundation

final class ValueTypeWrapper<S: Equatable> : Equatable {
    let value: S
    init(_ structValue: S) {
        self.value = structValue
    }

    static func ==(lhs: ValueTypeWrapper, rhs: ValueTypeWrapper) -> Bool {
        return lhs.value == rhs.value
    }
}
