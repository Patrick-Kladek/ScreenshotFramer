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

    var document: Document
    var layerStateHistory: LayerStateHistory { return self.document.layerStateHistory }
    var lastLayerState: LayerState { return self.layerStateHistory.currentLayerState}
    var windowController: DocumentWindowController? { return self.view.window?.windowController as? DocumentWindowController }
    var inspectorViewController: InspectorViewController?
    let viewStateController = ViewStateController()
    let layoutController: LayoutController
    var languageController: LanguageController


    // MARK: - Interface Builder

    @IBOutlet var inspectorPlaceholder: NSView!
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var segmentedControl: NSSegmentedControl!
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var addMenu: NSMenu!


    // MARK: - Lifecycle

    init(document: Document) {
        let languageController = LanguageController(document: document)

        self.document = document
        self.layoutController = LayoutController(document: self.document, layerStateHistory: document.layerStateHistory, viewStateController: self.viewStateController, languageController: languageController)
        self.languageController = languageController

        super.init(nibName: self.nibName, bundle: nil)

        self.viewStateController.delegate = self
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
        let inspector = InspectorViewController(layerStateHistory: self.document.layerStateHistory, selectedRow: 0, viewStateController: viewStateController, languageController: languageController)
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

        if self.document.fileURL == nil {
            self.document.save(self)
        }
    }


    // MARK: - Actions

    @IBAction func segmentClicked(sender: NSSegmentedControl) {
        guard sender == self.segmentedControl else { return }

        if sender.indexOfSelectedItem == 0 {
            self.showMenu(for: sender)
        } else {
            sender.setEnabled(false, forSegment: 1)
            self.removeLayoutableObject()
        }
    }

    @IBAction func addContent(_ sender: AnyObject?) {
        let operation = AddContentOperation(layerStateHistory: self.layerStateHistory)
        operation.apply()
    }

    @IBAction func addDevice(_ sender: AnyObject?) {
        let operation = AddDeviceOperation(layerStateHistory: self.layerStateHistory)
        operation.apply()
    }

    @IBAction func addText(_ sender: AnyObject?) {
        let operation = AddTextOperation(layerStateHistory: self.layerStateHistory)
        operation.apply()
    }

    @IBAction func toggleHighlightCurrentLayer(_ sender: AnyObject?) {
        if self.layoutController.highlightLayer <= 0 {
            self.layoutController.highlightLayer = self.tableView.selectedRow
        } else {
            self.layoutController.highlightLayer = -1
        }
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

        case #selector(ContentViewController.toggleHighlightCurrentLayer):
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

    func reloadLayout() {
        self.tableView.reloadDataKeepingSelection()
        self.scrollView.documentView = self.layoutController.layouthierarchy()
        self.updateEnabledStateOfControls()
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

        if self.layoutController.highlightLayer >= 0 {
            self.layoutController.highlightLayer = self.tableView.selectedRow
        }

        self.inspectorViewController?.updateUI()
    }
}


// MARK: - View State Delegate

extension ContentViewController: ViewStateControllerDelegate {

    func viewStateDidChange(_ viewState: ViewState) {
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

    func showMenu(for segmentedControl: NSSegmentedControl) {
        var menuLocation = segmentedControl.bounds.origin
        menuLocation.y += segmentedControl.bounds.size.height + 5.0
        self.addMenu.popUp(positioning: nil, at: menuLocation, in: segmentedControl)
    }
}
