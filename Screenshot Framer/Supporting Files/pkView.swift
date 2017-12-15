//
//  pkView.swift
//  Framer
//
//  Created by Patrick Kladek on 28.11.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


@IBDesignable
final class pkView: NSView {

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
//        self.lockFocus()
//        let rep = NSBitmapImageRep(focusedViewRect: self.bounds)
//        self.unlockFocus()
//        return rep?.representation(using: .png, properties: [:])

        guard let rep = self.bitmapImageRepForCachingDisplay(in: self.bounds) else { return nil }
        self.cacheDisplay(in: self.bounds, to: rep)
        return rep.representation(using: .png, properties: [:])


//        NSBitmapImageRep* rep = [self bitmapImageRepForCachingDisplayInRect:bounds];
//        [self cacheDisplayInRect:bounds toBitmapImageRep:rep];
//        NSData* data = [rep representationUsingType:NSJPEGFileType properties:nil];
//        [data writeToFile:@"/path/to/file.jpg" atomically:NO];
    }
}
