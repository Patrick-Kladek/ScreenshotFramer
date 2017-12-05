//
//  InspectorViewController.swift
//  Framer
//
//  Created by Patrick Kladek on 29.11.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

class InspectorViewController: NSViewController {

    // MARK: - Properties
    private let layerStateHistory: LayerStateHistory

    var selectedRow: Int = 0 {
        didSet {
            self.updateUI()
        }
    }


    // MARK: - Interface Builder

    @IBOutlet weak var textFieldFile: NSTextField!

    @IBOutlet weak var textFieldX: NSTextField!
    @IBOutlet weak var stepperX: NSStepper!

    @IBOutlet weak var textFieldY: NSTextField!
    @IBOutlet weak var stepperY: NSStepper!

    @IBOutlet weak var textFieldWidth: NSTextField!
    @IBOutlet weak var stepperWidth: NSStepper!

    @IBOutlet weak var textFieldHeight: NSTextField!
    @IBOutlet weak var stepperHeight: NSStepper!


    // MARK: - Lifecycle

    init(layerStateHistory: LayerStateHistory, selectedRow: Int) {
        self.layerStateHistory = layerStateHistory
        self.selectedRow = selectedRow
        super.init(nibName: NSNib.Name(rawValue: String(describing: type(of: self))), bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    func updateUI() {
        let layoutableObject = self.layerStateHistory.lastLayerState.layers[self.selectedRow]

        self.textFieldX.doubleValue = Double(layoutableObject.frame.origin.x)
        self.textFieldY.doubleValue = Double(layoutableObject.frame.origin.y)
        self.textFieldWidth.doubleValue = Double(layoutableObject.frame.size.width)
        self.textFieldHeight.doubleValue = Double(layoutableObject.frame.size.height)
    }

    @IBAction func stepperPressed(sender: NSStepper) {
        self.textFieldX.doubleValue = self.stepperX.doubleValue
        self.textFieldY.doubleValue = self.stepperY.doubleValue
        self.textFieldWidth.doubleValue = self.stepperWidth.doubleValue
        self.textFieldHeight.doubleValue = self.stepperHeight.doubleValue

        self.syncModel(sender: self.textFieldX)
    }

    func syncModel(sender: NSTextField) {
        if sender == self.textFieldX ||
            sender == self.textFieldY ||
            sender == self.textFieldWidth ||
            sender == self.textFieldHeight {
            let frame = CGRect(x: self.textFieldX.doubleValue,
                               y: self.textFieldY.doubleValue,
                               width: self.textFieldWidth.doubleValue,
                               height: self.textFieldHeight.doubleValue)

            let lastLayerState = self.layerStateHistory.lastLayerState
            guard let newLayerState = lastLayerState.updating(frame: frame, layer: self.selectedRow) else { return }

            self.layerStateHistory.append(newLayerState)
            self.updateUI()
        }
    }

    @IBAction func textFieldChanged(sender: NSTextField) {
        if sender == self.textFieldFile {

        } else {
            self.syncModel(sender: self.textFieldX)
        }
    }
}
