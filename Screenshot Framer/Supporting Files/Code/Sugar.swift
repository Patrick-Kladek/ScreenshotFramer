//
//  Sugar.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 22.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation


extension Collection {

    public var hasElements: Bool {
        return self.isEmpty == false
    }
}


extension Array where Element: Equatable {

    /**
     * Remove first collection element that is equal to the given `object`:
     */
    mutating func remove(object: Element) {
        if let index = firstIndex(of: object) {
            remove(at: index)
        }
    }
}


extension Array where Element == String {

    func subtracting(_ blacklist: Array, caseSensitive: Bool) -> Array {
        var newValues: [String] = []

        for element in self {
            if blacklist.contains(where: { (caseSensitive ? $0 : $0.lowercased()) == (caseSensitive ? element : element.lowercased()) }) == false {
                // No match in blacklist -> add item
                newValues.append(element)
            }
        }

        return newValues
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

extension FileManager {

    func contentsOfDirectory(at url: URL, recursive: Bool) throws -> [URL] {
        if recursive == false {
            return try self.contentsOfDirectory(atPath: url.path).map { URL(fileURLWithPath: $0) }
        }

        var files: [URL] = []
        if let enumerator = FileManager.default.enumerator(at: url,
                                                           includingPropertiesForKeys: [.isRegularFileKey],
                                                           options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                let fileAttributes = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                if fileAttributes.isRegularFile! {
                    files.append(fileURL)
                }
            }
        }
        return files
    }
}
