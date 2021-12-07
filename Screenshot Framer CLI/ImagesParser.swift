//
//  ImagesParser.swift
//  Screenshot-Framer-CLI
//
//  Created by Patrick Kladek on 07.12.21.
//  Copyright © 2021 Patrick Kladek. All rights reserved.
//

import Foundation

final class ImagesParser {
    struct Language {
        struct Group {
            struct Image {
                let url: URL
                var filename: String {
                    return self.url.lastPathComponent
                }
            }
            let images: [Image]
            let name: String
        }
        let groups: [Group]
        let language: String
    }

    private let fileManager = FileManager()

    // MARK: - ImagesParser

    func languages(in folder: URL) throws -> [Language] {
        let fileManager = FileManager()
        let languageFolders = try fileManager.contentsOfDirectory(at: folder,
                                                            includingPropertiesForKeys: [.isDirectoryKey],
                                                            options: [.skipsHiddenFiles, .skipsPackageDescendants, .producesRelativePathURLs])
            .filter { $0.hasDirectoryPath }

        let languages = try languageFolders.map { try self.contents(in: $0) }
        return languages
    }
}

// MARK: - Private

extension ImagesParser {

    func contents(in folder: URL) throws -> Language {
        struct Screenshot: CustomDebugStringConvertible {
            let url: URL
            let device: String
            let number: String

            init?(url: URL) {
                self.url = url

                let elements = url.lastPathComponent.components(separatedBy: CharacterSet(charactersIn: " -")).filter { $0 != "" }
                guard elements.count >= 2 else { return nil }

                self.device = elements[0...elements.count - 2].joined(separator: " ")
                self.number = elements.last!
            }

            var debugDescription: String {
                return "\(self.device) \(self.number)"
            }
        }

        let contents = try self.fileManager.contentsOfDirectory(at: folder,
                                                                includingPropertiesForKeys: [.isRegularFileKey],
                                                                options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])

        let relative = contents.compactMap { $0.relativeURL(from: folder.deletingLastPathComponent()) }
        let sorted = relative.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
        let screenshots = sorted.compactMap { Screenshot(url: $0) }
        let devices = Set(screenshots.map { $0.device })


        var groups: [Language.Group] = []
        for device in devices {
            let images = screenshots.filter { $0.device == device }.map { Language.Group.Image(url: $0.url) }
            groups.append(Language.Group(images: images, name: device))
        }

        return Language(groups: groups, language: folder.lastPathComponent)
    }
}

extension URL {

    func relativeURL(from base: URL) -> URL? {
        guard let path = self.relativePath(from: base) else { return nil }

        return URL(fileURLWithPath: path, relativeTo: base)
    }

    func relativePath(from base: URL) -> String? {
        // Ensure that both URLs represent files:
        guard self.isFileURL && base.isFileURL else {
            return nil
        }

        // Remove/replace "." and "..", make paths absolute:
        let destComponents = self.standardized.pathComponents
        let baseComponents = base.standardized.pathComponents

        // Find number of common path components:
        var index = 0
        while index < destComponents.count && index < baseComponents.count
                && destComponents[index] == baseComponents[index] {
            index += 1
        }

        // Build relative path:
        var relComponents = Array(repeating: "..", count: baseComponents.count - index)
        relComponents.append(contentsOf: destComponents[index...])
        return relComponents.joined(separator: "/")
    }
}
