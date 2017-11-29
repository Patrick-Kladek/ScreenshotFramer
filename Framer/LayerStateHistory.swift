//
//  LayerStateHistory.swift
//  Framer
//
//  Created by Patrick Kladek on 29.11.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation


final class LayerStateHistory {

    private(set) var layerStates: [LayerState] = []
    var lastLayerState: LayerState {
        get {
            if let lastState = self.layerStates.last {
                return lastState
            }

            let firstLayerState = LayerState(title: "First Operation", layers: [])
            self.layerStates.append(firstLayerState)
            return firstLayerState
        }
    }

    func append(_ layerState: LayerState) {
        self.layerStates.append(layerState)
    }

    // MARK: - Undo / Redo

    func undo() {

    }

    func redo() {

    }
}
