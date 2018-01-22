//
//  MNCoalescing.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 15.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation


extension NSObject {

    func coalesceCalls(to selector: Selector, interval: TimeInterval, object: AnyObject? = nil) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.perform(selector, with: object, afterDelay: interval)
    }
}
