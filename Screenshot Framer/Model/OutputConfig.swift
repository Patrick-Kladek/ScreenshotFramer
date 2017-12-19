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
