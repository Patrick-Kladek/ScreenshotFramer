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
    let document: Document
    let fileController: FileController
    let languageController: LanguageController
    weak var delegate: ExportControllerDelegate?

    var layerStateHistory: LayerStateHistory { return self.document.layerStateHistory }
    var lastLayerState: LayerState { return self.layerStateHistory.currentLayerState}


    // MARK: - Lifecycle

    init(document: Document, fileController: FileController, languageController: LanguageController) {
        self.document = document
        self.fileController = fileController
        self.languageController = languageController
    }


    // MARK: - functions

    func saveSingleImage(viewState: ViewState) {
        self.shouldCancel = false

        let viewStateController = ViewStateController(viewState: viewState)
        let layoutController = LayoutController(document: self.document, layerStateHistory: self.layerStateHistory, viewStateController: viewStateController, languageController: self.languageController, fileController: self.fileController)
        guard let view = layoutController.layouthierarchy() else { return }

        let data = view.pngData()
        guard let url = self.fileController.outputURL(for: self.lastLayerState, viewState: viewState) else { return }

        try? data?.write(to: url, options: .atomic)
    }

    func saveAllImages() {
        self.shouldCancel = false
        
        let viewStateController = ViewStateController()
        let layoutController = LayoutController(document: self.document, layerStateHistory: self.layerStateHistory, viewStateController: viewStateController, languageController: self.languageController, fileController: self.fileController)
        let fileManager = FileManager()

        let totalSteps = self.calculatePossibleComabinations(languageController: self.languageController)
        var currentStep = 0

        for language in self.languageController.allLanguages() {
            viewStateController.newViewState(language: language)
            for index in 1...5 {
                currentStep += 1
                let progress = Double(currentStep)/Double(totalSteps)
                self.delegate?.exportController(self, didUpdateProgress: self.shouldCancel ? 1.0 : progress)

                viewStateController.newViewState(imageNumber: index)
                guard let view = layoutController.layouthierarchy() else { continue }           // TODO: is called from a background thread

                let data = view.pngData()
                guard let url = self.fileController.outputURL(for: self.lastLayerState, viewState: viewStateController.viewState) else { return }

                try? fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                try? data?.write(to: url, options: .atomic)
            }
        }
    }

    func cancel() {
        self.shouldCancel = true
    }
}

private extension ExportController {

    func calculatePossibleComabinations(languageController: LanguageController) -> Int {
        return languageController.allLanguages().count * 5
    }
}


