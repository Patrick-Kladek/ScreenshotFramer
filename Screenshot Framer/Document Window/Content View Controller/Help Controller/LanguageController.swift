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

    let fileCapsule: FileCapsule


    // MARK: Init

    init(fileCapsule: FileCapsule) {
        self.fileCapsule = fileCapsule
    }


    // MARK: Functions

    func allLanguages() -> [String] {
        let fileManager = FileManager()
        guard let projectURL = self.fileCapsule.projectURL else { return [] }
        guard let contents = try? fileManager.contentsOfDirectory(at: projectURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants) else { return [] }

        let allLanguages = Set(contents.filter { file in
            var isDir = ObjCBool(false)
            fileManager.fileExists(atPath: file.path, isDirectory: &isDir)
            return isDir.boolValue
        }.compactMap { $0.lastPathComponent }) as Set<String>

        let blackList: Set = ["backgrounds", "device_frames", "Export"]
        return Array(allLanguages.subtracting(blackList))
    }
}
