//
//  InspectorViewController.swift
//  Framer
//
//  Created by Patrick Kladek on 29.11.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


final class InspectorViewController: NSViewController {

    // MARK: - Properties
    private let layerStateHistory: LayerStateHistory

    let viewStateController: ViewStateController
    var selectedRow: Int = -1 {
        didSet {
            self.updateUI()
        }
    }


    // MARK: - Interface Builder
    @IBOutlet weak var textFieldImageNumber: NSTextField!
    @IBOutlet weak var stepperImageNumber: NSStepper!

    @IBOutlet weak var textFieldFile: NSTextField!

    @IBOutlet weak var textFieldX: NSTextField!
    @IBOutlet weak var stepperX: NSStepper!

    @IBOutlet weak var textFieldY: NSTextField!
    @IBOutlet weak var stepperY: NSStepper!

    @IBOutlet weak var textFieldWidth: NSTextField!
    @IBOutlet weak var stepperWidth: NSStepper!

    @IBOutlet weak var textFieldHeight: NSTextField!
    @IBOutlet weak var stepperHeight: NSStepper!

    @IBOutlet weak var textFieldFont: NSTextField!


    // MARK: - Lifecycle

    init(layerStateHistory: LayerStateHistory, selectedRow: Int, viewStateController: ViewStateController) {
        self.layerStateHistory = layerStateHistory
        self.selectedRow = selectedRow
        self.viewStateController = viewStateController
        super.init(nibName: NSNib.Name(rawValue: String(describing: type(of: self))), bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Update Methods

    func updateUI() {
        guard self.selectedRow >= 0 else { return }

        let layoutableObject = self.layerStateHistory.currentLayerState.layers[self.selectedRow]

        self.textFieldX.isEnabled = layoutableObject.isRoot == false
        self.stepperX.isEnabled = layoutableObject.isRoot == false
        self.textFieldY.isEnabled = layoutableObject.isRoot == false
        self.stepperY.isEnabled = layoutableObject.isRoot == false

        self.textFieldX.doubleValue = Double(layoutableObject.frame.origin.x)
        self.stepperX.doubleValue = self.textFieldX.doubleValue
        self.textFieldY.doubleValue = Double(layoutableObject.frame.origin.y)
        self.stepperY.doubleValue = self.textFieldY.doubleValue
        self.textFieldWidth.doubleValue = Double(layoutableObject.frame.size.width)
        self.stepperWidth.doubleValue = self.textFieldWidth.doubleValue
        self.textFieldHeight.doubleValue = Double(layoutableObject.frame.size.height)
        self.stepperHeight.doubleValue = self.textFieldHeight.doubleValue

        self.textFieldFile.stringValue = layoutableObject.file

        if let font = layoutableObject.font {
            self.textFieldFont.stringValue = font
        }
    }

    func updateFrame() {
        let frame = CGRect(x: self.textFieldX.doubleValue,
                           y: self.textFieldY.doubleValue,
                           width: self.textFieldWidth.doubleValue,
                           height: self.textFieldHeight.doubleValue)

        let operation = UpdateFrameOperation(layerStateHistory: self.layerStateHistory, frame: frame, indexOfLayer: self.selectedRow)
        operation.apply()
    }

    // MARK: - Actions

    @IBAction func stepperPressed(sender: NSStepper) {
        self.textFieldImageNumber.integerValue = self.stepperImageNumber.integerValue
        self.textFieldX.doubleValue = self.stepperX.doubleValue
        self.textFieldY.doubleValue = self.stepperY.doubleValue
        self.textFieldWidth.doubleValue = self.stepperWidth.doubleValue
        self.textFieldHeight.doubleValue = self.stepperHeight.doubleValue

        if sender == self.stepperImageNumber {
            self.viewStateController.viewState = ViewState(imageNumber: self.textFieldImageNumber.integerValue)
        } else {
            self.updateFrame()
        }
    }

    @IBAction func textFieldChanged(sender: NSTextField) {
        if sender == self.textFieldFile {
            let file = self.textFieldFile.stringValue
            let operation = UpdateFileOperation(layerStateHistory: self.layerStateHistory, file: file, indexOfLayer: self.selectedRow)
            operation.apply()
        } else if sender == self.textFieldImageNumber {
            self.viewStateController.viewState = ViewState(imageNumber: self.textFieldImageNumber.integerValue)
        } else {
            self.updateFrame()
        }
    }
}
