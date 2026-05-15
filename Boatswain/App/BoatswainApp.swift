//
//  BoatswainApp.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.08.23.
//

import SwiftUI

@main
struct BoatswainApp: App {
    var body: some Scene {
        MenuBarExtra {
            AppMenu()
        } label: {
            MenubarIcon()
        }

        Settings {
            SettingsScreen()
        }
    }
}
