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

    @IBOutlet private weak var lockAspectButton: NSButton!

    @IBOutlet private var textFieldRotation: NSTextField!
    @IBOutlet private var sliderRotation: NSSlider!

    @IBOutlet private var textFieldFont: NSTextField!
    @IBOutlet private var textFieldFontSize: NSTextField!
    @IBOutlet private var stepperFontSize: NSStepper!
    @IBOutlet private var colorWell: NSColorWell!
    @IBOutlet private var alignmentSegment: NSSegmentedControl!
    @IBOutlet private var verticallyCenteredCheckbox: NSButton!


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

    override func awakeFromNib() {
        super.awakeFromNib()

        let fromImageNumber = self.layerStateHistory.currentLayerState.outputConfig.fromImageNumber
        guard fromImageNumber > 0 else { return }

        self.textFieldImageNumber.integerValue = fromImageNumber
        self.viewStateController.newViewState(imageNumber: fromImageNumber)
        self.lockAspectButton.state = UserDefaults.standard.lockAspectRatio ? .on : .off
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
        self.alignmentSegment.selectSegment(withTag: layoutableObject.textAlignment?.segmentTag ?? 1)   // default to center
        self.verticallyCenteredCheckbox.state = (layoutableObject.verticallyCentered ?? false) ? .on : .off

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
        self.alignmentSegment.isEnabled = isEnabled
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

    func updateUIFromViewState() {
        self.textFieldImageNumber.integerValue = self.viewStateController.viewState.imageNumber
        self.stepperImageNumber.integerValue = self.textFieldImageNumber.integerValue
        self.languages.stringValue = self.viewStateController.viewState.language
    }


    // MARK: - Actions

    @IBAction func stepperPressed(sender: NSStepper) {
        self.textFieldImageNumber.integerValue = self.stepperImageNumber.integerValue
        self.textFieldX.doubleValue = self.stepperX.doubleValue
        self.textFieldY.doubleValue = self.stepperY.doubleValue

        switch sender {
        case self.stepperWidth:
            self.textFieldWidth.doubleValue = self.stepperWidth.doubleValue
            self.updateLockedRelatedFields(forNewWidth: CGFloat(self.stepperWidth!.doubleValue))
        case self.stepperHeight:
            self.textFieldHeight.doubleValue = self.stepperHeight.doubleValue
            self.updateLockedRelatedFields(forNewHeight: CGFloat(self.stepperHeight!.doubleValue))
        default:
            break
        }
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

        case self.textFieldWidth:
            self.updateLockedRelatedFields(forNewWidth: self.frameInInspector.width)
            self.updateFrame()

        case self.textFieldHeight:
            self.updateLockedRelatedFields(forNewHeight: self.frameInInspector.height)
            self.updateFrame()

        default:
            self.updateFrame()
        }
    }

    func updateLockedRelatedFields(forNewWidth width: CGFloat) {
        guard self.selectedRow < self.layerStateHistory.currentLayerState.layers.count else { return }

        if self.lockAspectButton.state == .on {
            let currentLayer = self.layerStateHistory.currentLayerState.layers[self.selectedRow]
            self.textFieldHeight.doubleValue = Double(currentLayer.frame.aspectScaled(toWidth: width).height)
        }
    }

    func updateLockedRelatedFields(forNewHeight height: CGFloat) {
        guard self.selectedRow < self.layerStateHistory.currentLayerState.layers.count else { return }

        if self.lockAspectButton.state == .on {
            let currentLayer = self.layerStateHistory.currentLayerState.layers[self.selectedRow]
            self.textFieldWidth.doubleValue = Double(currentLayer.frame.aspectScaled(toHeight: height).width)
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

    @IBAction func segmentDidChange(sender: NSSegmentedControl) {
        let tag = sender.selectedSegment
        let alignment = NSTextAlignment(segmentTag: tag)

        let operation = UpdateTextAlignmentOperation(layerStateHistory: self.layerStateHistory, indexOfLayer: self.selectedRow, alignment: alignment)
        operation.apply()
    }

    @IBAction func checkboxDidChange(sender: NSButton) {
        guard sender == self.verticallyCenteredCheckbox else { return }

        let state = self.verticallyCenteredCheckbox.state == .on ? true : false
        let operation = UpdateVerticallyCenteredTextOperation(layerStateHistory: self.layerStateHistory, indexOfLayer: self.selectedRow, verticallyCentered: state)
        operation.apply()
    }

    @IBAction func didToggleAspectRatioLock(_ sender: NSButton) {
        UserDefaults.standard.lockAspectRatio = sender.state == .on
    }

    @IBAction func centerFrameHorizontally(_ sender: Any) {
        let backgroundFrame = self.layerStateHistory.currentLayerState.layers[0].frame
        let currentFrame = self.layerStateHistory.currentLayerState.layers[self.selectedRow].frame
        guard backgroundFrame != currentFrame else { return }

        let newFrame = currentFrame.centeredHorizontally(in: backgroundFrame)
        self.textFieldX.doubleValue = Double(newFrame.origin.x)
        self.updateFrame()
    }

    @IBAction func centerFrameVertically(_ sender: Any) {
        let backgroundFrame = self.layerStateHistory.currentLayerState.layers[0].frame
        let currentFrame = self.layerStateHistory.currentLayerState.layers[self.selectedRow].frame
        guard backgroundFrame != currentFrame else { return }

        let newFrame = currentFrame.centeredVertically(in: backgroundFrame)
        self.textFieldY.doubleValue = Double(newFrame.origin.y)
        self.updateFrame()
    }
}


// MARK: - Private

private extension InspectorViewController {

    @objc func updateFrame() {
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
        let rotation = CGFloat(self.textFieldRotation.doubleValue.normalizeAngle)
        let operation = UpdateRotationOperation(layerStateHistory: self.layerStateHistory, rotation: rotation, indexOfLayer: self.selectedRow)
        operation.apply()
    }

    @objc func applyColor(_ color: NSColor) {
        let operation = UpdateTextColorOperation(layerStateHistory: self.layerStateHistory, color: color, indexOfLayer: self.selectedRow)
        operation.apply()
    }
}

// MARK: - Helper

private extension Double {

    var normalizeAngle: Double {
        return self.normalizeValue(self, start: 0.0, end: 360.0)
    }

    /// from https://stackoverflow.com/a/2021986
    func normalizeValue(_ value: Double, start: Double, end: Double) -> Double {
        let width = end - start
        let offsetValue = value - start

        return (offsetValue - (floor(offsetValue / width) * width)) + start
    }
}

private extension NSTextAlignment {

    var segmentTag: Int {
        switch self {
        case .left:
            return 0
        case .center:
            return 1
        case .right:
            return 2
        case .justified,
             .natural:
            return 3
        @unknown default:
            // Fallback to center if new case is added in future
            return 1
        }
    }

    init(segmentTag: Int) {
        switch segmentTag {
        case 0:
            self = .left
        case 1:
            self = .center
        case 2:
            self = .right
        case 3:
            self = .justified
        default:
            self = .center
        }
    }
}

private extension CGRect {

    func aspectScaled(toHeight height: CGFloat) -> CGRect {
        guard let size = self.size.aspectScaled(toHeight: height) else { return self }

        return CGRect(origin: self.origin, size: size)
    }

    func aspectScaled(toWidth width: CGFloat) -> CGRect {
        guard let size = self.size.aspectScaled(toHeight: height) else { return self }

        return CGRect(origin: self.origin, size: size)
    }

    func centeredHorizontally(in container: CGRect) -> CGRect {
        var rect = self
        rect.origin.x = container.origin.x + ((container.width - self.width) / 2.0)
        return rect
    }

    func centeredVertically(in container: CGRect) -> CGRect {
        return self.transposed.centeredHorizontally(in: container.transposed).transposed
    }

    var transposed: CGRect {
        return CGRect(x: self.origin.y, y: self.origin.x, width: self.height, height: self.width)
    }
}

private extension CGSize {

    var widthHeightAspect: CGFloat? {
        guard self.height != 0, self.width != 0 else { return nil }

        return self.width / self.height
    }

    func aspectScaled(toWidth width: CGFloat) -> CGSize? {
        guard let aspect = self.widthHeightAspect else { return nil }

        return CGSize(width: width, height: width / aspect)
    }

    func aspectScaled(toHeight height: CGFloat) -> CGSize? {
        guard let aspect = self.widthHeightAspect else { return nil }

        return CGSize(width: height * aspect, height: width)
    }
}
