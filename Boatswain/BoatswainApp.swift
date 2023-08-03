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
        MenuBarExtra("Boatswain", systemImage: "drop") {
            AppMenu()
        }
    }
}

struct AppMenu: View {
    @State var currentNumber: String = "1"
    
    var body: some View {
        Live()
        
        Divider()
        
        Section()
        
        Divider()
        
        Sites()
        
        Divider()

        Button("Preferences") {
           currentNumber = "3"
        }
        .keyboardShortcut(",")
        
        Menu("More") {
            Button("About") {
                
            }
            Button("Send Feedback...") {
                            
            }
        }

        Divider()

        Button("Quit Boatswain") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }
}

struct Sites: View {
    @Environment(\.openURL) var openURL
    
    @State var websites: [String] = ["simplepleasures.site", "wearecoal.com", "refugeworldwide.com", "voicesradio.co.uk"]
    
    var body: some View {
        Text("Sites").font(.subheadline)
        
        ForEach(websites, id: \.self) { website in
            Menu(website) {
                Section()
                
                Divider()
                
                Button("Set Active") {
                    
                }
            }
        }
    }
}

struct Section: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Text("Last 7 Days").font(.subheadline)
        
        Text("1000 Visitors")
        Text("1000 Views")
        Text("40s Avg time on site")
        Text("50% Bounce rate")
        Text("0 Event completions")
       
        Button("Visit Dashboard") {
            openURL(URL(string: "https://app.usefathom.com/all?range=last_7_days")!)
        }
    }
}

struct Live: View {
    var body: some View {
        Text("simplepleasures.site")
        Text("Live").font(.subheadline)
        Text("15 current visitors")
    }
}
