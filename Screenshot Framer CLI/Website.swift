//
//  Website.swift
//  Screenshot-Framer-CLI
//
//  Created by Patrick Kladek on 25.11.21.
//  Copyright © 2021 Patrick Kladek. All rights reserved.
//

import AppKit
import ArgumentParser
import Foundation
import SwiftSoup

final class Website: ParsableCommand {

    @Option(help: "Root Folder of export", completion: .file(), transform: URL.init(fileURLWithPath:))
    var exportFolder: URL

    // MARK: - Export

    func run() throws {
        let builder = WebsiteBuilder(baseURL: self.exportFolder)
        let file = try builder.makeWebsite()
        NSWorkspace.shared.open(file)
    }
}
