//
//  Stats.swift
//  Boatswain
//
//  Created by Jeff Reiner on 04.08.23.
//

import SwiftUI

struct Stats {
    let visitors: Int
    let views: Int
    let avgTimeOnSite: Int
    let bounceRate: Int
    let eventCompletions: Int
}

struct ReportsSection: View {
    public var site: SiteViewModel
    public var range: String
    
    @State var aggr: Aggregation?
    
    @Environment(\.openURL) var openURL

    let stats = Stats(
        visitors: 1000,
        views: 20000,
        avgTimeOnSite: 40,
        bounceRate: 50,
        eventCompletions: 0
    )
    
    @State var eventCompletions: Int = 0
    
    var body: some View {
        Text(self.range).font(.subheadline).task {
            do {
                self.aggr = try await Webservice().getAggregation(id: site.id)
            } catch {
                print(error)
            }
        }
                
        Text("\(aggr?.visits ?? "-") visitor(s)")
        
        Text("\(aggr?.pageviews ?? "-") view(s)")
        
        Text("\(aggr?.avg_duration ?? "-")s Avg time on site")
        
        Text("\(aggr?.bounce_rate.formatted(.percent) ?? "-") Bounce rate")
        
        Text("\(self.eventCompletions) Event completion(s)").task {
            do {
                self.eventCompletions = try await Webservice()
                    .getEvents(id: site.id).count
            } catch {
                print(error)
            }
        }
       
        Button("Visit Dashboard") {
            openURL(URL(string: "https://app.usefathom.com/?page=1&range=last_7_days&site=\(site.id)")!)
        }
    }
}

struct ReportsSectionGroup: View {
    public var site: SiteViewModel

    @State var visitors: String = "0"
    
    var body: some View {
        Text(site.name)
                
        Text("Live").font(.subheadline)
        
        Text("\(visitors) current visitors")
            .task {
                do {
                    self.visitors = try await Webservice()
                        .getCurrentVisiors(id: site.id)
                } catch {
                    print(error)
                }
            }
        
        Divider()
        
        ReportsSection(site: site, range: "Today")
        
        Divider()
        
        ReportsSection(site: site, range: "Last 7 Days")
    }
}
