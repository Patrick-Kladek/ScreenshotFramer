//
//  Sugar.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 22.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation


extension Collection {

    public var hasElements: Bool {
        return self.isEmpty == false
    }
}


extension Array where Element: Equatable {

    /**
     * Remove first collection element that is equal to the given `object`:
     */
    mutating func remove(object: Element) {
        if let index = firstIndex(of: object) {
            remove(at: index)
        }
    }
}


extension Array where Element == String {

    func subtracting(_ blacklist: Array, caseSensitive: Bool) -> Array {
        var newValues: [String] = []

        for element in self {
            if blacklist.contains(where: { (caseSensitive ? $0 : $0.lowercased()) == (caseSensitive ? element : element.lowercased()) }) == false {
                // No match in blacklist -> add item
                newValues.append(element)
            }
        }

        return newValues
    }
}
