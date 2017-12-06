//
//  CenterClipView.swift
//  FrameMe
//
//  Created by Patrick Kladek on 06.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

final class CenterClipView: NSClipView {

    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {

        var rect = super.constrainBoundsRect(proposedBounds)
        if let containerView = self.documentView {

            if (rect.size.width > containerView.frame.size.width) {
                rect.origin.x = (containerView.frame.width - rect.width) / 2
            }

            if(rect.size.height > containerView.frame.size.height) {
                rect.origin.y = (containerView.frame.height - rect.height) / 2
            }
        }

        return rect
    }
}
