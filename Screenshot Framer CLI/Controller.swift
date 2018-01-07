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
    private var ignoreFontToBig = false

    // MARK: - Lifecycle

    init(arguments: [String]) {
        self.arguments = arguments
    }

    // MARK: - Functions

    func run() -> ExitStatus {
        func parseParameterFailed() {
            self.console.writeMessage("Wrong Parameters", to: .error)
            self.console.printUsage()
        }

        self.ignoreFontToBig = self.arguments.filter { $0 == "-ignoreFontToBig" }.hasElements
        guard let index = self.arguments.index(of: "-project") else { parseParameterFailed(); return .wrongArguments }
        guard self.arguments.count >= index + 1 else { parseParameterFailed(); return .wrongArguments }


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

        return status
    }
}


// MARK: - ExportControllerDelegate

extension Controller: ExportControllerDelegate {

    func exportController(_ exportController: ExportController, didUpdateProgress progress: Double, file: String, layoutErrors: [LayoutError]) {
        var errors = layoutErrors

        if self.ignoreFontToBig {
            errors.remove(object: .fontToBig)
        }

        self.console.writeMessage("export: \(String(format: "%3.0f", progress * 100))%\t\(file)", to: errors.hasElements ? .error : .success)
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

        var exportErrors = exportController.saveAllImages()

        if self.ignoreFontToBig {
            exportErrors.remove(object: .fontToBig)
        }

        if exportErrors.hasElements {
            self.console.writeMessage("Something went wrong while exporting. Please check the projects for detailed information", to: .error)
            self.console.writeMessage("Here are the error codes:", to: .error)
            self.console.writeMessage("\(exportErrors.map { $0.rawValue }.joined(separator: "\n"))")

        }

        return .noError
    }
}
