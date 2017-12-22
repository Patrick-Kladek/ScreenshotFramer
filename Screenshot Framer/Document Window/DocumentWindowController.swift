//
//  DocumentWindowController.swift
//  Framer
//
//  Created by Patrick Kladek on 28.11.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


final class DocumentWindowController: NSWindowController, NSWindowDelegate {

    // MARK: - Overrides

    override var windowNibName: NSNib.Name? {
        return NSNib.Name(rawValue: String(describing: type(of: self)))
    }

    override func windowDidLoad() {
        self.shouldCloseDocument = true

        // swiftlint:disable:next force_cast
        let contentViewController = ContentViewController(document: self.document as! Document)
        self.contentViewController = contentViewController
    }
}
