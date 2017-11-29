//
//  DocumentWindowController.swift
//  Framer
//
//  Created by Patrick Kladek on 28.11.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


final class DocumentWindowController: NSWindowController {

    override var windowNibName: NSNib.Name? {
        return NSNib.Name(rawValue: String(describing: type(of: self)))
    }
}


extension DocumentWindowController: NSTableViewDelegate, NSTableViewDataSource {

}
