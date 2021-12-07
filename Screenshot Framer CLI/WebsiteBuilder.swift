//
//  WebsiteBuilder.swift
//  Screenshot-Framer-CLI
//
//  Created by Patrick Kladek on 07.12.21.
//  Copyright © 2021 Patrick Kladek. All rights reserved.
//

import Foundation
import SwiftSoup

final class WebsiteBuilder {

    let baseURL: URL
    let imageParser = ImagesParser()

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    // MARK: - WebsiteBuilder

    func makeWebsite() throws -> URL {
        let doc = try self.makeHTML()
        let html = try doc.html()

        let file = self.baseURL.appendingPathComponent("index_new").appendingPathExtension("html")
        try html.write(to: file, atomically: true, encoding: .utf8)
        return file
    }
}

// MARK: - Private

private extension WebsiteBuilder {

    func makeHTML() throws -> Document {
        let doc = Document("")
        try doc.appendChild(DataNode("<!DOCTYPE html>", ""))

        try doc.appendChild(self.makeHead())
        try doc.appendChild(self.makeBody())

        return doc
    }

    func makeHead() throws -> Element {
        let head = Element(Tag("head"), "")
        let title = try head.appendElement("title")
        try title.text("Screenshots")

        let meta = try head.appendElement("meta")
        try meta.attr("chatset", "UTF-8")

        let style = try head.appendElement("style")
        try style.attr("type", "text/css")

        let data = DataNode(WebsiteTemplate.style, "")
        try style.addChildren(data)

        return head
    }

    func makeBody() throws -> Element {
        let body = Element(Tag("body"), "")

        // Make SortMenu
        let sort = try self.makeSortMenu()
        try body.addChildren(sort)

        // Make byLanguage
        let language = try self.makeLanguageSection()
        try body.addChildren(language)

        // Make byScreen
        let screens = try self.makeScreenSection()
        try body.addChildren(screens)

        // Make overlay
        let overlay = try self.makeOverlay()
        try body.addChildren(overlay)

        // Make Script
        let script = try self.makeScript()
        try body.addChildren(script)

        return body
    }

    func makeSortMenu() throws -> Element {
        let div = Element(Tag("div"), "")
        try div.attr("id", "sortMenu")

        let byLanguage = Element(Tag("button"), "")
        try byLanguage.attr("id", "defaultTab")
        try byLanguage.attr("class", "tabLink")
        try byLanguage.attr("onClick", "openTab(event, 'byLanguage')")
        try byLanguage.addChildren(TextNode("By Language", nil))
        try div.addChildren(byLanguage)

        let byScreen = Element(Tag("button"), "")
        try byScreen.attr("class", "tabLink")
        try byScreen.attr("onclick", "openTab(event, 'byScreen')")
        try byScreen.addChildren(TextNode("By Screen", nil))
        try div.addChildren(byScreen)

        return div
    }

    func makeLanguageSection() throws -> Element {
        let div = Element(Tag("div"), "")
        try div.attr("id", "byLanguage")
        try div.attr("class", "tabContent")

        let header1 = try div.appendElement("h1")
        try header1.attr("class", "tabTitle")
        try header1.addChildren(TextNode("By Language", nil))

        let languages = try self.imageParser.languages(in: self.baseURL)

        var index: Int = 0
        for language in languages {
            let header2 = try div.appendElement("h2")
            try header2.attr("id", language.language)
            try header2.appendText(language.language)

            try div.appendElement("hr")

            let table = try self.makeLanguageTable(language, offset: index)
            try div.addChildren(table.element)
            index = table.index
        }

        return div
    }

    func makeScreenSection() throws -> Element {
        let div = Element(Tag("div"), "")
        try div.attr("id", "byScreen")
        try div.attr("class", "tabContent")

        let header1 = try div.appendElement("h1")
        try header1.attr("class", "tabTitle")
        try header1.addChildren(TextNode("By Screen", nil))

        let screens = try self.imageParser.screens(in: self.baseURL)

        var index: Int = 0
        for screen in screens {
            let header2 = try div.appendElement("h2")
            try header2.attr("id", screen.name)
            try header2.attr("class", "screen")
            try header2.appendText(screen.name)

            try div.appendElement("hr")

            let table = try self.makeScreenTable(screen, offset: index)
            try div.addChildren(table.element)
            index = table.index
        }

        return div
    }

    func makeLanguageTable(_ language: ImagesParser.Language, offset: Int) throws -> (element: Element, index: Int) {
        let table = Element(Tag("table"), "")

        var index = offset
        for group in language.groups {
            let header = try self.makeTitleRow(for: group.name)
            try table.addChildren(header)

            let content = try self.makeContentRow(with: group.images, offset: index, dataTab: 1)
            try table.addChildren(content.element)
            index = content.index
        }

        return (table, index)
    }

    func makeScreenTable(_ screen: ImagesParser.Screen, offset: Int) throws -> (element: Element, index: Int) {
        let table = Element(Tag("table"), "")

        var index = offset
        for group in screen.groups {
            let header = try self.makeTitleRow(for: group.name)
            try table.addChildren(header)

            let content = try self.makeContentRow(with: group.images, offset: index, dataTab: 2, showCaption: true)
            try table.addChildren(content.element)
            index = content.index
        }

        return (table, index)
    }

    func makeTitleRow(for device: String) throws -> Element {
        let tableRow = Element(Tag("tr"), "")

        let tableHeader = Element(Tag("th"), "")
        try tableHeader.attr("colspan", "1")

        let content = Element(Tag("a"), "")
        try content.attr("id", device)
        try content.attr("class", "deviceName")
        try content.attr("href", "#\(device)")

        let text = TextNode(device, nil)

        try content.addChildren(text)
        try tableHeader.addChildren(content)
        try tableRow.addChildren(tableHeader)

        return tableRow
    }

    func makeContentRow(with images: [ImagesParser.Group.Image], offset: Int, dataTab: Int, showCaption: Bool = false) throws -> (element: Element, index: Int) {
        let tableRow = Element(Tag("tr"), "")

        var index = offset
        for image in images {
            index += 1
            let tableData = try tableRow.appendElement("td")

            let content = try tableData.appendElement("a")
            try content.attr("href", "\(image.url.relativePath)")
            try content.attr("target", "_blank")
            try content.attr("class", "screenshotLink")

            let img = try content.appendElement("img")
            try img.attr("class", "screenshot")
            try img.attr("src", image.url.relativePath)
            try img.attr("style", "width: 100%;")
            try img.attr("alt", image.url.relativePath)
            try img.attr("data-tab", "\(dataTab)")
            try img.attr("data-counter", "\(index)")

            if showCaption {
                let caption = try tableData.appendElement("div")
                try caption.attr("class", "caption")
                try caption.text(image.caption)
            }
        }

        return (tableRow, index)
    }

    func makeOverlay() throws -> Element {
        let div = Element(Tag("div"), "")
        try div.attr("id", "overlay")

        let img = try div.appendElement("img")
        try img.attr("id", "imageDisplay")
        try img.attr("src", "")
        try img.attr("alt", "")

        let info = try div.appendElement("div")
        try info.attr("id", "imageInfo")

        return div
    }

    func makeScript() throws -> Element {
        let script = Element(Tag("script"), "")
        try script.attr("type", "text/javascript")

        let data = DataNode(WebsiteTemplate.script, "")
        try script.addChildren(data)

        return script
    }
}
