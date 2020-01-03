//
//  UserDefaults+Keys.swift
//  Screenshot Framer
//
//  Created by Patrick Kladek on 13.12.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation


extension UserDefaults {

    var showTimeTravelWindow: Bool {
        set { self.set(newValue, forKey: UserDefaultKeys.showTimeTravelWindow) }
        get { return self.bool(forKey: UserDefaultKeys.showTimeTravelWindow) }
    }

    var lockAspectRatio: Bool {
        set { self.set(newValue, forKey: UserDefaultKeys.lockAspectRatio) }
        get { return self.bool(forKey: UserDefaultKeys.lockAspectRatio) }
    }
}

struct UserDefaultKeys {
    static let showTimeTravelWindow = "showTimeTravelWindow"
    static let lockAspectRatio = "lockAspectRatio"
}
