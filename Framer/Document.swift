//
//  Document.swift
//  Framer
//
//  Created by Patrick Kladek on 28.11.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


final class Document: NSDocument {

    private(set) var layerStateHistory = LayerStateHistory()
    lazy var timeTravelWindowController = DebugWindowController(layerStateHistory: self.layerStateHistory)


    // MARK: - Lifecycle

    override init() {
        super.init()

        self.layerStateHistory.delegate = self
        self.hasUndoManager = false

        let layer = LayoutableObject(title: "Background", frame: CGRect(x: 0, y: 0, width: 800, height: 1200), file: "backgrounds/1.jpg", isRoot: true)
        let newLayerState = self.layerStateHistory.currentLayerState.addingLayer(layer)
        self.layerStateHistory.append(newLayerState)
    }
    

    // MARK: - Override

    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        let windowController = DocumentWindowController()
        self.addWindowController(windowController)

        self.addWindowController(self.timeTravelWindowController)
        self.showTimeTravelWindow(nil)
    }

    // Responder Chain

    @IBAction func showTimeTravelWindow(_ sender: AnyObject?) {
        self.timeTravelWindowController.window?.orderFront(self)
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
        let decoder = JSONDecoder()

        let layers = try decoder.decode([LayerState].self, from: data)
        self.layerStateHistory = LayerStateHistory(layerStates: layers, delegate: self)
        self.updateChangeCount(.changeCleared)
    }
}

extension Document: LayerStateHistoryDelegate {

    func layerStateHistory(_ histroy: LayerStateHistory, didUpdateHistory: LayerState) {
        self.updateChangeCount(.changeDone)
        guard let windowController = self.windowControllers.first(where: { $0 is DocumentWindowController }) as? DocumentWindowController else { return }
        guard let contentViewController = windowController.contentViewController as? ContentViewController else { return }

        contentViewController.reloadLayout()
    }
}
