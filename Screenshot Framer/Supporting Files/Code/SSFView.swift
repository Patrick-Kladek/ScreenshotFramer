//
//  SSFView.swift
//  Framer
//
//  Created by Patrick Kladek on 28.11.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


@IBDesignable
final class SSFView: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        self.wantsLayer = true
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)

        self.wantsLayer = true
    }


    override var wantsUpdateLayer: Bool {
        return true
    }

    override func updateLayer() {
        guard let color = self.backgroundColor else { return }

        self.layer?.backgroundColor = color.cgColor
    }


    @IBInspectable var backgroundColor: NSColor? {
        didSet {
            self.needsDisplay = true
        }
    }
}


extension NSView {

    func pngData() -> Data? {
        let imageSize = self.bounds.size
        guard let rep = self.bitmapImageRepForCachingDisplay(in: self.bounds) else { return nil }

        rep.size = imageSize
        rep.pixelsHigh = Int(imageSize.height)
        rep.pixelsWide = Int(imageSize.width)
        rep.hasAlpha = false
        self.cacheDisplay(in: self.bounds, to: rep)
        return rep.representation(using: .png, properties: [:])
    }
}

extension NSView {
    var snapshot: NSImage {
        guard let bitmapRep = self.bitmapImageRepForCachingDisplay(in: bounds) else { return NSImage() }
        bitmapRep.size = self.frame.size
        self.cacheDisplay(in: bounds, to: bitmapRep)
        let image = NSImage(size: bounds.size)
        image.addRepresentation(bitmapRep)
        return image
    }

    func imageData() -> Data? {
        return self.snapshot.tiffRepresentation
    }
}
