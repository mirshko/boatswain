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
    public var date_to: Date
    public var date_from: Date
    
    @State var aggr: Aggregation?
    
    @Environment(\.openURL) var openURL
    
    @State var eventCompletions: Int = 0
    
    var body: some View {
        Text(self.range).font(.subheadline).task {
            do {
                self.aggr = try await Webservice().getAggregation(id: site.id, date_to: date_to, date_from: date_from)
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
    
    // Set date_to as today's date
    let startOfToday = Calendar.current.startOfDay(for: Date())
    
    let date_from_last7 = Calendar.current.startOfDay(for: Date()).addingTimeInterval(-6 * 24 * 60 * 60)
    
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
        
        ReportsSection(site: site, range: "Today", date_to: Date(), date_from: startOfToday)
        
        Divider()
        
        ReportsSection(site: site, range: "Last 7 Days", date_to: startOfToday, date_from: date_from_last7)
    }
}
