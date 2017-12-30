//
//  Document.swift
//  Framer
//
//  Created by Patrick Kladek on 28.11.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


final class Document: NSDocument {

    // MARK: - Properties

    let fileCapsule = FileCapsule()
    private(set) var layerStateHistory = LayerStateHistory()
    private var projectURL: URL? { return self.fileURL?.deletingLastPathComponent() }
    lazy var timeTravelWindowController = TimeTravelWindowController(layerStateHistory: self.layerStateHistory)


    // MARK: - Lifecycle

    override init() {
        super.init()

        self.layerStateHistory.delegate = self
        self.hasUndoManager = false

        let operation = AddBackgroundOperation(layerStateHistory: self.layerStateHistory)
        operation.apply()
        self.updateChangeCount(.changeCleared)
    }


    // MARK: - Override

    override class var autosavesInPlace: Bool { return true }

    override var shouldRunSavePanelWithAccessoryView: Bool { return true }

    override func makeWindowControllers() {
        let windowController = DocumentWindowController()
        self.addWindowController(windowController)

        self.addWindowController(self.timeTravelWindowController)
        if UserDefaults.standard.showTimeTravelWindow {
            self.showTimeTravelWindow(nil)
        }
    }

    override func prepareSavePanel(_ savePanel: NSSavePanel) -> Bool {
        let accessoryView = NSView(frame: CGRect(x: 0, y: 0, width: savePanel.frame.width, height: 60))
        let detailLabel = NSTextField(labelWithString: "Screenshot Framer needs a project directory to start.\nYou will be able to access all files in this directory but no files outside of this directory")

        detailLabel.frame = CGRect(x: 0, y: 15, width: savePanel.frame.width, height: detailLabel.frame.height)
        detailLabel.alignment = .center
        detailLabel.maximumNumberOfLines = 2

        accessoryView.addSubview(detailLabel)
        savePanel.accessoryView = accessoryView

        return true
    }

    override func save(_ sender: Any?) {
        self.save(withDelegate: self, didSave: #selector(Document.document(_:didSave:contextInfo:)), contextInfo: nil)
    }

    @objc
    func document(_ document: NSDocument, didSave: Bool, contextInfo: UnsafeRawPointer) {
        guard didSave == true else { return }

        self.fileCapsule.projectURL = self.projectURL
    }


    override func canClose(withDelegate delegate: Any, shouldClose shouldCloseSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
        self.layerStateHistory.discardRedoHistory()

        if self.isDocumentEdited && self.fileURL != nil {
            self.save(nil)
        }
        self.close()
    }


    // Responder Chain

    @IBAction func showTimeTravelWindow(_ sender: AnyObject?) {
        self.timeTravelWindowController.window?.orderFront(self)

        if sender != nil {
            UserDefaults.standard.showTimeTravelWindow = true
        }
    }

    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(showTimeTravelWindow) {
            return self.timeTravelWindowController.window?.isVisible == false
        }

        return super.validateMenuItem(menuItem)
    }


    // MARK: - Read/Write

    override func data(ofType typeName: String) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self.layerStateHistory.layerStates)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        self.fileCapsule.projectURL = self.projectURL

        let decoder = JSONDecoder()
        let layers = try decoder.decode([LayerState].self, from: data)
        self.layerStateHistory = LayerStateHistory(layerStates: layers, delegate: self)
        self.updateChangeCount(.changeCleared)
    }
}


// MARK: - LayerStateHistoryDelegate

extension Document: LayerStateHistoryDelegate {

    func layerStateHistory(_ histroy: LayerStateHistory, didUpdateHistory: LayerState, layerCountDidChange: Bool) {
        self.updateChangeCount(.changeDone)
        guard let windowController = self.windowControllers.first(where: { $0 is DocumentWindowController }) as? DocumentWindowController else { return }
        guard let contentViewController = windowController.contentViewController as? ContentViewController else { return }

        contentViewController.reloadLayout()
    }
}
