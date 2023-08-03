//
//  BoatswainApp.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.08.23.
//

import SwiftUI

@main
struct BoatswainApp: App {
    @State var hasVisitors: Bool = false
    
    var body: some Scene {
        Settings {
            SettingsScreen()
        }
        
        MenuBarExtra() {
            AppMenu()
        } label: {
            if (self.hasVisitors) {
                Text("12 current visitors")
            } else {
                Image(systemName: "drop")
            }
        }
    }
}
