//
//  ContentViewController.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 06.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


final class ContentViewController: NSViewController, NSMenuItemValidation {

    // MARK: - Properties

    var document: Document
    var layerStateHistory: LayerStateHistory { return self.document.layerStateHistory }
    var lastLayerState: LayerState { return self.layerStateHistory.currentLayerState }
    var windowController: DocumentWindowController? { return self.view.window?.windowController as? DocumentWindowController }
    var inspectorViewController: InspectorViewController?
    let viewStateController = ViewStateController()
    var fileController: FileController
    var progressWindowController: ProgressWindowController?

    lazy var languageController = LanguageController(fileCapsule: self.document.fileCapsule)
    lazy var exportController = ExportController(layerStateHistory: self.layerStateHistory, fileController: self.fileController, languageController: self.languageController)
    lazy var layoutController = LayoutController(viewStateController: self.viewStateController, languageController: self.languageController, fileController: self.fileController)
    lazy var layoutWarningPopoverViewController = WarningPopoverViewController()
    lazy var popover = NSPopover()


    // MARK: - Interface Builder

    @IBOutlet private var inspectorPlaceholder: NSView!
    @IBOutlet private var scrollView: NSScrollView!
    @IBOutlet private var segmentedControl: NSSegmentedControl!
    @IBOutlet private var tableView: SSFTableView!
    @IBOutlet private var addMenu: NSMenu!
    @IBOutlet private var layoutWarningButton: NSButton!
    @IBOutlet private var textFieldOutput: NSTextField!
    @IBOutlet private var textFieldFromImageNumber: NSTextField!
    @IBOutlet private var textFieldToImageNumber: NSTextField!
    @IBOutlet private var buttonSave: NSButton!
    @IBOutlet private var buttonSaveAll: NSButton!


    // MARK: - Lifecycle

    init(document: Document) {
        let fileController = FileController(fileCapsule: document.fileCapsule)

        self.document = document
        self.fileController = fileController

        super.init(nibName: nil, bundle: nil)

        self.viewStateController.delegate = self
        self.exportController.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: - Overrides

    override var nibName: NSNib.Name? {
        return String(describing: type(of: self))
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let inspector = InspectorViewController(layerStateHistory: self.document.layerStateHistory, selectedRow: 0, viewStateController: viewStateController, languageController: languageController)
        self.addChild(inspector)
        self.inspectorPlaceholder.addSubview(inspector.view)

        NSLayoutConstraint.activate([
            self.inspectorPlaceholder.topAnchor.constraint(equalTo: inspector.view.topAnchor, constant: 0),
            self.inspectorPlaceholder.leadingAnchor.constraint(equalTo: inspector.view.leadingAnchor, constant: 0),
            self.inspectorPlaceholder.trailingAnchor.constraint(equalTo: inspector.view.trailingAnchor, constant: 0)
        ])

        inspector.updateUI()
        self.inspectorViewController = inspector
        self.inspectorViewController?.delegate = self

        self.reloadLayout()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.becomeFirstResponder()

        if self.document.fileURL == nil {
            self.document.save(self)
        }

        self.zoomToFit(nil)
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        self.updateMenuItem(menuItem)
        guard let action = menuItem.action else { return false }

        switch action {
        case #selector(ContentViewController.undo):
            return self.layerStateHistory.canUndo && self.lastLayerState.layers.hasElements
        case #selector(ContentViewController.redo):
            return self.layerStateHistory.canRedo

        case #selector(ContentViewController.addContent),
             #selector(ContentViewController.addDevice),
             #selector(ContentViewController.addText):
            return true

        case #selector(ContentViewController.toggleHighlightCurrentLayer),
             #selector(ContentViewController.zoomToFit):
            return true

        case #selector(ContentViewController.previousImage):
            guard let inspectorViewController = inspectorViewController else { return true }

            return inspectorViewController.viewStateController.viewState.imageNumber > self.textFieldFromImageNumber.integerValue

        case #selector(ContentViewController.nextImage):
            guard let inspectorViewController = inspectorViewController else { return true }

            return inspectorViewController.viewStateController.viewState.imageNumber < self.textFieldToImageNumber.integerValue

        default:
            return false
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
            guard self.textFieldFromImageNumber.integerValue <= self.textFieldToImageNumber.integerValue else {
                self.reloadLayout()
                return
            }
            self.updateEnabledStateOfControls()
            let operation = UpdateFromImageNuberOperation(layerStateHistory: self.layerStateHistory, fromImageNumber: self.textFieldFromImageNumber.integerValue)
            operation.apply()

        case self.textFieldToImageNumber:
            guard self.textFieldFromImageNumber.integerValue <= self.textFieldToImageNumber.integerValue else {
                self.reloadLayout()
                return
            }
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

            mainWindow.beginSheet(progressWindow, completionHandler: { _ in
                // Handle Cancel button
            })

            DispatchQueue.global(qos: .background).async {
                self.exportController.saveAllImages()
            }
        }
    }

    @IBAction func endEditingText(_ sender: Any?) {
        guard let textField = sender as? NSTextField else { return }

        let row = self.tableView.row(for: textField)
        guard row >= 0 else { return }

        let title = textField.stringValue
        let operation = UpdateTitleOperation(layerStateHistory: self.layerStateHistory, indexOfLayer: row, title: title)
        operation.apply()
    }

    /**
     *  - Attention: for now this displays only the fontToBig warning
     */
    @IBAction func warningButtonPressed(_ sender: NSButton?) {
        guard let sender = sender else { return }

        self.popover.contentViewController = self.layoutWarningPopoverViewController
        self.popover.animates = true
        self.popover.behavior = .transient
        self.popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: NSRectEdge.minX)
    }

    /**
     *  - Attenttion: uses animation when sender != nil. Therefore animates when called from UI elements
     */
    @IBAction func zoomToFit(_ sender: Any?) {
        guard var frame = self.scrollView.documentView?.frame else { return }

        frame.size.width += 40
        frame.size.height += 40

        if sender != nil {
            self.scrollView.animator().magnify(toFit: frame)
        } else {
            self.scrollView.magnify(toFit: frame)
        }
    }

    @IBAction func previousImage(_ sender: Any?) {
        let currentImage = self.inspectorViewController?.viewStateController.viewState.imageNumber ?? 0
        self.inspectorViewController?.viewStateController.newViewState(imageNumber: currentImage - 1)
    }

    @IBAction func nextImage(_ sender: Any?) {
        let currentImage = self.inspectorViewController?.viewStateController.viewState.imageNumber ?? 0
        self.inspectorViewController?.viewStateController.newViewState(imageNumber: currentImage + 1)
    }

    func reloadLayout() {
        self.layoutController.highlightLayer = self.tableView.selectedRow
        self.inspectorViewController?.updateUI()
        self.inspectorViewController?.updateUIFromViewState()
        self.scrollView.documentView = self.layoutController.layouthierarchy(layers: self.lastLayerState.layers)
        self.layoutWarningButton.isHidden = self.layoutController.layoutErrors.isEmpty

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
        view?.textField?.action = #selector(ContentViewController.endEditingText)
        view?.textField?.target = self

        return view
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard self.tableView.isReloading == false else { return }

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

    func exportController(_ exportController: ExportController, didUpdateProgress progress: Double, file: String, layoutErrors: [LayoutError]) {
        guard let progressWindowController = self.progressWindowController else { return }

        DispatchQueue.main.async {
            progressWindowController.progress = progress
        }

        if progress == 1.0 {
            guard let mainWindow = self.windowController?.window else { return }
            guard let progressWindow = self.progressWindowController?.window else { return }

            DispatchQueue.main.async {
                mainWindow.endSheet(progressWindow, returnCode: .OK)
            }
        }
    }
}


// MARK: - Progress Window Controller Delegate

extension ContentViewController: ProgressWindowControllerDelegate {

    func progressWindowControllerDidRequestCancel(_ windowController: ProgressWindowController) {
        self.exportController.cancel()
    }
}

// MARK: - Inspector Delegate

extension ContentViewController: InspectorViewControllerDelegate {

    func inspector(_ inspector: InspectorViewController, requestRotation newRotation: CGFloat, of index: Int) {
        guard index > 0 else { return }
        guard let views = self.scrollView.documentView?.subviews else { return }

        let view = views[index]
        view.frameCenterRotation = newRotation
        view.needsDisplay = true
        view.display()
    }

    func inspector(_ inspector: InspectorViewController, requestNewFrame newFrame: CGRect, of index: Int) {
        guard let documentView = self.scrollView.documentView else { return }

        if index == 0 {
            documentView.frame = newFrame
            return
        }

        let view = documentView.subviews[index]
        view.frame = newFrame
    }

    func inspector(_ inspector: InspectorViewController, requestNewFont newFont: NSFont?, of index: Int) {
        guard index > 0 else { return }
        guard let views = self.scrollView.documentView?.subviews else { return }
        guard let textField = views[index] as? NSTextField else { return }

        textField.font = newFont
    }

    func inspector(_ inspector: InspectorViewController, requestNewColor newColor: NSColor, of index: Int) {
        guard index > 0 else { return }
        guard let views = self.scrollView.documentView?.subviews else { return }
        guard let textField = views[index] as? NSTextField else { return }

        textField.textColor = newColor
    }
}

// MARK: - Private

private extension ContentViewController {

    func updateEnabledStateOfControls() {
        self.segmentedControl.setEnabled(true, forSegment: 0)
        self.segmentedControl.setEnabled(true, forSegment: 1)

        let selectedRow = self.tableView.selectedRow
        self.segmentedControl.setEnabled(selectedRow != 0, forSegment: 1)

        self.buttonSave.isEnabled = self.textFieldOutput.stringValue.isEmpty == false
        self.buttonSaveAll.isEnabled = self.buttonSave.isEnabled
    }

    func showMenu(for segmentedControl: NSSegmentedControl) {
        var menuLocation = segmentedControl.bounds.origin
        menuLocation.y += segmentedControl.bounds.size.height + 5.0
        self.addMenu.popUp(positioning: nil, at: menuLocation, in: segmentedControl)
    }

    @objc func addContent(_ sender: AnyObject?) {
        let operation = AddContentOperation(layerStateHistory: self.layerStateHistory)
        operation.apply()
        self.tableView.reloadDataKeepingSelection()
    }

    @objc func addDevice(_ sender: AnyObject?) {
        let operation = AddDeviceOperation(layerStateHistory: self.layerStateHistory)
        operation.apply()
        self.tableView.reloadDataKeepingSelection()
    }

    @objc func addText(_ sender: AnyObject?) {
        let operation = AddTextOperation(layerStateHistory: self.layerStateHistory)
        operation.apply()
        self.tableView.reloadDataKeepingSelection()
    }

    @objc func removeLayoutableObject() {
        let operation = RemoveLayerOperation(layerStateHistory: self.layerStateHistory, indexOfLayer: self.tableView.selectedRow)

        let firstIndex = IndexSet(integer: self.tableView.selectedRow - 1)
        self.tableView.selectRowIndexes(firstIndex, byExtendingSelection: false)

        operation.apply()
        self.tableView.reloadDataKeepingSelection()
    }

}
