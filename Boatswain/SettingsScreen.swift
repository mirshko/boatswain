//
//  SettingsScreen.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.08.23.
//

import SwiftUI
import LaunchAtLogin
import Defaults

struct SettingsScreen: View {
    @Default(.fathomApiKey) private var fathomApiKey
    
    @EnvironmentObject private var appState: AppState
    
    @Default(.activeSite) private var activeSite
    
    var body: some View {
        Form {
            Section("General") {
                LaunchAtLogin.Toggle()
                
                Picker("Active Site", selection: $activeSite) {
                    Text("No site").tag("")
                    
                    ForEach(appState.sites, id: \.id) { site in
                        Text(site.name).tag(site.id)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section("Fathom") {
                TextField("API Key", text: $fathomApiKey)
                    .autocorrectionDisabled(true)
            }
        }
            .textFieldStyle(.roundedBorder)
            .formStyle(.grouped)
            .frame(width: 400)
            .fixedSize()
    }
}

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScreen()
    }
}
