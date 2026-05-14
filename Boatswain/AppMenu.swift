//
//  AppMenu.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.08.23.
//

import AppKit
import Defaults
import SwiftUI

struct MenuTrackingView: NSViewRepresentable {
    let onOpen: () -> Void
    let onClose: () -> Void

    func makeNSView(context _: Context) -> NSView {
        let view = TrackingNSView()
        view.onOpen = onOpen
        view.onClose = onClose
        return view
    }

    func updateNSView(_: NSView, context _: Context) {}
}

class TrackingNSView: NSView {
    var onOpen: (() -> Void)?
    var onClose: (() -> Void)?
    private weak var observed: NSMenu?
    private let delegate = MenuDelegate()

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        findAndObserveMenu()
    }

    private func findAndObserveMenu() {
        var next = superview
        while next != nil {
            if let item = next as? NSMenuItem, let menu = item.menu {
                observed = menu
                delegate.onOpen = onOpen
                delegate.onClose = onClose
                guard menu.delegate !== delegate else { break }
                menu.delegate = delegate
                delegate.suppressNextOpen = true
                onOpen?()
                break
            }
            next = next?.superview
        }
    }

    private class MenuDelegate: NSObject, NSMenuDelegate {
        var onOpen: (() -> Void)?
        var onClose: (() -> Void)?
        var suppressNextOpen = false
        func menuWillOpen(_: NSMenu) {
            if suppressNextOpen {
                suppressNextOpen = false
                return
            }
            onOpen?()
        }

        func menuDidClose(_: NSMenu) {
            onClose?()
        }
    }
}

struct AppMenu: View {
    @Default(.fathomApiKey) private var apiKey
    @Default(.activeSite) private var activeSiteId

    private var appState = AppState.shared

    var body: some View {
        Group {
            if apiKey.isEmpty {
                NoApiKeyView()

                Divider()

                SettingsLink {
                    Text("Settings...")
                }
                .keyboardShortcut(",")

                Divider()

                Button("Quit Boatswain") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q")
            } else {
                if !activeSiteId.isEmpty {
                    if let site = appState.sites.first(where: { $0.id == activeSiteId }) {
                        ReportsSectionGroup(site: site)

                        Divider()
                    }
                }

                Text("Sites").font(.subheadline)

                if appState.sites.isEmpty {
                    Text("No sites found")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(appState.sites.filter { $0.id != activeSiteId }) { site in
                        Menu(site.name) {
                            ReportsSectionGroup(site: site)
                            MenuTrackingView(
                                onOpen: { Task { await appState.refreshSubmenuData(for: site.id) } },
                                onClose: {}
                            )
                        }
                    }
                }

                Divider()

                SettingsLink {
                    Text("Settings...")
                }
                .keyboardShortcut(",")

                Menu("More") {
                    MoreMenu()
                    MenuTrackingView(onOpen: {}, onClose: {})
                }

                Divider()

                Button("Quit Boatswain") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
    }
}
