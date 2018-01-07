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

        let fileManager = FileManager()
        let documentURL = URL(fileURLWithPath: self.arguments[2])

        var isDir: ObjCBool = false
        fileManager.fileExists(atPath: documentURL.path, isDirectory: &isDir)

        let projects: [URL]
        if isDir.boolValue {
            guard let contentOfDirectory = try? fileManager.contentsOfDirectory(at: documentURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]) else { return .readError }
            projects = contentOfDirectory.filter { $0.pathExtension == "frame" }
        } else {
            projects = [documentURL]
        }

        var status: ExitStatus = .noError
        for project in projects {
            let exit = self.export(project: project)
            if exit != .noError {
                status = exit
            }
        }

        if status == .noError {
            self.console.writeMessage("Export Successful", to: .standard)
        }
        return status
    }
}


// MARK: - ExportControllerDelegate

extension Controller: ExportControllerDelegate {

    func exportController(_ exportController: ExportController, didUpdateProgress progress: Double) {
        self.console.writeMessage("export: \(progress * 100)%", to: .success)
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

    func export(project: URL) -> ExitStatus {
        let fileCapsule = FileCapsule()
        fileCapsule.projectURL = project.deletingLastPathComponent()

        guard let layerStateHistory = self.layerStateHistory(for: project) else { return .readError }

        let fileController = FileController(fileCapsule: fileCapsule)
        let languageController = LanguageController(fileCapsule: fileCapsule)

        let exportController = ExportController(layerStateHistory: layerStateHistory, fileController: fileController, languageController: languageController)
        exportController.delegate = self

        self.console.writeMessage("Project: \(project.lastPathComponent)")

        exportController.saveAllImages()

        return .noError
    }
}
