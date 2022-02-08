//
//  LayerState.swift
//  Framer
//
//  Created by Patrick Kladek on 29.11.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


struct LayerState: Codable {

    // MARK: - Properties

    let title: String
    let layers: [LayoutableObject]
    let outputConfig: OutputConfig


    // MARK: - Mutating Functions

    func addingLayer(_ layer: LayoutableObject) -> LayerState {
        var layers = self.layers
        layers.append(layer)
        return LayerState(title: "Add \(layer.title)", layers: layers, outputConfig: self.outputConfig)
    }

    func addingLayers(_ layers: [LayoutableObject]) -> LayerState {
        var layer = self.layers
        layer.append(contentsOf: layers)
        return LayerState(title: "Add Layers", layers: layers, outputConfig: self.outputConfig)
    }

    func removingLayer(_ layer: LayoutableObject) -> LayerState {
        var layers = self.layers
        guard let index = layers.firstIndex(of: layer) else { return self }

        layers.remove(at: index)
        return LayerState(title: "Remove \(layer.title)", layers: layers, outputConfig: self.outputConfig)
    }

    func updating(frame: CGRect, index: Int) -> LayerState? {
        var layers = self.layers

        guard index < layers.count else { return nil }
        guard layers[index].frame != frame else { return nil }

        layers[index].frame = frame
        return LayerState(title: "Update Frame \(title(of: frame))", layers: layers, outputConfig: self.outputConfig)
    }

    func updating(rotation: CGFloat, index: Int) -> LayerState? {
        var layers = self.layers

        guard index < layers.count else { return nil }
        guard layers[index].rotation != rotation else { return nil }

        layers[index].rotation = rotation
        return LayerState(title: "Update Rotation " + String(format: "%.2f°", rotation), layers: layers, outputConfig: self.outputConfig)
    }

    func updating(title: String, index: Int) -> LayerState? {
        var layers = self.layers

        guard index < layers.count else { return nil }

        layers[index].title = title
        return LayerState(title: "Updating Title", layers: layers, outputConfig: self.outputConfig)
    }

    func updating(file: String, index: Int) -> LayerState? {
        var layers = self.layers

        guard index < layers.count else { return nil }

        layers[index].file = file
        return LayerState(title: "Updating File", layers: layers, outputConfig: self.outputConfig)
    }

    func updating(font: String, index: Int) -> LayerState? {
        var layers = self.layers

        guard index < layers.count else { return nil }

        layers[index].font = font
        return LayerState(title: "Updating Font", layers: layers, outputConfig: self.outputConfig)
    }

    func updating(fontSize: CGFloat, index: Int) -> LayerState? {
        var layers = self.layers

        guard index < layers.count else { return nil }

        layers[index].fontSize = fontSize
        return LayerState(title: "Updating Font Size", layers: layers, outputConfig: self.outputConfig)
    }

    func updating(color: NSColor, index: Int) -> LayerState? {
        var layers = self.layers

        guard index < layers.count else { return nil }

        layers[index].color = color
        return LayerState(title: "Updating Color", layers: layers, outputConfig: self.outputConfig)
    }

    func updating(alignment: NSTextAlignment, index: Int) -> LayerState? {
        var layers = self.layers

        guard index < layers.count else { return nil }

        layers[index].textAlignment = alignment
        return LayerState(title: "Updating Text Alignment", layers: layers, outputConfig: self.outputConfig)
    }

    func updating(verticallyCentered: Bool, index: Int) -> LayerState? {
        var layers = self.layers

        guard index < layers.count else { return nil }

        layers[index].verticallyCentered = verticallyCentered
        return LayerState(title: "Updating Vertical Alignment", layers: layers, outputConfig: self.outputConfig)
    }


    // MARK: - Output Config

    func updating(output: String) -> LayerState {
        let newConfig = OutputConfig(transparent: self.outputConfig.transparent, output: output, fromImageNumber: self.outputConfig.fromImageNumber, toImageNumber: self.outputConfig.toImageNumber)
        return LayerState(title: "Updating Export Output", layers: self.layers, outputConfig: newConfig)
    }

    func updating(fromImageNumber: Int) -> LayerState {
        let newConfig = OutputConfig(transparent: self.outputConfig.transparent, output: self.outputConfig.output, fromImageNumber: fromImageNumber, toImageNumber: self.outputConfig.toImageNumber)
        return LayerState(title: "Updating Export From Image Number", layers: self.layers, outputConfig: newConfig)
    }

    func updating(toImageNumber: Int) -> LayerState {
        let newConfig = OutputConfig(transparent: self.outputConfig.transparent, output: self.outputConfig.output, fromImageNumber: self.outputConfig.fromImageNumber, toImageNumber: toImageNumber)
        return LayerState(title: "Updating Export To Image Number", layers: self.layers, outputConfig: newConfig)
    }

    func updating(transparency: Bool) -> LayerState {
        let newConfig = OutputConfig(transparent: transparency, output: self.outputConfig.output, fromImageNumber: self.outputConfig.fromImageNumber, toImageNumber: self.outputConfig.toImageNumber)
        return LayerState(title: "Updating Export Transparency", layers: self.layers, outputConfig: newConfig)
    }


    // MARK: - Private

    private func title(of rect: CGRect) -> String {
        return "\(Int(rect.origin.x)) \(Int(rect.origin.y)) | \(Int(rect.size.width)) \(Int(rect.size.height))"
    }
}
