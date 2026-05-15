//
//  Formatting.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.08.23.
//

import Foundation

func formatDuration(_ seconds: String?) -> String {
    guard let secsStr = seconds, let total = Double(secsStr), total > 0 else { return "-" }
    let secs = Int(total)
    if secs < 60 {
        return "\(secs)s"
    }
    let minutes = secs / 60
    let remainingSeconds = secs % 60
    return "\(minutes)m \(remainingSeconds)s"
}

func formatNumber(_ value: String?) -> String {
    guard let str = value, let num = Int(str) else { return "-" }
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = .current
    return formatter.string(from: NSNumber(value: num)) ?? "-"
}

func formatPercent(_ value: String?) -> String {
    guard let str = value, let num = Double(str) else { return "-" }
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.locale = .current
    formatter.minimumFractionDigits = 1
    formatter.maximumFractionDigits = 1
    return formatter.string(from: NSNumber(value: num / 100)) ?? "-"
}
