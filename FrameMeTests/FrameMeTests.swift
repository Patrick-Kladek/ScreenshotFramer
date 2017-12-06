//
//  FrameMeTests.swift
//  FrameMeTests
//
//  Created by Patrick Kladek on 06.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import XCTest


class FrameMeTests: XCTestCase {

    var layerStateHistory: LayerStateHistory!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        self.layerStateHistory = LayerStateHistory()

        let layerState = LayerState(title: "First Operation", layers: [LayoutableObject(title: "Background", frame: CGRect(x: 0, y: 0, width: 800, height: 1200), file: "", isRoot: true)])
        self.layerStateHistory.append(layerState)
    }

    func testSetup() {
        // 2: because we it is guranted that layerStates has at least 1 LayerState (Initial Operation) and we added a new LayerState
        XCTAssert(self.layerStateHistory.layerStates.count == 2)
    }

    func testAddLayerState() {
        let newLayer = LayoutableObject(title: "Device Frame", frame: CGRect(x: 100, y: -100, width: 600, height: 800), file: "iPhone X", isRoot: false)

        let currentLayerState = self.layerStateHistory.currentLayerState
        _ = currentLayerState.addingLayer(newLayer)

        self.layerStateHistory.append(currentLayerState)

        XCTAssert(self.layerStateHistory.layerStates.count == 3)
    }
    
}
