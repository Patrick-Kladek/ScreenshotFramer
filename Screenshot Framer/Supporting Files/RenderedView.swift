//
//  RenderedView.swift
//  FrameMe
//
//  Created by Patrick Kladek on 11.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


final class RenderedView: NSView {

    let url: URL
    lazy var image = NSImage(contentsOf: self.url)


    init(frame frameRect: NSRect, url: URL) {
        self.url = url
        super.init(frame: frameRect)
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        self.image?.draw(in: self.bounds)
    }
}
