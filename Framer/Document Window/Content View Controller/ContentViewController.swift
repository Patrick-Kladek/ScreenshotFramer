//
//  ContentViewController.swift
//  FrameMe
//
//  Created by Patrick Kladek on 06.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

final class ContentViewController: NSViewController {

    // MARK: - Properties

    var layerStateHistory: LayerStateHistory { return self.document.layerStateHistory }
    var lastLayerState: LayerState { return self.layerStateHistory.currentLayerState}
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
        self.addMenuToSegmentedControl()

        self.reloadLayout()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.becomeFirstResponder()
    }


    // MARK: - Actions

    @IBAction func segmentClicked(sender: NSSegmentedControl) {
        guard sender == self.segmentedControl else { return }

        if sender.indexOfSelectedItem == 0 {
            sender.setEnabled(false, forSegment: 0)
            self.showMenu(for: sender)
        } else {
            sender.setEnabled(false, forSegment: 1)
            self.removeLayoutableObject()
        }
    }

    @objc
    func addContent() {
        let operation = AddContentOperation(layerStateHistory: self.layerStateHistory)
        operation.apply()
    }

    @objc
    func addDevice() {
        let operation = AddDeviceOperation(layerStateHistory: self.layerStateHistory)
        operation.apply()
    }

    @objc
    func addText() {
        let operation = AddTextOperation(layerStateHistory: self.layerStateHistory)
        operation.apply()
    }

    func removeLayoutableObject() {
        let operation = RemoveLayerOperation(layerStateHistory: self.layerStateHistory, indexOfLayer: self.tableView.selectedRow)
        operation.apply()
    }

    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let action = menuItem.action else { return false }

        switch action {
        case #selector(ContentViewController.undo):
            return self.layerStateHistory.canUndo
        case #selector(ContentViewController.redo):
            return self.layerStateHistory.canRedo

        case #selector(ContentViewController.addContent):
            return true
        case #selector(ContentViewController.addDevice):
            return true
        case #selector(ContentViewController.addText):
            return true

        default:
            return super.validateMenuItem(menuItem)
        }
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
        return self.lastLayerState.layers.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let layer = self.lastLayerState.layers[row]
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "layerCell"), owner: nil) as? NSTableCellView

        view?.textField?.stringValue = layer.title

        return view
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        self.updateEnabledStateOfControls()

        self.inspectorViewController?.updateUI()
    }
}


// MARK: - Document Delegate

extension ContentViewController: DocumentDelegate {

    func document(_ document: Document, didUpdateLayers layers: [LayoutableObject]) {
        self.reloadLayout()
    }
}


// MARK: - Private
private extension ContentViewController {

    func updateEnabledStateOfControls() {
        self.segmentedControl.setEnabled(true, forSegment: 0)
        self.segmentedControl.setEnabled(true, forSegment: 1)

        let selectedRow = self.tableView.selectedRow
        self.segmentedControl.setEnabled(selectedRow != 0, forSegment: 1)
        self.inspectorViewController?.selectedRow = selectedRow
    }

    func reloadLayout() {
        self.reloadTableViewKeepingSelection()
        self.scrollView.documentView = self.layouthierarchy()
        self.updateEnabledStateOfControls()
    }

    func reloadTableViewKeepingSelection() {
        let selectedRowIndexes = self.tableView.selectedRowIndexes
        self.tableView.reloadData()
        self.tableView.selectRowIndexes(selectedRowIndexes, byExtendingSelection: false)
    }

    func layouthierarchy() -> NSView? {
        let layoutableObjects = self.layerStateHistory.currentLayerState.layers
        guard layoutableObjects.count > 0 else { return nil }

        let firstLayoutableObject = layoutableObjects[0]
        let rootView: NSView

        if let absoluteURL = self.imageURL(for: firstLayoutableObject) {
            rootView = RenderedView(frame: firstLayoutableObject.frame, url: absoluteURL)
        } else {
            rootView = pkView(frame: firstLayoutableObject.frame)
            (rootView as! pkView).backgroundColor = NSColor.red
        }

        for object in layoutableObjects where object != layoutableObjects[0] {
            let view: NSView

            if let absoluteURL = self.imageURL(for: object) {
                view = RenderedView(frame: object.frame, url: absoluteURL)
            } else {
                view = pkView(frame: object.frame)
                (view as! pkView).backgroundColor = NSColor.blue
            }
            
            rootView.addSubview(view)
        }

        return rootView
    }

    func imageURL(for object: LayoutableObject) -> URL? {
        let documentUrl = self.document.fileURL
        let folderURL = documentUrl?.deletingLastPathComponent()
        let absoluteURL = folderURL?.appendingPathComponent(object.file)
        return absoluteURL
    }

    func addMenuToSegmentedControl() {
        let menu = NSMenu(title: "Add")
        menu.addItem(withTitle: "Add Content", action: #selector(addContent), keyEquivalent: "")
        menu.addItem(withTitle: "Add Device", action: #selector(addDevice), keyEquivalent: "")
        menu.addItem(withTitle: "Add Text", action: #selector(addText), keyEquivalent: "")

        self.segmentedControl.setMenu(menu, forSegment: 0)
        self.segmentedControl.setShowsMenuIndicator(true, forSegment: 0)
    }

    func showMenu(for segmentedControl: NSSegmentedControl) {
        let menu = segmentedControl.menu(forSegment: 0)!
        var menuLocation = segmentedControl.bounds.origin
        menuLocation.y += segmentedControl.bounds.size.height + 5.0
        menu.popUp(positioning: nil, at: menuLocation, in: segmentedControl)
    }
}
