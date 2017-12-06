//
//  LayerStateHistory.swift
//  Framer
//
//  Created by Patrick Kladek on 29.11.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation


protocol LayerStateHistoryDelegate {
    func layerStateHistory(_ histroy: LayerStateHistory, didUpdateHistory: LayerState)
}


final class LayerStateHistory {

    private(set) var currentStackPosition: Int = 0
    private(set) var layerStates: [LayerState] = []
    var delegate: LayerStateHistoryDelegate?
    var lastLayerState: LayerState {
        get {
            if self.layerStates.count != 0 && self.currentStackPosition <= self.layerStates.count {
                return self.layerStates[self.currentStackPosition]
            }

            let firstLayerState = LayerState(title: "First Operation", layers: [])
            self.layerStates.append(firstLayerState)
            return firstLayerState
        }
    }


    // MARK: - Actions

    func append(_ layerState: LayerState) {
        if self.currentStackPosition < self.layerStates.count - 1 {
            self.layerStates.removeLast(self.currentStackPosition)
        }

        self.currentStackPosition += 1
        self.layerStates.append(layerState)
        self.notifyLayerStateDidChange()
    }

    // MARK: - Undo / Redo

    @discardableResult func undo() -> Bool {
        guard self.canUndo else { return false }

        self.currentStackPosition -= 1
        self.notifyLayerStateDidChange()
        return true
    }

    @discardableResult func redo() -> Bool {
        guard self.canRedo else { return false }

        self.currentStackPosition += 1
        self.notifyLayerStateDidChange()
        return true
    }

    var canRedo: Bool {
        return self.currentStackPosition < self.layerStates.count
    }

    var canUndo: Bool {
        return self.layerStates.count > 0 && self.currentStackPosition > 0
    }

    // MARK: - Private

    private func notifyLayerStateDidChange() {
        self.delegate?.layerStateHistory(self, didUpdateHistory: self.lastLayerState)
    }
}
