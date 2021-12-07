//
//  ImagesParser.swift
//  Screenshot-Framer-CLI
//
//  Created by Patrick Kladek on 07.12.21.
//  Copyright © 2021 Patrick Kladek. All rights reserved.
//

import Foundation

final class ImagesParser {

    struct Group {
        struct Image {
            let url: URL
            var filename: String {
                return self.url.lastPathComponent
            }
            var caption: String {
                return self.url.deletingLastPathComponent().lastPathComponent
            }
        }
        let images: [Image]
        let name: String
    }

    struct Language {
        let groups: [Group]
        let language: String
    }

    struct Screen {
        let groups: [Group]
        let name: String
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

    func screens(in folder: URL) throws -> [Screen] {
        let files = try FileManager.default.contentsOfDirectory(at: folder, recursive: true)
        let filtered = files.filter { $0.pathExtension == "png" || $0.pathExtension == "jpg" }
        let relative = filtered.compactMap { $0.relativeURL(from: folder) }
        let screenshots = relative.compactMap { Screenshot(url: $0) }
        let numbers = Set(screenshots.map { $0.number }).sorted()

        var screens: [Screen] = []
        for number in numbers {
            let imagesInScreen = screenshots.filter { $0.number == number }
            let devices = Set(imagesInScreen.map { $0.device }).sorted()
            var groups: [Group] = []
            for device in devices {
                let images = imagesInScreen.filter { $0.device == device }.map { Group.Image(url: $0.url) }
                groups.append(Group(images: images, name: device))
            }
            screens.append(Screen(groups: groups, name: number))
        }

        return screens
    }
}

// MARK: - Private

private extension ImagesParser {

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

    func contents(in folder: URL) throws -> Language {
        let contents = try self.fileManager.contentsOfDirectory(at: folder,
                                                                includingPropertiesForKeys: [.isRegularFileKey],
                                                                options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])

        let relative = contents.compactMap { $0.relativeURL(from: folder.deletingLastPathComponent()) }
        let sorted = relative.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
        let screenshots = sorted.compactMap { Screenshot(url: $0) }
        let devices = Set(screenshots.map { $0.device }).sorted()

        var groups: [Group] = []
        for device in devices {
            let images = screenshots.filter { $0.device == device }.map { Group.Image(url: $0.url) }
            groups.append(Group(images: images, name: device))
        }

        return Language(groups: groups, language: folder.lastPathComponent)
    }
}
