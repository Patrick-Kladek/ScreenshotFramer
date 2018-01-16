//
//  NSColor+Hex.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 06.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


extension NSColor {

    /**
     *  init Color from HEX-String
     *  - parameter hex: 8 digit hex number with optional '#' as prefix
     *  - returns: NSColor with rgba value
     */
    convenience init?(hex: String) {
        var cString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        cString.cleanHexPrefix()

        var hexNumber: UInt32 = 0
        Scanner(string: cString).scanHexInt32(&hexNumber)

		self.init(red: CGFloat( (hexNumber & 0xFF000000) >> 24) / 255.0,
                  green: CGFloat( (hexNumber & 0x00FF0000) >> 16) / 255.0,
                  blue: CGFloat( (hexNumber & 0x0000FF00) >> 8) / 255.0,
                  alpha: CGFloat( (hexNumber & 0x000000FF) >> 0) / 255.0)
    }

    func hexString() -> String {
        guard let standardizedColor = self.usingColorSpace(.sRGB) else { return "" }
        let r = Int(standardizedColor.redComponent * 255.0)
        let g = Int(standardizedColor.greenComponent * 255.0)
        let b = Int(standardizedColor.blueComponent * 255.0)
        let a = Int(standardizedColor.alphaComponent * 255.0)

        return String(format: "#%02X%02X%02X%02X", r, g, b, a)
    }
}


private extension String {

    mutating func cleanHexPrefix() {
        if self.hasPrefix("#") {
            self.removeFirst()
        }
    }
}
