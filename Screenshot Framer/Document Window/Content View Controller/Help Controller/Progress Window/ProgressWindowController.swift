//
//  ProgressWindowController.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 18.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


protocol ProgressWindowControllerDelegate: AnyObject {
    func progressWindowControllerDidRequestCancel(_ windowController: ProgressWindowController)
}

class ProgressWindowController: NSWindowController {

    // MARK: - Properties
    weak var delegate: ProgressWindowControllerDelegate?
    var maxProgress: Double {
        get { return self.progressBar.maxValue }
        set { self.progressBar.maxValue = newValue }
    }

    var progress: Double {
        get { return self.progressBar.doubleValue }
        set { self.progressBar.doubleValue = newValue }
    }


    // MARK: - Interface Builder

    @IBOutlet private var progressBar: NSProgressIndicator!


    // MARK: - Overrides

    override var windowNibName: NSNib.Name? {
        return String(describing: type(of: self))
    }


    // MARK: - Actions

    @IBAction func cancelPressed(_ sender: AnyObject?) {
        self.delegate?.progressWindowControllerDidRequestCancel(self)
    }
}
