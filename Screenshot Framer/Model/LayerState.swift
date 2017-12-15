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


    // MARK: - Mutating Functions

    func addingLayer(_ layer: LayoutableObject) -> LayerState {
        var layers = self.layers
        layers.append(layer)
        return LayerState(title: "Add \(layer.title)", layers: layers)
    }

    func addingLayers(_ layers: [LayoutableObject]) -> LayerState {
        var layer = self.layers
        layer.append(contentsOf: layers)
        return LayerState(title: "Add Layers", layers: layers)
    }

    func removingLayer(_ layer: LayoutableObject) -> LayerState {
        var layers = self.layers
        guard let index = layers.index(of: layer) else { return self }

        layers.remove(at: index)
        return LayerState(title: "Remove \(layer.title)", layers: layers)
    }

    func updating(frame: CGRect, index: Int) -> LayerState? {
        var layers = self.layers

        guard index < layers.count else { return nil }
        guard layers[index].frame != frame else { return nil }

        layers[index].frame = frame
        return LayerState(title: "Update Frame \(title(of: frame))", layers: layers)
    }

    func updating(title: String, index: Int) -> LayerState? {
        var layers = self.layers

        guard index < layers.count else { return nil }

        layers[index].title = title
        return LayerState(title: "Updating Title", layers: layers)
    }

    func updating(file: String, index: Int) -> LayerState? {
        var layers = self.layers

        guard index < layers.count else { return nil }

        layers[index].file = file
        return LayerState(title: "Updating File", layers: layers)
    }

    func updating(font: String, index: Int) -> LayerState? {
        var layers = self.layers

        guard index < layers.count else { return nil }

        layers[index].font = font
        return LayerState(title: "Updating Font", layers: layers)
    }

    func updating(fontSize: CGFloat, index: Int) -> LayerState? {
        var layers = self.layers

        guard index < layers.count else { return nil }

        layers[index].fontSize = fontSize
        return LayerState(title: "Updating Font Size", layers: layers)
    }

    func updating(color: NSColor, index: Int) -> LayerState? {
        var layers = self.layers

        guard index < layers.count else { return nil }

        layers[index].color = color
        return LayerState(title: "Updating Color", layers: layers)
    }

    private func title(of rect: CGRect) -> String {
        return "\(Int(rect.origin.x)) \(Int(rect.origin.y)) | \(Int(rect.size.width)) \(Int(rect.size.height))"
    }
}
