//
//  NSTableView+keepSelection.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 12.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


final class pkTableView: NSTableView {

    var isReloading = false

    func reloadDataKeepingSelection() {
        self.isReloading = true
        let selectedRowIndexes = self.selectedRowIndexes
        self.reloadData()
        self.isReloading = false

        self.selectRowIndexes(selectedRowIndexes, byExtendingSelection: false)
//        NotificationCenter.default.post(name: NSTableView.selectionDidChangeNotification, object: self)
    }
}
