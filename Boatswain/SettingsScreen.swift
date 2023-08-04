//
//  SettingsScreen.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.08.23.
//

import SwiftUI
import LaunchAtLogin

struct SettingsScreen: View {
    var body: some View {
            TabView {
                GeneralSettings().tabItem {
                    Label("General", systemImage: "gearshape")
                }
                
                FathomSettings().tabItem {
                    Label("Fathom", systemImage: "drop")
                }
            }
                .formStyle(.grouped)
                .frame(width: 400)
                .fixedSize()
        }
}

private struct GeneralSettings: View {
    var body: some View {
        Form {
            Section {
                LaunchAtLogin.Toggle()
            }
        }
    }
}

private struct FathomSettings: View {
    @State var apiKey: String = ""
    
    var body: some View {
        Form {
            Section {
                TextField("API Key", text: $apiKey).autocorrectionDisabled(true)
            }
        }.textFieldStyle(.roundedBorder)
    }
}


struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScreen()
    }
}
