//
//  LayoutController.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 12.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

enum LayoutError: String {
    case none = """
                - No errors
                  Everything went fine
                """
    case noLayers = """
                    - No layers present.
                      Check your project file and make sure it contains at least one layer
                    """
    case fontToBig = """
                     - The font of one label is too big. This often happens in a different language than you design.
                       Check all languages in your project and decrease the font size or increase the frame of the label
                       The font is decresed on affected labels so the contents fit on screen.
                       You can ignore this warning with the '-ignoreFontToBig' flag
                     """
    case noOutputFile = """
                        - You forgot to specify an output path or entered an incorrect one.
                          The default path is: 'Export/$language/iPhone XXX-$image framed.png'
                        """
}


class LayoutController {

    // MARK: - Properties

    let viewStateController: ViewStateController
    let languageController: LanguageController
    var highlightLayer: Int = 0
    var shouldHighlightSelectedLayer = false
    var fileController: FileController
    private(set) var layoutErrors: [LayoutError] = []


    // MARK: Init

    init(viewStateController: ViewStateController, languageController: LanguageController, fileController: FileController) {
        self.viewStateController = viewStateController
        self.languageController = languageController
        self.fileController = fileController
    }


    // MARK: - Public Functions

    func layouthierarchy(layers: [LayoutableObject]) -> NSView? {
        self.layoutErrors = []
        guard layers.hasElements else { self.layoutErrors = [.noLayers]; return nil }

        let firstLayoutableObject = layers[0]
        let rootView = self.view(from: firstLayoutableObject)
        (rootView as? SSFView)?.backgroundColor = NSColor.lightGray

        for object in layers where object != layers[0] {
            let view: NSView

            if object.type == .text {
                view = self.textField(from: object)
            } else {
                view = self.view(from: object)
            }

            if self.shouldHighlightSelectedLayer && object == layers[self.highlightLayer] {
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

        if self.limitFontSize(for: textField) {
            self.layoutErrors.append(.fontToBig)
        }

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

        func calculateStringSize(withFont font: NSFont) -> CGSize {
            return string.boundingRect(
                with: CGSize(width: frame.width, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin],
                attributes: [NSAttributedStringKey.font: font],
                context: nil).size
        }

        var size = calculateStringSize(withFont: NSFont(name: font.fontName, size: fontSize)!)
        while (size.width >= frame.width || size.height >= frame.height) && fontSize > kMinFontSize {
            limited = true
            fontSize -= 0.5
            let newFontSize = CGFloat(fontSize)
            guard let newFont = NSFont(name: font.fontName, size: newFontSize) else { return limited }

            size = calculateStringSize(withFont: newFont)
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
            imageView.frameCenterRotation = object.rotation ?? 0
            return imageView
        } else {
            let view = SSFView(frame: object.frame)
            view.backgroundColor = NSColor.red
            view.frameCenterRotation = object.rotation ?? 0
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
