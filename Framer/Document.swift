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


class Document: NSDocument {

    private(set) weak var delegate: DocumentDelegate?
    private(set) var layerStateHistory = LayerStateHistory()

    var layers: [LayoutableObject] {
        get {
            return self.layerStateHistory.lastLayerState.layers
        }
    }

    // MARK: - Lifecycle

    override init() {
        let root = LayoutableObject(title: "Background", frame: CGRect(x: 0, y: 0, width: 800, height: 1200), file: "../background/01", isRoot: true)

        super.init()

        self.addLayer(root)
    }

    // MARK: - Override

    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        let windowController = DocumentWindowController()
        self.delegate = windowController
        self.addWindowController(windowController)
    }

    // MARK: - Read/Write

    func addLayer(_ layer: LayoutableObject) {
        let newLayerState = self.layerStateHistory.lastLayerState.addingLayer(layer)
        self.layerStateHistory.append(newLayerState)
        self.delegate?.document(self, didUpdateLayers: self.layerStateHistory.lastLayerState.layers)
    }

    func remove(_ layer: LayoutableObject) {
        let newLayerState = self.layerStateHistory.lastLayerState.removingLayer(layer)
        self.layerStateHistory.append(newLayerState)
        self.delegate?.document(self, didUpdateLayers: self.layerStateHistory.lastLayerState.layers)
    }

    override func data(ofType typeName: String) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self.layerStateHistory.lastLayerState.layers)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        let decoder = JSONDecoder()
        let layers = try decoder.decode([LayoutableObject].self, from: data)

        let newLayerState = self.layerStateHistory.lastLayerState.addingLayers(layers)
        self.layerStateHistory.append(newLayerState)
    }
}

