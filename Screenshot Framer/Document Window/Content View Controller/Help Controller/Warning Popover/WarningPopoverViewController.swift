//
//  WarningPopover.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 07.01.18.
//  Copyright © 2018 Patrick Kladek. All rights reserved.
//

import Cocoa

class WarningPopoverViewController: NSViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overrides

    override var nibName: NSNib.Name? {
        return String(describing: type(of: self))
    }
}
