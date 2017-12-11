//
//  Operations.swift
//  FrameMe
//
//  Created by Patrick Kladek on 11.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation


protocol OperationProtocol {

    func apply()
}


final class UpdateFrameOperation: OperationProtocol {

    let layerStateHistory: LayerStateHistory
    let indexOfLayer: Int
    let frame: CGRect

    init(layerStateHistory: LayerStateHistory, frame: CGRect, indexOfLayer: Int) {
        self.layerStateHistory = layerStateHistory
        self.frame = frame
        self.indexOfLayer = indexOfLayer
    }

    func apply() {
        let lastLayerState = self.layerStateHistory.currentLayerState
        guard let newLayerState = lastLayerState.updating(frame: self.frame, index: self.indexOfLayer) else { return }

        self.layerStateHistory.append(newLayerState)
    }
}


final class UpdateFileOperation: OperationProtocol {

    let layerStateHistory: LayerStateHistory
    let indexOfLayer: Int
    let file: String


    init(layerStateHistory: LayerStateHistory, file: String, indexOfLayer: Int) {
        self.layerStateHistory = layerStateHistory
        self.file = file
        self.indexOfLayer = indexOfLayer
    }

    func apply() {
        let lastLayerState = self.layerStateHistory.currentLayerState
        guard let newLayerState = lastLayerState.updating(file: self.file, index: self.indexOfLayer) else { return }

        self.layerStateHistory.append(newLayerState)
    }
}

final class RemoveLayerOperation: OperationProtocol {

    let layerStateHistory: LayerStateHistory
    let indexOfLayer: Int

    init(layerStateHistory: LayerStateHistory, indexOfLayer: Int) {
        self.layerStateHistory = layerStateHistory
        self.indexOfLayer = indexOfLayer
    }

    func apply() {
        let layers = self.layerStateHistory.currentLayerState.layers
        guard self.indexOfLayer < layers.count else { return }

        let layer = layers[self.indexOfLayer]
        let newLayerState = self.layerStateHistory.currentLayerState.removingLayer(layer)
        self.layerStateHistory.append(newLayerState)
    }
}


class AddLayerOperation: OperationProtocol {

    let layerStateHistory: LayerStateHistory

    init(layerStateHistory: LayerStateHistory) {
        self.layerStateHistory = layerStateHistory
    }

    func apply() {
        let layer = LayoutableObject()
        let newLayerState = self.layerStateHistory.currentLayerState.addingLayer(layer)
        self.layerStateHistory.append(newLayerState)
    }
}

final class AddTextOperation: AddLayerOperation {

    override func apply() {
        let layer = LayoutableObject(title: "Text", frame: .zero, file: "", isRoot: false)
        let newLayerState = self.layerStateHistory.currentLayerState.addingLayer(layer)
        self.layerStateHistory.append(newLayerState)
    }
}

final class AddContentOperation: AddLayerOperation {

    override func apply() {
        let layer = LayoutableObject(title: "Content", frame: .zero, file: "", isRoot: false)
        let newLayerState = self.layerStateHistory.currentLayerState.addingLayer(layer)
        self.layerStateHistory.append(newLayerState)
    }
}

final class AddDeviceOperation: AddLayerOperation {

    override func apply() {
        let layer = LayoutableObject(title: "Device", frame: .zero, file: "", isRoot: false)
        let newLayerState = self.layerStateHistory.currentLayerState.addingLayer(layer)
        self.layerStateHistory.append(newLayerState)
    }
}
