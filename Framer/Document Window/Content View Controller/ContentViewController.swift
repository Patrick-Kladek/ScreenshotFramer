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
    let viewStateController = ViewStateController()


    // MARK: - Interface Builder

    @IBOutlet var inspectorPlaceholder: NSView!
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var segmentedControl: NSSegmentedControl!
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var addMenu: NSMenu!


    // MARK: - Lifecycle

    init(document: Document) {
        self.document = document

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
        let inspector = InspectorViewController(layerStateHistory: self.document.layerStateHistory, selectedRow: 0, viewStateController: viewStateController)
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

    func reloadLayout() {
        self.tableView.reloadDataKeepingSelection()
        self.scrollView.documentView = self.layouthierarchy()
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

    func layouthierarchy() -> NSView? {
        let layoutableObjects = self.layerStateHistory.currentLayerState.layers
        guard layoutableObjects.count > 0 else { return nil }

        let firstLayoutableObject = layoutableObjects[0]
        let rootView: NSView

        if let absoluteURL = self.absoluteURL(for: firstLayoutableObject) {
            rootView = RenderedView(frame: firstLayoutableObject.frame, url: absoluteURL)
        } else {
            rootView = pkView(frame: firstLayoutableObject.frame)
            (rootView as! pkView).backgroundColor = NSColor.red
        }

        for object in layoutableObjects where object != layoutableObjects[0] {
            let view: NSView

            if let absoluteURL = self.absoluteURL(for: object) {
                if object.title == "Text", let text = self.localizedTitle(from: absoluteURL, imageNumber: self.viewStateController.viewState.imageNumber) {
                    view = self.textField(with: text, frame: object.frame, color: NSColor.white, font: NSFont.systemFont(ofSize: NSFont.systemFontSize))
                } else {
                    view = RenderedView(frame: object.frame, url: absoluteURL)
                }
            } else {
                view = pkView(frame: object.frame)
                (view as! pkView).backgroundColor = NSColor.blue
            }
            
            rootView.addSubview(view)
        }

        return rootView
    }

    func textField(with string: String, frame: CGRect, color: NSColor, font: NSFont) -> NSTextField {
        let textField             = NSTextField(frame: frame)
        textField.textColor       = color
        textField.backgroundColor = NSColor.clear
        textField.isBezeled       = false
        textField.isEditable      = false
        textField.stringValue     = string
        textField.alignment       = .center

        let kMaxFontSize = CGFloat(120.0)
        let kMinFontSize = CGFloat(6.0)
        var fontSize = kMaxFontSize;
        var size = (string as NSString).size(withAttributes: [NSAttributedStringKey.font: NSFont(name: font.fontName, size: kMaxFontSize)!])
        while (size.width >= frame.width - 5 || size.height >= frame.height - 5) && fontSize > kMinFontSize  {
            fontSize -= 1
            let newFontSize = CGFloat(fontSize)
            let newFont = NSFont(name: font.fontName, size: newFontSize)

            size = (string as NSString).size(withAttributes: [NSAttributedStringKey.font: newFont!])
        }
        textField.font = NSFont(name: font.fontName, size: fontSize)
        return textField
    }

    func absoluteURL(for object: LayoutableObject) -> URL? {
        let documentUrl = self.document.fileURL
        let folderURL = documentUrl?.deletingLastPathComponent()
        guard object.file.count > 0 else { return nil }

        let file = object.file.replacingOccurrences(of: "$image", with: "\(self.viewStateController.viewState.imageNumber)")

        let absoluteURL = folderURL?.appendingPathComponent(file)
        return absoluteURL
    }

    func localizedTitle(from url: URL, imageNumber: Int) -> String? {
        guard let dict = NSDictionary(contentsOf: url) else { return nil }

        let value = dict["\(imageNumber)"] as? String
        return value
    }

    func showMenu(for segmentedControl: NSSegmentedControl) {
        var menuLocation = segmentedControl.bounds.origin
        menuLocation.y += segmentedControl.bounds.size.height + 5.0
        self.addMenu.popUp(positioning: nil, at: menuLocation, in: segmentedControl)
    }
}
