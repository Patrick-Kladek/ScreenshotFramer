//
//  NSTableView+keepSelection.swift
//  FrameMe
//
//  Created by Patrick Kladek on 12.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


extension NSTableView {

    func reloadDataKeepingSelection() {
        let selectedRowIndexes = self.selectedRowIndexes
        self.reloadData()
        self.selectRowIndexes(selectedRowIndexes, byExtendingSelection: false)
    }
}
