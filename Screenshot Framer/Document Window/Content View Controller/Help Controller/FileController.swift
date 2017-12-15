//
//  FileController.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 15.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation


final class FileController {

    // MARK: - Properties

    let document: Document


    // MARK: Lifecycle

    init(document: Document) {
        self.document = document
    }


    // MARK: - Functions

    func absoluteURL(for object: LayoutableObject, viewState: ViewState) -> URL? {
        guard object.file.count > 0 else { return nil }

        var file = object.file.replacingOccurrences(of: "$image", with: "\(viewState.imageNumber)")
        file = file.replacingOccurrences(of: "$language", with: viewState.language)

        let absoluteURL = self.document.documentRoot?.appendingPathComponent(file)
        return absoluteURL
    }

    func localizedTitle(from url: URL?, viewState: ViewState) -> String? {
        guard let url = url else { return nil }
        guard let dict = NSDictionary(contentsOf: url) else { return nil }

        let value = dict["\(viewState.imageNumber)"] as? String
        return value
    }

    func outputURL(for layerState: LayerState, viewState: ViewState) -> URL? {
        guard let base = self.document.documentRoot else { return nil }
        var file = layerState.output.replacingOccurrences(of: "$image", with: "\(viewState.imageNumber)")
        file = file.replacingOccurrences(of: "$language", with: viewState.language)

        return base.appendingPathComponent(file)
    }
}
