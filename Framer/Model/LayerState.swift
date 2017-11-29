//
//  LayerState.swift
//  Framer
//
//  Created by Patrick Kladek on 29.11.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation


struct LayerState {
    let title: String
    let layers: [LayoutableObject]

    func addingLayer(_ layer: LayoutableObject) -> LayerState {
        var layers = self.layers
        layers.append(layer)
        return LayerState(title: "Add Layer", layers: layers)
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
        return LayerState(title: "Remove Layer", layers: layers)
    }
}
