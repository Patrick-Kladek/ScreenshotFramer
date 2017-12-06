//
//  ContentViewController.swift
//  FrameMe
//
//  Created by Patrick Kladek on 06.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

class ContentViewController: NSViewController {

    // MARK: - Properties

    var layerStateHistory: LayerStateHistory { return self.document.layerStateHistory }
    var lastLayerState: LayerState { return self.layerStateHistory.lastLayerState}
    var windowController: DocumentWindowController? { return self.view.window?.windowController as? DocumentWindowController }
    var inspectorViewController: InspectorViewController?
    var document: Document


    // MARK: - Interface Builder

    @IBOutlet var inspectorPlaceholder: NSView!
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var segmentedControl: NSSegmentedControl!
    @IBOutlet var tableView: NSTableView!


    // MARK: - Lifecycle

    init(document: Document) {
        self.document = document

        super.init(nibName: self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: - Overrides

    override var nibName: NSNib.Name? {
        return NSNib.Name(rawValue: String(describing: type(of: self)))
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func viewDidLoad() {
        let inspector = InspectorViewController(layerStateHistory: self.document.layerStateHistory, selectedRow: 0)
        self.addChildViewController(inspector)
        self.inspectorPlaceholder.addSubview(inspector.view)

        NSLayoutConstraint.activate([
            self.inspectorPlaceholder.topAnchor.constraint(equalTo: inspector.view.topAnchor, constant: 0),
            self.inspectorPlaceholder.leadingAnchor.constraint(equalTo: inspector.view.leadingAnchor, constant: 0),
            self.inspectorPlaceholder.trailingAnchor.constraint(equalTo: inspector.view.trailingAnchor, constant: 0),
        ])

        inspector.updateUI()
        self.inspectorViewController = inspector
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.becomeFirstResponder()
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
        self.document.addLayer(object)
    }

    func removeLayoutableObject() {
        let row = self.tableView.selectedRow
        if row < 0 { return }

        let object = self.document.layers[row]
        self.document.remove(object)
    }

    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(undo(_:)) {
            return self.layerStateHistory.canUndo
        }

        if menuItem.action == #selector(redo(_:)) {
            return self.layerStateHistory.canRedo
        }

        return super.validateMenuItem(menuItem)
    }

    @IBAction func undo(_ sender: AnyObject?) {
        self.layerStateHistory.undo()
    }

    @IBAction func redo(_ sender: AnyObject?) {
        self.layerStateHistory.redo()
    }
}


// MARK: - Table View Delegate

extension ContentViewController: NSTableViewDelegate, NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.document.layers.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let layer = self.document.layers[row]
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


// MARK: - Document Delegate

extension ContentViewController: DocumentDelegate {

    func document(_ document: Document, didUpdateLayers layers: [LayoutableObject]) {
        self.tableView.reloadData()
    }
}
