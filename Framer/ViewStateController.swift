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
        self.viewState = ViewState(imageNumber: 1)
    }
}
