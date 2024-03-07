//
//  MoreMenu.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.02.24.
//

import SwiftUI

struct MoreMenu: View {
    @Environment(\.openURL) var openURL

    var body: some View {
        Button("About") {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.orderFrontStandardAboutPanel(nil)
        }
        
        Divider()
        
        Button("Send Feedback...") {
            openURL(URL(string: "https://github.com/mirshko/boatswain/issues/new")!)
        }
    }
}
