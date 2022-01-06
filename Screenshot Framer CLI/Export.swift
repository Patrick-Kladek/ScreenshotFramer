//
//  Export.swift
//  Screenshot-Framer-CLI
//
//  Created by Patrick Kladek on 25.11.21.
//  Copyright © 2021 Patrick Kladek. All rights reserved.
//

import ArgumentParser
import Foundation

final class Export: ParsableCommand {

    @Option(help: "Input file or folder", completion: .file(), transform: URL.init(fileURLWithPath:))
    var input: URL

    @Flag(help: "Ignore Warnings about potential issues like clipped text")
    var ignoreWarnings: Bool = false

    // MARK: - Export

    func validate() throws {
        guard FileManager.default.fileExists(atPath: self.input.path) else {
            throw ValidationError("'input' does not exist")
        }

        if self.input.isDirectory { return }

        if self.input.pathExtension != "frame" {
            throw ValidationError("'input' must either be a folder or .frame file")
        }
    }

    func run() throws {
        let projects: [URL]
        if self.input.isDirectory {
            let fileManager = FileManager()
            let contentOfDirectory = try fileManager.contentsOfDirectory(at: self.input, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
            projects = contentOfDirectory.filter { $0.pathExtension == "frame" }
        } else {
            projects = [self.input]
        }

        for project in projects {
            autoreleasepool {
                self.export(project: project)
            }
        }
    }
}

// MARK: - ExportControllerDelegate

extension Export: ExportControllerDelegate {

    func exportController(_ exportController: ExportController, didUpdateProgress progress: Double, file: String, layoutErrors: [LayoutError]) {
        ConsoleIO.writeMessage("export: \(String(format: "%3.0f", progress * 100))%\t\(file)", to: self.checkedErrors(layoutErrors).hasElements ? .error : .success)
    }
}


// MARK: - Private

extension Export {

    func layerStateHistory(for url: URL) -> LayerStateHistory? {
        let decoder = JSONDecoder()
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let layerStates = try? decoder.decode([LayerState].self, from: data) else { return nil }

        return LayerStateHistory(layerStates: layerStates, delegate: nil)
    }

    func export(project: URL) {
        let fileCapsule = FileCapsule()
        fileCapsule.projectURL = project.deletingLastPathComponent()

        guard let layerStateHistory = self.layerStateHistory(for: project) else { return }

        let fileController = FileController(fileCapsule: fileCapsule)
        let languageController = LanguageController(fileCapsule: fileCapsule)

        let exportController = ExportController(layerStateHistory: layerStateHistory, fileController: fileController, languageController: languageController)
        exportController.delegate = self

        ConsoleIO.writeMessage("Project: \(project.lastPathComponent)")
        let exportErrors = exportController.saveAllImages()

        if self.checkedErrors(exportErrors).hasElements {
            ConsoleIO.writeMessage("Something went wrong while exporting. Please check the projects for detailed information", to: .error)
            ConsoleIO.writeMessage("Here are the error codes:", to: .error)
            ConsoleIO.writeMessage("\(exportErrors.map { $0.rawValue }.joined(separator: "\n"))")
        }
    }

    func checkedErrors(_ errors: [LayoutError]) -> [LayoutError] {
        var exportErrors = errors

        if self.ignoreWarnings {
            exportErrors.remove(object: .fontTooBig)
        }

        return exportErrors
    }
}
