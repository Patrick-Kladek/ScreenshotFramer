//
//  LayerStateHistory.swift
//  Framer
//
//  Created by Patrick Kladek on 29.11.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation


protocol LayerStateHistoryDelegate: class {
    func layerStateHistory(_ histroy: LayerStateHistory, didUpdateHistory: LayerState, layerCountDidChange: Bool)
}


final class LayerStateHistory {

    // MARK: - Properties

    private(set) var currentStackPosition: Int = -1
    private(set) var layerStates: [LayerState] = []
    weak var delegate: LayerStateHistoryDelegate?

    /**
     *  returns the current LayerState based on undo (currentStackPosition)
     *  Warning: Ensure that at least one object is availible
     */
    var currentLayerState: LayerState {
        return self.layerStates[self.currentStackPosition]
    }

    // MARK: - Lifecycle

    init() {
        let initialState = LayerState(title: "Initial Operation", layers: [], outputConfig: OutputConfig(output: "", fromImageNumber: 1, toImageNumber: 5))
        self.append(initialState)
    }

    init(layerStates: [LayerState], delegate: LayerStateHistoryDelegate?) {
        self.layerStates = layerStates
        self.currentStackPosition = self.layerStates.count - 1
        self.delegate = delegate
    }


    // MARK: - Actions

    func append(_ layerState: LayerState) {
        if self.currentStackPosition > 0 && self.currentStackPosition < self.layerStates.count - 1 {
            let diff = self.layerStates.count - self.currentStackPosition - 1
            self.layerStates.removeLast(diff)
        }

        self.currentStackPosition += 1
        self.layerStates.append(layerState)
        self.notifyLayerStateDidChange()
    }

    @discardableResult func discardRedoHistory() -> Bool {
        guard self.currentStackPosition < self.layerStates.count - 1 else { return false }

        let delta = (self.layerStates.count - 1) - self.currentStackPosition
        self.layerStates.removeLast(delta)
        return true
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
        return self.currentStackPosition + 1 < self.layerStates.count
    }

    var canUndo: Bool {
        return self.layerStates.hasElements && self.currentStackPosition > 0
    }


    // MARK: - Private

    private func notifyLayerStateDidChange() {
        self.delegate?.layerStateHistory(self, didUpdateHistory: self.currentLayerState, layerCountDidChange: true)

        NotificationCenter.default.post(name: Constants.layerStateHistoryDidChangeConstant, object: self)
    }
}


// MARK: - Constants used in Notifications

struct Constants {
    static let layerStateHistoryDidChangeConstant = NSNotification.Name(rawValue: "LayerStateHistoryDidChange")
}
