//
//  ExportController.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 18.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

protocol ExportControllerDelegate: class {
    func exportController(_ exportController: ExportController, didUpdateProgress progress: Double, file: String, layoutErrors: [LayoutError])
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

    @discardableResult
    func saveSingleImage(viewState: ViewState) -> [LayoutError] {
        self.shouldCancel = false

        let fileManager = FileManager()
        let viewStateController = ViewStateController(viewState: viewState)
        let layoutController = LayoutController(viewStateController: viewStateController, languageController: self.languageController, fileController: self.fileController)
        guard let view = layoutController.layouthierarchy(layers: self.lastLayerState.layers) else { return [.noLayers] }

        let data = view.pngData()
        guard let url = self.fileController.outputURL(for: self.lastLayerState, viewState: viewState) else { return [.noOutputFile] }

        try? fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        try? data?.write(to: url, options: .atomic)

        return layoutController.layoutErrors
    }

    @discardableResult
    func saveAllImages() -> [LayoutError] {
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
                guard let url = self.fileController.outputURL(for: self.lastLayerState, viewState: viewStateController.viewState) else { return [.noOutputFile] }

                try? fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                try? data?.write(to: url, options: .atomic)

                currentStep += 1
                let progress = Double(currentStep) / Double(totalSteps)
                self.delegate?.exportController(self, didUpdateProgress: self.shouldCancel ? 1.0 : progress, file: url.pathComponents.suffix(2).joined(separator: "/"), layoutErrors: layoutController.layoutErrors)

                if self.shouldCancel { break }
            }
        }

        return layoutController.layoutErrors
    }

    func preview(viewState: ViewState, name: String) {
        let firstImageNumber = self.lastLayerState.outputConfig.fromImageNumber
        let numberOfImages = self.lastLayerState.outputConfig.toImageNumber - firstImageNumber
        let frame = CGRect(x: 0,
                           y: 0,
                           width: self.lastLayerState.layers.first!.frame.width * CGFloat(numberOfImages + 1),
                           height: self.lastLayerState.layers.first!.frame.height)
        let view = NSView(frame: frame)

        let viewState = ViewState(selectedLayer: 0, imageNumber: 0, language: viewState.language)
        let tempViewStateController = ViewStateController(viewState: viewState)
        let tempLayoutController = LayoutController(viewStateController: tempViewStateController, languageController: self.languageController, fileController: self.fileController)

        for currentImageNumber in 0...numberOfImages {
            tempViewStateController.newViewState(imageNumber: currentImageNumber + firstImageNumber)

            guard let image = tempLayoutController.layouthierarchy(layers: self.lastLayerState.layers) else { continue }

            let offsetX = image.frame.width * CGFloat(currentImageNumber)
            image.frame = image.frame.offsetBy(dx: offsetX, dy: 0)
            view.addSubview(image)
        }

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Preview \(name).png")

        do {
            try view.pngData()?.write(to: tempURL)
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }

        NSWorkspace.shared.open(tempURL)
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
