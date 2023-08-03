//
//  AppMenu.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.08.23.
//

import SwiftUI

struct AppMenu: View {
    @State var websites: [String] = ["simplepleasures.site", "wearecoal.com", "refugeworldwide.com", "voicesradio.co.uk"]
        
    var body: some View {
        Live()
        
        Divider()
        
        Section()
        
        Divider()
        
        Sites(websites: websites)
        
        Divider()

        Button("Settings...") {
           // Open settings panel here
        }
        .keyboardShortcut(",")
        
        More()

        Divider()

        Button("Quit Boatswain") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }
}

struct More: View {
    @Environment(\.openURL) var openURL
    
    // Hook this up to the settings and Sindreshorus package
    @State var launchAtLogin: Bool = false

    var body: some View {
        Menu("More") {
            Toggle("Launch at login", isOn: $launchAtLogin)
            
            Divider()
            
            Button("About") {
                openURL(URL(string: "https://github.com/mirshko/boatswain")!)
            }
            
            Divider()
            
            Button("Send Feedback...") {
                openURL(URL(string: "https://github.com/mirshko/boatswain/issues/new")!)
            }
        }
    }
}

struct Sites: View {
    @State var active: Bool = false
    
    @State var websites: [String]
        
    var body: some View {
        Text("Sites").font(.subheadline)
        
        ForEach(websites, id: \.self) { website in
            Menu(website) {
                Section()
                
                Divider()
                
                Toggle("Active", isOn: $active)
            }
        }
    }
}

struct Stats {
    let visitors: Int
    let views: Int
    let avgTimeOnSite: Int
    let bounceRate: Int
    let eventCompletions: Int
}

struct Section: View {
    @Environment(\.openURL) var openURL
    
    let stats = Stats(
        visitors: 1000,
        views: 20000,
        avgTimeOnSite: 40,
        bounceRate: 50,
        eventCompletions: 0
    )
    
    var body: some View {
        Text("Last 7 Days").font(.subheadline)
        
        Text("\(stats.visitors.formatted(.number)) visitors")
        Text("\(stats.views.formatted(.number)) views")
        Text("\(stats.avgTimeOnSite.formatted(.number))s Avg time on site")
        Text("\(stats.bounceRate.formatted(.percent)) Bounce rate")
        Text("\(stats.eventCompletions) Event completions")
       
        Button("Visit Dashboard") {
            openURL(URL(string: "https://app.usefathom.com/all?range=last_7_days")!)
        }
    }
}

struct Live: View {
    @State var text: String = ""
    
    var body: some View {
        Text("activeSite")
        Text("Live").font(.subheadline)
        Text("15 current visitors")
    }
}

