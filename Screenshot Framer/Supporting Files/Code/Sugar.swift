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
