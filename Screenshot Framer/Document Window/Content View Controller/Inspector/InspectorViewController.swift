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
    private let languageController: LanguageController

    let viewStateController: ViewStateController
    var selectedRow: Int = -1 {
        didSet {
            self.updateUI()
        }
    }


    // MARK: - Interface Builder

    @IBOutlet weak var textFieldImageNumber: NSTextField!
    @IBOutlet weak var stepperImageNumber: NSStepper!

    @IBOutlet weak var languages: NSPopUpButton!

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
    @IBOutlet weak var textFieldFontSize: NSTextField!
    @IBOutlet weak var stepperFontSize: NSStepper!


    // MARK: - Lifecycle

    init(layerStateHistory: LayerStateHistory, selectedRow: Int, viewStateController: ViewStateController, languageController: LanguageController) {
        self.layerStateHistory = layerStateHistory
        self.selectedRow = selectedRow
        self.viewStateController = viewStateController
        self.languageController = languageController
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

        if let fontString = layoutableObject.font {
            self.textFieldFont.stringValue = fontString
        }

        if let fontSize = layoutableObject.fontSize {
            self.textFieldFontSize.doubleValue = Double(fontSize)
            self.stepperFontSize.doubleValue = self.textFieldFontSize.doubleValue
        }

        let selectedLanguage = self.languages.titleOfSelectedItem
        self.languages.removeAllItems()
        let allLanguages = self.languageController.allLanguages()
        self.languages.addItems(withTitles: allLanguages)
        if selectedLanguage != nil {
            self.languages.selectItem(withTitle: selectedLanguage!)
        } else {
            self.languages.selectItem(withTitle: "en-US")
        }
    }

    
    // MARK: - Actions

    @IBAction func stepperPressed(sender: NSStepper) {
        self.textFieldImageNumber.integerValue = self.stepperImageNumber.integerValue
        self.textFieldX.doubleValue = self.stepperX.doubleValue
        self.textFieldY.doubleValue = self.stepperY.doubleValue
        self.textFieldWidth.doubleValue = self.stepperWidth.doubleValue
        self.textFieldHeight.doubleValue = self.stepperHeight.doubleValue
        self.textFieldFontSize.doubleValue = self.stepperFontSize.doubleValue

        switch sender {
        case self.stepperImageNumber:
            let imageNumber = self.textFieldImageNumber.integerValue
            self.viewStateController.newViewState(imageNumber: imageNumber)

        case self.stepperFontSize:
            self.updateFontSize()

        default:
            self.updateFrame()
        }
    }

    @IBAction func textFieldChanged(sender: NSTextField) {
        switch sender {
        case self.textFieldFile:
            let file = self.textFieldFile.stringValue
            let operation = UpdateFileOperation(layerStateHistory: self.layerStateHistory, file: file, indexOfLayer: self.selectedRow)
            operation.apply()

        case self.textFieldImageNumber:
            let imageNumber = self.textFieldImageNumber.integerValue
            self.viewStateController.newViewState(imageNumber: imageNumber)

        case self.textFieldFont:
            let font = self.textFieldFont.stringValue
            let operation = UpdateFontOperation(layerStateHistory: self.layerStateHistory, font: font, indexOfLayer: self.selectedRow)
            operation.apply()

        case self.textFieldFontSize:
            self.updateFontSize()

        default:
            self.updateFrame()
        }
    }

    @IBAction func popupDidChange(sender: NSPopUpButton) {
        if sender == self.languages {
            self.viewStateController.newViewState(language: self.languages.titleOfSelectedItem ?? "en-US")
        }
    }
}


// MARK: Private

private extension InspectorViewController {

    func updateFrame() {
        let frame = CGRect(x: self.textFieldX.doubleValue,
                           y: self.textFieldY.doubleValue,
                           width: self.textFieldWidth.doubleValue,
                           height: self.textFieldHeight.doubleValue)

        let operation = UpdateFrameOperation(layerStateHistory: self.layerStateHistory, frame: frame, indexOfLayer: self.selectedRow)
        operation.apply()
    }

    func updateFontSize() {
        let fontSize = CGFloat(self.textFieldFontSize.floatValue)
        let operation = UpdateFontSizeOperation(layerStateHistory: self.layerStateHistory, fontSize: fontSize, indexOfLayer: self.selectedRow)
        operation.apply()
    }
}
