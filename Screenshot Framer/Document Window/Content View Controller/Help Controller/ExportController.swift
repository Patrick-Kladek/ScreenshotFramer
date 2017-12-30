//
//  ExportController.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 18.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

protocol ExportControllerDelegate: class {
    func exportController(_ exportController: ExportController, didUpdateProgress progress: Double)
}


final class ExportController {

    // MARK: - Properties

    private var shouldCancel: Bool = false
    let fileController: FileController
    let languageController: LanguageController
    let layerStateHistory: LayerStateHistory
    weak var delegate: ExportControllerDelegate?

    var lastLayerState: LayerState { return self.layerStateHistory.currentLayerState }


    // MARK: - Lifecycle

    init(layerStateHistory: LayerStateHistory, fileController: FileController, languageController: LanguageController) {
        self.layerStateHistory = layerStateHistory
        self.fileController = fileController
        self.languageController = languageController
    }


    // MARK: - functions

    func saveSingleImage(viewState: ViewState) {
        self.shouldCancel = false

        let viewStateController = ViewStateController(viewState: viewState)
        let layoutController = LayoutController(viewStateController: viewStateController, languageController: self.languageController, fileController: self.fileController)
        guard let view = layoutController.layouthierarchy(layers: self.lastLayerState.layers) else { return }

        let data = view.pngData()
        guard let url = self.fileController.outputURL(for: self.lastLayerState, viewState: viewState) else { return }

        try? data?.write(to: url, options: .atomic)
    }

    func saveAllImages() {
        self.shouldCancel = false

        let viewStateController = ViewStateController()
        let layoutController = LayoutController(viewStateController: viewStateController, languageController: self.languageController, fileController: self.fileController)
        let fileManager = FileManager()

        let totalSteps = self.calculatePossibleComabinations(languageController: self.languageController)
        var currentStep = 0

        for language in self.languageController.allLanguages() {
            viewStateController.newViewState(language: language)
            for index in self.lastLayerState.outputConfig.fromImageNumber...self.lastLayerState.outputConfig.toImageNumber {
                viewStateController.newViewState(imageNumber: index)
                guard let view = layoutController.layouthierarchy(layers: self.lastLayerState.layers) else { continue }           // TODO: is called from a background thread

                let data = view.pngData()
                guard let url = self.fileController.outputURL(for: self.lastLayerState, viewState: viewStateController.viewState) else { return }

                try? fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                try? data?.write(to: url, options: .atomic)

                currentStep += 1
                let progress = Double(currentStep) / Double(totalSteps)
                self.delegate?.exportController(self, didUpdateProgress: self.shouldCancel ? 1.0 : progress)
            }
        }
    }

    func cancel() {
        self.shouldCancel = true
    }
}

private extension ExportController {

    func calculatePossibleComabinations(languageController: LanguageController) -> Int {
        let outputConfig = self.lastLayerState.outputConfig

        // because we use a for-loop and `for n in 1...1` would
        // mean 1 execution but (1 - 1 = 0) we handle this special case
        // by adding +1 so the progressBar is still updated correctly
        let totalSteps = outputConfig.toImageNumber - outputConfig.fromImageNumber + 1

        return languageController.allLanguages().count * totalSteps
    }
}
