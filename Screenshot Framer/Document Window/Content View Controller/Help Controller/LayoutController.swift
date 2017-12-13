//
//  LayoutController.swift
//  FrameMe
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
    var highlightLayer: Int = -1


    // MARK: Init

    init(document: Document, layerStateHistory: LayerStateHistory, viewStateController: ViewStateController, languageController: LanguageController) {
        self.document = document
        self.layerStateHistory = layerStateHistory
        self.viewStateController = viewStateController
        self.languageController = languageController
    }


    // MARK: - Public Functions

    func layouthierarchy() -> NSView? {
        let layoutableObjects = self.layerStateHistory.currentLayerState.layers
        guard layoutableObjects.count > 0 else { return nil }

        let firstLayoutableObject = layoutableObjects[0]
        let rootView: NSView

        if let absoluteURL = self.absoluteURL(for: firstLayoutableObject) {
            rootView = RenderedView(frame: firstLayoutableObject.frame, url: absoluteURL)
        } else {
            rootView = pkView(frame: firstLayoutableObject.frame)
            (rootView as! pkView).backgroundColor = NSColor.red
        }

        for object in layoutableObjects where object != layoutableObjects[0] {
            let view: NSView

            if let absoluteURL = self.absoluteURL(for: object) {
                if object.title == "Text", let text = self.localizedTitle(from: absoluteURL, imageNumber: self.viewStateController.viewState.imageNumber) {
                    view = self.textField(with: text, frame: object.frame, color: NSColor.white, font: NSFont.systemFont(ofSize: NSFont.systemFontSize))
                } else {
                    view = RenderedView(frame: object.frame, url: absoluteURL)
                }
            } else {
                view = pkView(frame: object.frame)
                (view as! pkView).backgroundColor = NSColor.blue
            }

            if self.highlightLayer >= 0 && object == layoutableObjects[self.highlightLayer] {
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

    func textField(with string: String, frame: CGRect, color: NSColor, font: NSFont) -> NSTextField {
        let textField             = NSTextField(frame: frame)
        textField.textColor       = color
        textField.backgroundColor = NSColor.clear
        textField.isBezeled       = false
        textField.isEditable      = false
        textField.stringValue     = string
        textField.alignment       = .center

        let kMaxFontSize = CGFloat(120.0)
        let kMinFontSize = CGFloat(6.0)
        var fontSize = kMaxFontSize;
        var size = (string as NSString).size(withAttributes: [NSAttributedStringKey.font: NSFont(name: font.fontName, size: kMaxFontSize)!])
        while (size.width >= frame.width || size.height >= frame.height) && fontSize > kMinFontSize  {
            fontSize -= 0.5
            let newFontSize = CGFloat(fontSize)
            let newFont = NSFont(name: font.fontName, size: newFontSize)

            size = (string as NSString).size(withAttributes: [NSAttributedStringKey.font: newFont!])
        }
        textField.font = NSFont(name: font.fontName, size: fontSize)
        return textField
    }

    func absoluteURL(for object: LayoutableObject) -> URL? {
        guard object.file.count > 0 else { return nil }

        var file = object.file.replacingOccurrences(of: "$image", with: "\(self.viewStateController.viewState.imageNumber)")
        file = file.replacingOccurrences(of: "$language", with: self.viewStateController.viewState.language)

        let absoluteURL = self.document.documentRoot?.appendingPathComponent(file)
        return absoluteURL
    }

    func localizedTitle(from url: URL, imageNumber: Int) -> String? {
        guard let dict = NSDictionary(contentsOf: url) else { return nil }

        let value = dict["\(imageNumber)"] as? String
        return value
    }
}
