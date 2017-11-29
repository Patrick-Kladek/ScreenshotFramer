//
//  LayoutableObject.swift
//  Framer
//
//  Created by Patrick Kladek on 28.11.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation


/// Model that holds all information about a rendered layer
struct LayoutableObject: Codable {

    var title: String
    var frame: CGRect
    var file: String
    var root: Bool = false


    // MARK: - Lifecycle

    init(title: String, frame: CGRect, file: String, root: Bool = false) {
        self.title = title
        self.frame = frame
        self.file = file
        self.root = root
    }


    // MARK: - Encoding/Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.title = try container.decode(String.self, forKey: .title)
        self.file = try container.decode(String.self, forKey: .file)
        self.root = try container.decode(Bool.self, forKey: .root)

        let frameString = try container.decode(String.self, forKey: .frame)
        self.frame = NSRectFromString(frameString)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.title, forKey: .title)
        try container.encode(self.file, forKey: .file)
        try container.encode(self.root, forKey: .root)

        let frameString = NSStringFromRect(self.frame)
        try container.encode(frameString, forKey: .frame)
    }
}

private extension LayoutableObject {

    private enum CodingKeys: String, CodingKey {
        case title = "title"
        case frame = "frame"
        case file = "file"
        case root = "isRoot"
    }
}
