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
            let aboutView = AboutView()
            let hostingController = NSHostingController(rootView: aboutView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "About Boatswain"
            window.styleMask = [.titled, .closable]
            window.setContentSize(NSSize(width: 320, height: 260))
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }

        Divider()

        Button("Send Feedback...") {
            openURL(URL(string: "https://github.com/mirshko/boatswain/issues/new")!)
        }
    }
}
