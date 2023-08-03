//
//  SettingsScreen.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.08.23.
//

import SwiftUI

struct SettingsScreen: View {
    var body: some View {
            TabView {
                GeneralSettings().tabItem {
                    Label("General", systemImage: "gearshape")
                }
            }
                .formStyle(.grouped)
                .frame(width: 400)
                .fixedSize()
        }
}

private struct GeneralSettings: View {
    @State var toggle: Bool = false
    
    var body: some View {
        Form {
            Toggle("Toggle", isOn: $toggle)
        }
    }
}

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScreen()
    }
}
