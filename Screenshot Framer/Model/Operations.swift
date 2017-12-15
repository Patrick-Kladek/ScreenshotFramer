//
//  Operations.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 11.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


protocol OperationProtocol {

    func apply()
}


final class UpdateOutputOperation: OperationProtocol {

    let layerStateHistory: LayerStateHistory
    let output: String

    init(layerStateHistory: LayerStateHistory, output: String) {
        self.layerStateHistory = layerStateHistory
        self.output = output
    }

    func apply() {
        let lastLayerState = self.layerStateHistory.currentLayerState
        let newLayerState = lastLayerState.updating(output: self.output)
        self.layerStateHistory.append(newLayerState)
    }
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


final class UpdateFontOperation: OperationProtocol {

    let layerStateHistory: LayerStateHistory
    let indexOfLayer: Int
    let fontString: String

    init(layerStateHistory: LayerStateHistory, font: String, indexOfLayer: Int) {
        self.layerStateHistory = layerStateHistory
        self.indexOfLayer = indexOfLayer
        self.fontString = font
    }

    func apply() {
        let lastLayerState = self.layerStateHistory.currentLayerState
        guard let newLayerState = lastLayerState.updating(font: self.fontString, index: self.indexOfLayer) else { return }

        self.layerStateHistory.append(newLayerState)
    }
}


final class UpdateFontSizeOperation: OperationProtocol {

    let layerStateHistory: LayerStateHistory
    let indexOfLayer: Int
    let fontSize: CGFloat

    init(layerStateHistory: LayerStateHistory, fontSize: CGFloat, indexOfLayer: Int) {
        self.layerStateHistory = layerStateHistory
        self.indexOfLayer = indexOfLayer
        self.fontSize = fontSize
    }

    func apply() {
        let lastLayerState = self.layerStateHistory.currentLayerState
        guard let newLayerState = lastLayerState.updating(fontSize: self.fontSize, index: self.indexOfLayer) else { return }

        self.layerStateHistory.append(newLayerState)
    }
}


final class UpdateTextColorOperation: OperationProtocol {

    let layerStateHistory: LayerStateHistory
    let indexOfLayer: Int
    let color: NSColor

    init(layerStateHistory: LayerStateHistory, color: NSColor, indexOfLayer: Int) {
        self.layerStateHistory = layerStateHistory
        self.indexOfLayer = indexOfLayer
        self.color = color
    }

    func apply() {
        let lastLayerState = self.layerStateHistory.currentLayerState
        guard let newLayerState = lastLayerState.updating(color: self.color, index: self.indexOfLayer) else { return }

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
    var type: LayoutableObjectType { return .none }

    init(layerStateHistory: LayerStateHistory) {
        self.layerStateHistory = layerStateHistory
    }

    func apply() {
        let layer = LayoutableObject(type: self.type, title: self.type.rawValue, frame: .zero, file: "", isRoot: false)
        let newLayerState = self.layerStateHistory.currentLayerState.addingLayer(layer)
        self.layerStateHistory.append(newLayerState)
    }
}

final class AddBackgroundOperation: AddLayerOperation {

    override var type: LayoutableObjectType { return .background }

    override func apply() {
        let layer = LayoutableObject(type: self.type, title: self.type.rawValue, frame: CGRect(x: 0, y: 0, width: 800, height: 1200), file: "", isRoot: false)
        let newLayerState = self.layerStateHistory.currentLayerState.addingLayer(layer)
        self.layerStateHistory.append(newLayerState)
    }
}

final class AddTextOperation: AddLayerOperation {

    override var type: LayoutableObjectType { return .text }
}

final class AddContentOperation: AddLayerOperation {

    override var type: LayoutableObjectType { return .content }
}

final class AddDeviceOperation: AddLayerOperation {

    override var type: LayoutableObjectType { return .device }
}
