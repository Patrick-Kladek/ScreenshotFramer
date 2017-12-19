//
//  ContentViewController.swift
//  Screenshot Framer
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
    var fileController: FileController
    let exportController: ExportController
    var progressWindowController: ProgressWindowController?


    // MARK: - Interface Builder

    @IBOutlet var inspectorPlaceholder: NSView!
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var segmentedControl: NSSegmentedControl!
    @IBOutlet var tableView: pkTableView!
    @IBOutlet var addMenu: NSMenu!
    @IBOutlet weak var textFieldOutput: NSTextField!
    @IBOutlet weak var textFieldFromImageNumber: NSTextField!
    @IBOutlet weak var textFieldToImageNumber: NSTextField!
    @IBOutlet weak var buttonSave: NSButton!
    @IBOutlet weak var buttonSaveAll: NSButton!


    // MARK: - Lifecycle

    init(document: Document) {
        let languageController = LanguageController(document: document)
        let fileController = FileController(document: document)

        self.document = document
        self.layoutController = LayoutController(document: self.document, layerStateHistory: document.layerStateHistory, viewStateController: self.viewStateController, languageController: languageController, fileController: fileController)
        self.languageController = languageController
        self.fileController = fileController
        self.exportController = ExportController(document: document, fileController: fileController, languageController: languageController)

        super.init(nibName: self.nibName, bundle: nil)

        self.viewStateController.delegate = self
        self.exportController.delegate = self
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

        self.reloadLayout()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.becomeFirstResponder()

        if self.document.fileURL == nil {
            self.document.save(self)
        }
    }

    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        self.updateMenuItem(menuItem)
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

    func updateMenuItem(_ menuItem: NSMenuItem) {
        if menuItem.action == #selector(ContentViewController.toggleHighlightCurrentLayer) {
            if self.layoutController.shouldHighlightSelectedLayer {
                menuItem.state = .on
            } else {
                menuItem.state = .off
            }
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
        self.tableView.reloadDataKeepingSelection()
    }

    @IBAction func addDevice(_ sender: AnyObject?) {
        let operation = AddDeviceOperation(layerStateHistory: self.layerStateHistory)
        operation.apply()
        self.tableView.reloadDataKeepingSelection()
    }

    @IBAction func addText(_ sender: AnyObject?) {
        let operation = AddTextOperation(layerStateHistory: self.layerStateHistory)
        operation.apply()
        self.tableView.reloadDataKeepingSelection()
    }

    func removeLayoutableObject() {
        let operation = RemoveLayerOperation(layerStateHistory: self.layerStateHistory, indexOfLayer: self.tableView.selectedRow)

        let firstIndex = IndexSet(integer: self.tableView.selectedRow - 1)
        self.tableView.selectRowIndexes(firstIndex, byExtendingSelection: false)

        operation.apply()
        self.tableView.reloadDataKeepingSelection()
    }

    @IBAction func toggleHighlightCurrentLayer(_ sender: AnyObject?) {
        self.layoutController.shouldHighlightSelectedLayer = !self.layoutController.shouldHighlightSelectedLayer
        self.viewStateController.newViewState(selectedLayer: self.tableView.selectedRow)
    }

    @IBAction func undo(_ sender: AnyObject?) {
        self.layerStateHistory.undo()
        self.tableView.reloadData()
    }

    @IBAction func redo(_ sender: AnyObject?) {
        self.layerStateHistory.redo()
        self.tableView.reloadData()
    }

    @IBAction func outputConfigDidChange(_ sender: AnyObject?) {
        guard let sender = sender as? NSTextField else { return }

        switch sender {
        case self.textFieldOutput:
            self.updateEnabledStateOfControls()
            let operation = UpdateOutputOperation(layerStateHistory: self.layerStateHistory, output: self.textFieldOutput.stringValue)
            operation.apply()

        case self.textFieldFromImageNumber:
            self.updateEnabledStateOfControls()
            let operation = UpdateFromImageNuberOperation(layerStateHistory: self.layerStateHistory, fromImageNumber: self.textFieldFromImageNumber.integerValue)
            operation.apply()

        case self.textFieldToImageNumber:
            self.updateEnabledStateOfControls()
            let operation = UpdateToImageNuberOperation(layerStateHistory: self.layerStateHistory, toImageNumber: self.textFieldToImageNumber.integerValue)
            operation.apply()

        default:
            return
        }
    }

    @IBAction func saveImage(_ sender: NSButton) {
        if sender == self.buttonSave {
            self.exportController.saveSingleImage(viewState: self.viewStateController.viewState)
        } else {
            self.progressWindowController = ProgressWindowController()
            self.progressWindowController?.delegate = self
            guard let mainWindow = self.windowController?.window else { return }
            guard let progressWindow = self.progressWindowController?.window else { return }

            mainWindow.beginSheet(progressWindow, completionHandler: { (responde) in
                // Handle Cancel button
            })

            DispatchQueue.global(qos: .background).async {
                self.exportController.saveAllImages()
            }
        }
    }

    func reloadLayout() {
        self.layoutController.highlightLayer = self.tableView.selectedRow
        self.inspectorViewController?.updateUI()
        self.scrollView.documentView = self.layoutController.layouthierarchy()

        self.textFieldOutput.stringValue = self.lastLayerState.outputConfig.output
        self.textFieldFromImageNumber.integerValue = self.lastLayerState.outputConfig.fromImageNumber
        self.textFieldToImageNumber.integerValue = self.lastLayerState.outputConfig.toImageNumber

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
        guard self.tableView.isReloading == false else { return}

        self.updateEnabledStateOfControls()

        if let selectedRow = self.tableView?.selectedRow {
            self.inspectorViewController?.selectedRow = selectedRow
        }

        self.viewStateController.newViewState(selectedLayer: self.tableView.selectedRow)
    }
}


// MARK: - View State Delegate

extension ContentViewController: ViewStateControllerDelegate {

    func viewStateDidChange(_ viewState: ViewState) {
        self.reloadLayout()
    }
}


// MARK: Export Delegate

extension ContentViewController: ExportControllerDelegate {

    func exportController(_ exportController: ExportController, didUpdateProgress progress: Double) {
        guard let progressWindowController = self.progressWindowController else { return }

        DispatchQueue.main.async {
            progressWindowController.progressBar.doubleValue = progress
        }

        if progress == 1.0 {
            guard let mainWindow = self.windowController?.window else { return }
            guard let progressWindow = self.progressWindowController?.window else { return }

            mainWindow.endSheet(progressWindow, returnCode: .OK)
        }
    }
}


// MARK: - Progress Window Controller Delegate

extension ContentViewController: ProgressWindowControllerDelegate {

    func progressWindowControllerDidRequestCancel(_ windowController: ProgressWindowController) {
        self.exportController.cancel()
    }
}

// MARK: - Private

private extension ContentViewController {

    func updateEnabledStateOfControls() {
        self.segmentedControl.setEnabled(true, forSegment: 0)
        self.segmentedControl.setEnabled(true, forSegment: 1)

        let selectedRow = self.tableView.selectedRow
        self.segmentedControl.setEnabled(selectedRow != 0, forSegment: 1)

        self.buttonSave.isEnabled = self.textFieldOutput.stringValue.count > 0
        self.buttonSaveAll.isEnabled = self.buttonSave.isEnabled
    }

    func showMenu(for segmentedControl: NSSegmentedControl) {
        var menuLocation = segmentedControl.bounds.origin
        menuLocation.y += segmentedControl.bounds.size.height + 5.0
        self.addMenu.popUp(positioning: nil, at: menuLocation, in: segmentedControl)
    }
}
