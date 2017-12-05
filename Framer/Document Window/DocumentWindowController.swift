//
//  DocumentWindowController.swift
//  Framer
//
//  Created by Patrick Kladek on 28.11.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


final class DocumentWindowController: NSWindowController {

    // MARK: - Interface Builder

    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var segmentedControl: NSSegmentedControl!
    @IBOutlet weak var inspectorPlaceholder: NSView!


    // MARK: - Properties

    var framerDocument: Document { return self.document as! Document }
    var inspectorViewController: InspectorViewController?

    // MARK: - Overrides

    override var windowNibName: NSNib.Name? {
        return NSNib.Name(rawValue: String(describing: type(of: self)))
    }

    override func windowDidLoad() {
        let inspector = InspectorViewController(layerStateHistory: self.framerDocument.layerStateHistory, selectedRow: 0)
        self.contentViewController?.addChildViewController(inspector)
        self.inspectorPlaceholder.addSubview(inspector.view)
        NSLayoutConstraint.activate([
            self.inspectorPlaceholder.topAnchor.constraint(equalTo: inspector.view.topAnchor, constant: 0),
            self.inspectorPlaceholder.leadingAnchor.constraint(equalTo: inspector.view.leadingAnchor, constant: 0),
            self.inspectorPlaceholder.trailingAnchor.constraint(equalTo: inspector.view.trailingAnchor, constant: 0)
        ])

        self.inspectorViewController = inspector
    }


    // MARK: - Actions

    @IBAction func segmentClicked(sender: NSSegmentedControl) {
        guard sender == self.segmentedControl else { return }

        if sender.indexOfSelectedItem == 0 {
            self.addLayoutableObject()
        } else {
            self.removeLayoutableObject()
        }
    }

    func addLayoutableObject() {
        let object = LayoutableObject()
        self.framerDocument.addLayer(object)
    }

    func removeLayoutableObject() {
        let row = self.tableView.selectedRow
        if row < 0 { return }

        let object = self.framerDocument.layers[row]
        self.framerDocument.remove(object)
    }
}


extension DocumentWindowController: DocumentDelegate {

    func document(_ document: Document, didUpdateLayers layers: [LayoutableObject]) {
        self.tableView?.reloadData()
    }
}

extension DocumentWindowController: NSTableViewDelegate, NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.framerDocument.layers.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let layer = self.framerDocument.layers[row]
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "layerCell"), owner: nil) as? NSTableCellView

        view?.textField?.stringValue = layer.title

        return view
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = self.tableView.selectedRow
        self.segmentedControl.setEnabled(selectedRow != 0, forSegment: 1)
        self.inspectorViewController?.selectedRow = selectedRow
    }
}
