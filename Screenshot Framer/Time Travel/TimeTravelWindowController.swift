//
//  DebugWindowController.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 06.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

final class TimeTravelWindowController: NSWindowController {

    // MARK: - Properties

    @IBOutlet private var tableView: NSTableView?
    private(set) var layerStateHistory: LayerStateHistory


    // MARK: - Overrides

    override var windowNibName: NSNib.Name? {
        return NSNib.Name(rawValue: String(describing: type(of: self)))
    }

    override var document: AnyObject? {
        get { return nil }
        set {}
    }


    // MARK: Lifecycle

    init(layerStateHistory: LayerStateHistory) {
        self.layerStateHistory = layerStateHistory

        super.init(window: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(updateFromNotification(_:)), name: Constants.LayerStateHistoryDidChangeConstant, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillClose(notification:)), name: NSWindow.willCloseNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: - Update

    @objc func updateFromNotification(_ notification: Notification) {
        self.tableView?.reloadData()
        guard let numberOfRows = self.tableView?.numberOfRows else { return }

        if numberOfRows > 0 {
        	self.tableView?.scrollRowToVisible(numberOfRows - 1)
        }
    }

    @objc func windowWillClose(notification: Notification) {
        UserDefaults.standard.showTimeTravelWindow = false
    }
}


// MARK: - TableView Delegate

extension TimeTravelWindowController: NSTableViewDelegate, NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.layerStateHistory.layerStates.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "layerStateCell"), owner: self) as? DetailTableCellView
        let state = self.layerStateHistory.layerStates[row]

        view?.setLayerState(state)
        view?.setBackgroundColor(row == self.layerStateHistory.currentStackPosition ? NSColor.lightGray : NSColor.clear)

        return view
    }
}
