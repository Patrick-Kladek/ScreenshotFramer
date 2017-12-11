//
//  Document.swift
//  Framer
//
//  Created by Patrick Kladek on 28.11.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


protocol DocumentDelegate: class {
    func document(_ document: Document, didUpdateLayers layers: [LayoutableObject])
}


final class Document: NSDocument {

    private(set) var layerStateHistory = LayerStateHistory()
    weak var delegate: DocumentDelegate?
    lazy var timeTravelWindowController = DebugWindowController(layerStateHistory: self.layerStateHistory)


    // MARK: - Lifecycle

    override init() {
        super.init()

        self.layerStateHistory.delegate = self
        self.hasUndoManager = false

        let layer = LayoutableObject(title: "Background", frame: CGRect(x: 0, y: 0, width: 800, height: 1200), file: "./Background/01.png", isRoot: true)
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
        self.delegate?.document(self, didUpdateLayers: self.layerStateHistory.currentLayerState.layers)
    }
}
