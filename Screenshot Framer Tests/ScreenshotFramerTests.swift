//
//  ScreenshotFramerTests.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 06.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import XCTest


class ScreenshotFramerTests: XCTestCase {

    var layerStateHistory: LayerStateHistory!

    override func setUp() {
        super.setUp()

        self.layerStateHistory = LayerStateHistory()

        let layerState = LayerState(title: "First Operation",
                                    layers: [LayoutableObject(type: .background, title: "Background", frame: CGRect(x: 0, y: 0, width: 800, height: 1200), file: "")],
                                    outputConfig: OutputConfig(transparent: false, output: "", fromImageNumber: 1, toImageNumber: 5))
        self.layerStateHistory.append(layerState)
    }

    func testSetup() {
        // 2: because it is guranted that layerStates has at least 1 LayerState (Initial Operation) and we added a new LayerState in setUp (First Operation)
        XCTAssert(self.layerStateHistory.layerStates.count == 2)
    }

    func testAddLayerState() {
        let newLayer = LayoutableObject(type: .device, title: "Device Frame", frame: CGRect(x: 100, y: 100, width: 600, height: 800), file: "iPhone X")

        let currentLayerState = self.layerStateHistory.currentLayerState
        _ = currentLayerState.addingLayer(newLayer)

        self.layerStateHistory.append(currentLayerState)

        XCTAssert(self.layerStateHistory.layerStates.count == 3)
    }

    func testCaseSensitiveSubstractingOfArray() {
        let blacklist = ["backgrounds", "device_frames", "Export"]
        let folders = ["de-DE", "Export", "Backgrounds"]

        let result = folders.subtracting(blacklist, caseSensitive: true)
        XCTAssertEqual(result, ["de-DE", "Backgrounds"])
    }

    func testCaseInsensitiveSubstractingOfArray() {
        let blacklist = ["backgrounds", "device_frames", "Export"]
        let folders = ["de-DE", "Export", "Backgrounds"]

        let result = folders.subtracting(blacklist, caseSensitive: false)
        XCTAssertEqual(result, ["de-DE"])
    }
}
