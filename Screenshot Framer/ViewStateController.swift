//
//  ViewStateController.swift
//  FrameMe
//
//  Created by Patrick Kladek on 11.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation


struct ViewState {
    let selectedLayer: Int
    let imageNumber: Int
    let language: String
}


protocol ViewStateControllerDelegate {

    func viewStateDidChange(_ viewState: ViewState)
}


final class ViewStateController {

    var delegate: ViewStateControllerDelegate?
    var viewState: ViewState {
        didSet {
            self.delegate?.viewStateDidChange(self.viewState)
        }
    }

    init() {
        self.viewState = ViewState(selectedLayer: 0, imageNumber: 1, language: "en-US")
    }

    func newViewState(selectedLayer: Int) {
        self.viewState = ViewState(selectedLayer: selectedLayer, imageNumber: self.viewState.imageNumber, language: self.viewState.language)
    }

    func newViewState(imageNumber: Int) {
        self.viewState = ViewState(selectedLayer: self.viewState.selectedLayer, imageNumber: imageNumber, language: self.viewState.language)
    }

    func newViewState(language: String) {
        self.viewState = ViewState(selectedLayer: self.viewState.selectedLayer, imageNumber: self.viewState.imageNumber, language: language)
    }
}
