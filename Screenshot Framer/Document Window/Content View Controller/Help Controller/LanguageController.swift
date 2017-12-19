//
//  LanguageController.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 12.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


final class LanguageController {

    // MARK: - Properties

    let document: Document


    // MARK: Init

    init(document: Document) {
        self.document = document
    }


    // MARK: Functions

    func allLanguages() -> [String] {
        let fileManager = FileManager()
        guard let url = self.document.documentRoot else { return [] }
        guard let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants) else { return [] }

        let allLanguages = Set(contents.filter { file in
            var isDir = ObjCBool(false)
            fileManager.fileExists(atPath: file.path, isDirectory: &isDir)
            return isDir.boolValue
        }.flatMap { $0.lastPathComponent }) as Set<String>

        let blackList: Set = ["backgrounds", "device_frames", "Export"]
        return Array(allLanguages.subtracting(blackList))
    }
}
