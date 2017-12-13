//
//  ViewStateController.swift
//  FrameMe
//
//  Created by Patrick Kladek on 11.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation


struct ViewState {
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
        self.viewState = ViewState(imageNumber: 1, language: "en-US")
    }


    func newViewState(with newImageNumber: Int) {
        self.viewState = ViewState(imageNumber: newImageNumber, language: self.viewState.language)
    }

    func newViewState(with newLanguage: String) {
        self.viewState = ViewState(imageNumber: self.viewState.imageNumber, language: newLanguage)
    }
}
