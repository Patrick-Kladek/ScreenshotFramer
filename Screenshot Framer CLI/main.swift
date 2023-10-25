//
//  main.swift
//  Screenshot Framer CLI
//
//  Created by Patrick Kladek on 29.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import ArgumentParser

struct ScreenshotFramer: ParsableCommand {

    static let configuration = CommandConfiguration(
        abstract: "A Swift command-line tool to frame localised screenshots for the AppStore",
        version: "2.0.1",
        subcommands: [Export.self, Website.self])
}

ScreenshotFramer.main()
