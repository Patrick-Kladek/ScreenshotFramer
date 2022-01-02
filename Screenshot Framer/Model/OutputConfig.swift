//
//  OutputConfig.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 19.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation


struct OutputConfig: Codable {

    // MARK: - Properties

    let output: String
    let fromImageNumber: Int
    let toImageNumber: Int
}

extension OutputConfig {

    func prefered(from: Int?) -> Int? {
        guard let from = from else { return nil }

        if from >= self.fromImageNumber && from <= self.toImageNumber {
            return from
        }

        return nil
    }

    func prefered(end: Int?) -> Int? {
        guard let end = end else { return nil }

        if end >= self.fromImageNumber && end <= self.toImageNumber {
            return end
        }
        return nil
    }
}
