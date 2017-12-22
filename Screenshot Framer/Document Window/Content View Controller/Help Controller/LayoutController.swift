//
//  LayoutController.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 12.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


class LayoutController {

    // MARK: - Properties

    let document: Document
    let layerStateHistory: LayerStateHistory
    let viewStateController: ViewStateController
    let languageController: LanguageController
    var highlightLayer: Int = 0
    var shouldHighlightSelectedLayer = false
    var fileController: FileController


    // MARK: Init

    init(document: Document, layerStateHistory: LayerStateHistory, viewStateController: ViewStateController, languageController: LanguageController, fileController: FileController) {
        self.document = document
        self.layerStateHistory = layerStateHistory
        self.viewStateController = viewStateController
        self.languageController = languageController
        self.fileController = fileController
    }


    // MARK: - Public Functions

    func layouthierarchy() -> NSView? {
        let layoutableObjects = self.layerStateHistory.currentLayerState.layers
        guard layoutableObjects.hasElements else { return nil }

        let firstLayoutableObject = layoutableObjects[0]
        let rootView = self.view(from: firstLayoutableObject)
        (rootView as? SSFView)?.backgroundColor = NSColor.lightGray

        for object in layoutableObjects where object != layoutableObjects[0] {
            let view: NSView

            if object.type == .text {
                view = self.textField(from: object)
            } else {
                view = self.view(from: object)
            }

            if self.shouldHighlightSelectedLayer && object == layoutableObjects[self.highlightLayer] {
                view.wantsLayer = true
                view.layer?.borderColor = NSColor.red.cgColor
                view.layer?.borderWidth = 2.0
            }

            rootView.addSubview(view)
        }
        return rootView
    }
}


// MARK: - Private

private extension LayoutController {

    func textField(from object: LayoutableObject) -> NSTextField {
        let viewState = self.viewStateController.viewState
        let absoluteURL = self.fileController.absoluteURL(for: object, viewState: viewState)
        let text = self.fileController.localizedTitle(from: absoluteURL, viewState: viewState)

        let textField = NSTextField(frame: object.frame)
        textField.textColor = NSColor.white
        textField.backgroundColor = NSColor.clear
        textField.isBezeled = false
        textField.isEditable = false
        textField.alignment = .center

        if let text = text {
            textField.stringValue = text
        } else {
            textField.backgroundColor = NSColor.red
        }

        textField.font = self.font(for: object)

        if let color = object.color {
            textField.textColor = color
        }

        self.limitFontSize(for: textField)
        return textField
    }

    @discardableResult
    func limitFontSize(for textField: NSTextField) -> Bool {
        guard let font = textField.font else { return false }
        guard let fontSizeObject = font.fontDescriptor.object(forKey: NSFontDescriptor.AttributeName.size) as? NSNumber else { return false }

        var fontSize = CGFloat(fontSizeObject.floatValue)
        let kMinFontSize = CGFloat(6.0)
        let frame = textField.frame
        let string = textField.stringValue as NSString
        var limited = false

        var size = string.size(withAttributes: [NSAttributedStringKey.font: NSFont(name: font.fontName, size: fontSize)!])
        while (size.width >= frame.width || size.height >= frame.height) && fontSize > kMinFontSize {
            limited = true
            fontSize -= 0.5
            let newFontSize = CGFloat(fontSize)
            guard let newFont = NSFont(name: font.fontName, size: newFontSize) else { return limited }

            size = string.size(withAttributes: [NSAttributedStringKey.font: newFont])
            textField.font = newFont
        }
        return limited
    }

    func view(from object: LayoutableObject) -> NSView {
        let viewState = self.viewStateController.viewState
        if let url = self.fileController.absoluteURL(for: object, viewState: viewState) {
            let imageView = NSImageView(frame: object.frame)
            imageView.image = NSImage(contentsOf: url)
            imageView.imageScaling = .scaleAxesIndependently
            imageView.layer?.shouldRasterize = true
            return imageView
        } else {
            let view = SSFView(frame: object.frame)
            view.backgroundColor = NSColor.red
            return view
        }
    }

    func font(for object: LayoutableObject) -> NSFont? {
        var fontName: String?

        if let fontFamily = object.font {
            fontName = fontFamily
        }

        // swiftlint:disable:next empty_count
        if fontName == nil || fontName?.count == 0 {
            fontName = "Helvetica Neue"
        }

        let font = NSFont(name: fontName!, size: object.fontSize ?? 25)
        return font
    }
}
