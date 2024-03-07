//
//  MenubarIcon.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.02.24.
//

import SwiftUI
import Defaults

struct MenubarIcon: View {
    @Default(.activeSite) private var activeSiteId
    
    @EnvironmentObject private var appState: AppState
    
    @State var liveVisitors: Int = 0
    
    var body: some View {
        if activeSiteId.isEmpty {
            Image(systemName: "drop")
        } else {
            Text("\(liveVisitors) visitors")
                .task {
                    do {
                        print("fetching active site \(activeSiteId)")
                        
                        self.liveVisitors = try await Webservice()
                            .getCurrentVisiors(id: activeSiteId)
                    } catch {
                        print(error)
                    }
            }
        }
    }
}
