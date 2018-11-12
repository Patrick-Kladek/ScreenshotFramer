//
//  InspectorViewController.swift
//  Framer
//
//  Created by Patrick Kladek on 29.11.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


/// These Methods are called frequently and therefore only modify exiting layers
protocol InspectorViewControllerDelegate: class {
    func inspector(_ inspector: InspectorViewController, requestRotation newRotation: CGFloat, of index: Int)
    func inspector(_ inspector: InspectorViewController, requestNewFrame newFrame: CGRect, of index: Int)
    func inspector(_ inspector: InspectorViewController, requestNewFont newFont: NSFont?, of index: Int)
    func inspector(_ inspector: InspectorViewController, requestNewColor newColor: NSColor, of index: Int)
}


final class InspectorViewController: NSViewController {

    // MARK: - Properties

    private let layerStateHistory: LayerStateHistory
    private let languageController: LanguageController
    private var frameInInspector: CGRect {
        get {
            return CGRect(x: self.textFieldX.doubleValue,
                          y: self.textFieldY.doubleValue,
                          width: self.textFieldWidth.doubleValue,
                          height: self.textFieldHeight.doubleValue)
        }
        set {
            self.textFieldX.doubleValue = Double(newValue.origin.x)
            self.stepperX.doubleValue = self.textFieldX.doubleValue
            self.textFieldY.doubleValue = Double(newValue.origin.y)
            self.stepperY.doubleValue = self.textFieldY.doubleValue
            self.textFieldWidth.doubleValue = Double(newValue.size.width)
            self.stepperWidth.doubleValue = self.textFieldWidth.doubleValue
            self.textFieldHeight.doubleValue = Double(newValue.size.height)
            self.stepperHeight.doubleValue = self.textFieldHeight.doubleValue
        }
    }
    private var rotationInInspector: CGFloat? {
        get {
            return self.textFieldRotation.objectValue as? CGFloat
        }
        set {
            self.textFieldRotation.objectValue = newValue
            self.sliderRotation.objectValue = self.textFieldRotation.objectValue
        }
    }
    private var fontSizeInInspector: CGFloat? {
        get {
            return CGFloat(self.textFieldFontSize.doubleValue)
        }
        set {
            guard let newValue = newValue else { return }

            self.textFieldFontSize.doubleValue = Double(newValue)
            self.stepperFontSize.doubleValue = self.textFieldFontSize.doubleValue
        }
    }

    weak var delegate: InspectorViewControllerDelegate?
    let viewStateController: ViewStateController
    var selectedRow: Int = -1 {
        didSet {
            self.updateUI()
        }
    }

    // MARK: - Interface Builder

    @IBOutlet private var textFieldImageNumber: NSTextField!
    @IBOutlet private var stepperImageNumber: NSStepper!

    @IBOutlet private var languages: NSPopUpButton!

    @IBOutlet private var textFieldFile: NSTextField!

    @IBOutlet private var textFieldX: NSTextField!
    @IBOutlet private var stepperX: NSStepper!

    @IBOutlet private var textFieldY: NSTextField!
    @IBOutlet private var stepperY: NSStepper!

    @IBOutlet private var textFieldWidth: NSTextField!
    @IBOutlet private var stepperWidth: NSStepper!

    @IBOutlet private var textFieldHeight: NSTextField!
    @IBOutlet private var stepperHeight: NSStepper!

    @IBOutlet private var textFieldRotation: NSTextField!
    @IBOutlet private var sliderRotation: NSSlider!

    @IBOutlet private var textFieldFont: NSTextField!
    @IBOutlet private var textFieldFontSize: NSTextField!
    @IBOutlet private var stepperFontSize: NSStepper!
    @IBOutlet private var colorWell: NSColorWell!


    // MARK: - Lifecycle

    init(layerStateHistory: LayerStateHistory, selectedRow: Int, viewStateController: ViewStateController, languageController: LanguageController) {
        self.layerStateHistory = layerStateHistory
        self.selectedRow = selectedRow
        self.viewStateController = viewStateController
        self.languageController = languageController
        super.init(nibName: String(describing: type(of: self)), bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: - Update Methods

    func updateUI() {
        guard self.selectedRow >= 0 else { return }
        guard self.layerStateHistory.currentLayerState.layers.count - 1 >= self.selectedRow else { return }
        guard self.layerStateHistory.currentLayerState.layers.hasElements else { return }

        self.updateEnabledState()
        let layoutableObject = self.layerStateHistory.currentLayerState.layers[self.selectedRow]
        self.frameInInspector = layoutableObject.frame
        self.rotationInInspector = layoutableObject.rotation
        self.textFieldFile.stringValue = layoutableObject.file
        self.textFieldFont.stringValue = layoutableObject.font ?? ""
        self.fontSizeInInspector = layoutableObject.fontSize
        self.colorWell.color = layoutableObject.color ?? .white

        self.updateLanguages()
    }

    func updateEnabledState() {
        let layoutableObject = self.layerStateHistory.currentLayerState.layers[self.selectedRow]
        var isEnabled = layoutableObject.type != .background
        self.textFieldX.isEnabled = isEnabled
        self.stepperX.isEnabled = isEnabled
        self.textFieldY.isEnabled = isEnabled
        self.stepperY.isEnabled = isEnabled
        self.textFieldRotation.isEnabled = isEnabled
        self.sliderRotation.isEnabled = isEnabled

        isEnabled = layoutableObject.type == .text
        self.textFieldFont.isEnabled = isEnabled
        self.textFieldFontSize.isEnabled = isEnabled
        self.stepperFontSize.isEnabled = isEnabled
        self.colorWell.isEnabled = isEnabled
    }

    func updateLanguages() {
        let selectedLanguage = self.languages.titleOfSelectedItem
        let allLanguages = self.languageController.allLanguages().sorted()

        self.languages.removeAllItems()
        self.languages.addItems(withTitles: allLanguages)

        if selectedLanguage != nil {
            self.languages.selectItem(withTitle: selectedLanguage!)
        } else {
            self.languages.selectItem(at: 0)
            guard let selectedLanguage = self.languages.titleOfSelectedItem else { return }

            self.viewStateController.newViewState(language: selectedLanguage)
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
            self.coalesceCalls(to: #selector(updateFontSize), interval: 0.5)
            let layer = self.layerStateHistory.currentLayerState.layers[self.selectedRow]
            var fontName = layer.font ?? "Helvetica Neue"
            if fontName.isEmpty {
                fontName = "Helvetica Neue"
            }

            let font = NSFont(name: fontName, size: CGFloat(self.stepperFontSize.doubleValue))
            self.delegate?.inspector(self, requestNewFont: font, of: self.selectedRow)

        default:
            self.coalesceCalls(to: #selector(updateFrame), interval: 0.5)
            self.delegate?.inspector(self, requestNewFrame: self.frameInInspector, of: self.selectedRow)
        }
    }

    @IBAction func sliderDidChangeValue(sender: NSSlider) {
        self.textFieldRotation.objectValue = sender.objectValue
        self.coalesceCalls(to: #selector(rotateLayer), interval: 0.5)

        // Note this is a workaround because live rotation is laggy/not possible
        // if the whole image is generated every time. Therefore the existing image
        // is rotated and if after a 1 sec no change happened, the operation is saved.
        self.delegate?.inspector(self, requestRotation: CGFloat(sender.doubleValue), of: self.selectedRow)
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

        case self.textFieldRotation:
            self.rotateLayer()

        default:
            self.updateFrame()
        }
    }

    @IBAction func popupDidChange(sender: NSPopUpButton) {
        if sender == self.languages {
            self.viewStateController.newViewState(language: self.languages.titleOfSelectedItem ?? "en-US")
        }
    }

    @IBAction func colorWellDidUpdateColor(sender: NSColorWell) {
        let color = sender.color
        self.coalesceCalls(to: #selector(applyColor), interval: 0.5, object: color)
        self.delegate?.inspector(self, requestNewColor: color, of: self.selectedRow)
    }
}


// MARK: Private

private extension InspectorViewController {

    @objc func updateFrame() {
//        let frame = CGRect(x: self.textFieldX.doubleValue,
//                           y: self.textFieldY.doubleValue,
//                           width: self.textFieldWidth.doubleValue,
//                           height: self.textFieldHeight.doubleValue)
        let frame = self.frameInInspector
        let operation = UpdateFrameOperation(layerStateHistory: self.layerStateHistory, frame: frame, indexOfLayer: self.selectedRow)
        operation.apply()
    }

    @objc func updateFontSize() {
        let fontSize = CGFloat(self.textFieldFontSize.floatValue)
        let operation = UpdateFontSizeOperation(layerStateHistory: self.layerStateHistory, fontSize: fontSize, indexOfLayer: self.selectedRow)
        operation.apply()
    }

    @objc func rotateLayer() {
        let rotation = CGFloat(self.textFieldRotation.doubleValue)
        let operation = UpdateRotationOperation(layerStateHistory: self.layerStateHistory, rotation: rotation, indexOfLayer: self.selectedRow)
        operation.apply()
    }

    @objc func applyColor(_ color: NSColor) {
        let operation = UpdateTextColorOperation(layerStateHistory: self.layerStateHistory, color: color, indexOfLayer: self.selectedRow)
        operation.apply()
    }
}
