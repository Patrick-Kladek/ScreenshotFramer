//
//  FileController.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 15.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation

/**
 * This class stores properties that are not known on init
 * projectRoot ist only set after a new document is saved
 * most classes need the projectRoot property but not directly
 * on init but later eg export
 */
final class FileCapsule {

    var projectRoot: URL?
    var projectFile: URL?
}


final class FileController {

    // MARK: - Properties

    let fileCapsule: FileCapsule


    // MARK: Lifecycle

    init(fileCapsule: FileCapsule) {
        self.fileCapsule = fileCapsule
    }


    // MARK: - Functions

    func absoluteURL(for object: LayoutableObject, viewState: ViewState) -> URL? {
        guard object.file.hasElements else { return nil }

        var file = object.file.replacingOccurrences(of: "$image", with: "\(viewState.imageNumber)")
        file = file.replacingOccurrences(of: "$language", with: viewState.language)

        if let projectURL = fileCapsule.projectRoot {
            file = file.replacingOccurrences(of: "$filename", with: projectURL.deletingPathExtension().lastPathComponent)
        }

        let absoluteURL = self.fileCapsule.projectRoot?.appendingPathComponent(file)
        return absoluteURL
    }

    func localizedTitle(from url: URL?, viewState: ViewState) -> String? {
        guard let url = url else { return nil }
        guard let dict = NSDictionary(contentsOf: url) else { return nil }

        let value = dict["\(viewState.imageNumber)"] as? String
        return value
    }

    func outputURL(for layerState: LayerState, viewState: ViewState) -> URL? {
        guard let base = self.fileCapsule.projectRoot else { return nil }
        var file = layerState.outputConfig.output.replacingOccurrences(of: "$image", with: "\(viewState.imageNumber)")
        file = file.replacingOccurrences(of: "$language", with: viewState.language)

        if let projectFile = fileCapsule.projectFile {
            file = file.replacingOccurrences(of: "$filename", with: projectFile.deletingPathExtension().lastPathComponent)
        }

        return base.appendingPathComponent(file)
    }
}
