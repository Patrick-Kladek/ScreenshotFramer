//
//  VerticallyCenteredTextFieldCell.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 17.04.19.
//  Copyright © 2019 Patrick Kladek. All rights reserved.
//
// from: https://stackoverflow.com/a/39945456

import Cocoa


class VerticallyCenteredTextFieldCell: NSTextFieldCell {

    var verticallyCentered: Bool = false

    override func titleRect(forBounds rect: NSRect) -> NSRect {
       guard verticallyCentered else {
            return super.titleRect(forBounds: rect)
        }

        var titleRect = super.titleRect(forBounds: rect)
        let minimumHeight = self.cellSize(forBounds: rect).height
        titleRect.origin.y += (titleRect.height - minimumHeight) / 2
        titleRect.size.height = minimumHeight

        return titleRect
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: titleRect(forBounds: cellFrame), in: controlView)
    }
}
