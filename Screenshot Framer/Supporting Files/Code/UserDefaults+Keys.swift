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
        get { return self.bool(forKey: UserDefaultKeys.showTimeTravelWindow) }
        set { self.set(newValue, forKey: UserDefaultKeys.showTimeTravelWindow) }
    }

    var lockAspectRatio: Bool {
        get { return self.bool(forKey: UserDefaultKeys.lockAspectRatio) }
        set { self.set(newValue, forKey: UserDefaultKeys.lockAspectRatio) }
    }
}

struct UserDefaultKeys {
    static let showTimeTravelWindow = "showTimeTravelWindow"
    static let lockAspectRatio = "lockAspectRatio"
}
