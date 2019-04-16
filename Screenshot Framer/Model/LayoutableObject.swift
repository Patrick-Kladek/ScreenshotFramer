//
//  LayoutableObject.swift
//  Framer
//
//  Created by Patrick Kladek on 28.11.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

enum LayoutableObjectType: String, Codable {
    case none
    case background
    case content
    case device
    case text
}

/// Model that holds all information about a rendered layer
struct LayoutableObject: Codable {

    // MARK: - Properties

    var type: LayoutableObjectType
    var title: String
    var frame: CGRect
    var rotation: CGFloat?
    var file: String
    var font: String?
    var fontSize: CGFloat?
    var color: NSColor?
    var textAlignment: NSTextAlignment?


    // MARK: - Lifecycle

    init(type: LayoutableObjectType, title: String = "Layer", frame: CGRect = .zero, rotation: CGFloat = 0, file: String = "") {
        self.type = type
        self.title = title
        self.frame = frame
        self.rotation = rotation
        self.file = file
    }


    // MARK: - Encoding/Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.type = try container.decode(LayoutableObjectType.self, forKey: .type)
        self.title = try container.decode(String.self, forKey: .title)
        self.file = try container.decode(String.self, forKey: .file)

        let frameString = try container.decode(String.self, forKey: .frame)
        self.frame = NSRectFromString(frameString)
        self.rotation = try container.decodeIfPresent(CGFloat.self, forKey: .rotation)

        self.font = try container.decodeIfPresent(String.self, forKey: .font)
        self.fontSize = try container.decodeIfPresent(CGFloat.self, forKey: .fontSize)

        if let colorHex = try container.decodeIfPresent(String.self, forKey: .color) {
            self.color = NSColor(hex: colorHex)
        }
        if let alignment = try container.decodeIfPresent(String.self, forKey: .textAlignment) {
            self.textAlignment = NSTextAlignment(string: alignment)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.type, forKey: .type)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.file, forKey: .file)

        let frameString = NSStringFromRect(self.frame)
        try container.encode(frameString, forKey: .frame)
        try container.encodeIfPresent(self.rotation, forKey: .rotation)

        try container.encodeIfPresent(self.font, forKey: .font)
        try container.encodeIfPresent(self.fontSize, forKey: .fontSize)
        try container.encodeIfPresent(self.color?.hexString(), forKey: .color)
        try container.encodeIfPresent(self.textAlignment?.stringRepresentation, forKey: .textAlignment)
    }
}


// MARK: - Equatable

extension LayoutableObject: Equatable {

    static func == (lhs: LayoutableObject, rhs: LayoutableObject) -> Bool {
        return  lhs.type == rhs.type && lhs.title == rhs.title && lhs.frame == rhs.frame
    }
}

private extension NSTextAlignment {

    var stringRepresentation: String {
        switch self {
        case .center:
            return "center"
        case .justified:
            return "justified"
        case .left:
            return "left"
        case .natural:
            return "natural"
        case .right:
            return "right"
        }
    }

    init(string: String) {
        switch string {
        case "left":
            self = .left
        case "right":
            self = .right
        case "justified":
            self = .justified
        case "natural":
            self = .natural
        default:
            self = .center
        }
    }
}


// MARK: - Private

private extension LayoutableObject {

    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case title = "title"
        case frame = "frame"
        case rotation = "rotation"
        case file = "file"
        case root = "isRoot"
        case font = "font"
        case fontSize = "fontSize"
        case color = "color"
        case textAlignment = "textAlignment"
    }
}
