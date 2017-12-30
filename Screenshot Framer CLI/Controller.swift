//
//  Controller.swift
//  Screenshot Framer CLI
//
//  Created by Patrick Kladek on 29.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation


enum ExitStatus {
    case noError
    case wrongArguments
    case readError
}


final class Controller {

    // MARK: - Properties

    private let arguments: [String]
    private let console = ConsoleIO()


    // MARK: - Lifecycle

    init(arguments: [String]) {
        self.arguments = arguments
    }

    // MARK: - Functions

    func run() -> ExitStatus {
        if self.arguments.count != 3 || self.arguments[1] != "-project" {
            self.console.writeMessage("Wrong Parameters", to: .error)
            self.console.printUsage()
            return .wrongArguments
        }

        let documentURL = URL(fileURLWithPath: self.arguments[2])
        let fileCapsule = FileCapsule()
        fileCapsule.projectURL = documentURL.deletingLastPathComponent()

        guard let layerStateHistory = self.layerStateHistory(for: documentURL) else { return .readError }

        let fileController = FileController(fileCapsule: fileCapsule)
        let languageController = LanguageController(fileCapsule: fileCapsule)

        let exportController = ExportController(layerStateHistory: layerStateHistory, fileController: fileController, languageController: languageController)
        exportController.delegate = self
        exportController.saveAllImages()

        return .noError
    }
}

// MARK: - ExportControllerDelegate

extension Controller: ExportControllerDelegate {

    func exportController(_ exportController: ExportController, didUpdateProgress progress: Double) {
        self.console.writeMessage("export: \(progress * 100)%")
    }
}


// MARK: - Private

extension Controller {

    func layerStateHistory(for url: URL) -> LayerStateHistory? {
        let decoder = JSONDecoder()
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let layerStates = try? decoder.decode([LayerState].self, from: data) else { return nil }

        return LayerStateHistory(layerStates: layerStates, delegate: nil)
    }
}
