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

    // MARK: - Lifecycle

    init(fileCapsule: FileCapsule) {
        self.fileCapsule = fileCapsule
    }

    // MARK: - LanguageController

    func allLanguages(prefered: String? = nil) -> [String] {
        let fileManager = FileManager()
        guard let projectURL = self.fileCapsule.projectRoot else { return [] }
        guard let contents = try? fileManager.contentsOfDirectory(at: projectURL, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]) else { return [] }

        let allLanguages = contents.filter { file in
            var isDir = ObjCBool(false)
            fileManager.fileExists(atPath: file.path, isDirectory: &isDir)
            return isDir.boolValue
        }.compactMap { $0.lastPathComponent }

        let blackList = ["backgrounds", "device_frames", "export"]
        let filteredLanguages = allLanguages.subtracting(blackList, caseSensitive: false)
        if let prefered = prefered {
            if filteredLanguages.contains(where: { $0.caseInsensitiveCompare(prefered) == .orderedSame }) {
                return [prefered]
            }
        }
        return filteredLanguages
    }
}
