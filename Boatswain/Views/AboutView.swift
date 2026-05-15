//
//  AboutView.swift
//  Boatswain
//
//  Created by Jeff Reiner on 15.05.26.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath))
                .resizable()
                .frame(width: 64, height: 64)

            Text("Boatswain")
                .font(.title2)
                .bold()

            if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                Text("Version \(version)")
                    .foregroundStyle(.secondary)
            }

            Text("Huge thanks to Vadim Demedes ([vadimdemedes.com](https://vadimdemedes.com)) and his app [pulsestats.app](https://pulsestats.app) for the inspiration.")
                .font(.caption)
                .multilineTextAlignment(.center)

            Text("App icon uses icons from [lucide.dev](https://lucide.dev) (ISC License).")
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(width: 300)
        .environment(\.openURL, OpenURLAction { url in
            NSWorkspace.shared.open(url)
            return .handled
        })
    }
}
