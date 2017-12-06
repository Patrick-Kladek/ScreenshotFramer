//
//  DebugWindowController.swift
//  FrameMe
//
//  Created by Patrick Kladek on 06.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

final class DebugWindowController: NSWindowController {

    @IBOutlet var tableView: NSTableView!
    private(set) var layerStateHistory: LayerStateHistory

    // MARK: - Overrides

    override var windowNibName: NSNib.Name? {
        return NSNib.Name(rawValue: String(describing: type(of: self)))
    }


    // MARK: Lifecycle

    init(layerStateHistory: LayerStateHistory) {
        self.layerStateHistory = layerStateHistory

        super.init(window: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(updateFromNotification(_:)), name: Constants.LayerStateHistoryDidChangeConstant, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Update

    @objc
    func updateFromNotification(_ notification: Notification) {
        self.tableView.reloadData()
    }
}

extension DebugWindowController: NSTableViewDelegate, NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.layerStateHistory.layerStates.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "layerStateCell"), owner: self) as? DetailTableCellView
        let state = self.layerStateHistory.layerStates[row]

        view?.textField?.stringValue = state.title
        view?.detailTextField.stringValue = "\(state.layers.count) Layer"

        return view
    }
}
