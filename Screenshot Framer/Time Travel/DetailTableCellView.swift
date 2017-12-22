//
//  DetailTableCellView.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 06.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

class DetailTableCellView: NSTableCellView {

    // MARK: - Interface Builder

    @IBOutlet private var detailTextField: NSTextField!


    // MARK: - Logic

    func setLayerState(_ state: LayerState) {
        self.textField?.stringValue = state.title
        self.detailTextField.stringValue = "\(state.layers.count) Layer"
    }

    func setBackgroundColor(_ color: NSColor) {
        self.wantsLayer = true
        self.layer?.backgroundColor = color.cgColor
    }
}
