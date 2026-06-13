//
//  CadenceApp.swift
//  Cadence
//
//  Created by Juan Pedro Martin on 6/12/26.
//

import SwiftData
import SwiftUI

@main
struct CadenceApp: App {
    /// On-disk SwiftData store for the whole app. CloudKit sync arrives in Slice 7
    /// (one-line change in `CadenceStore.live()` plus capabilities).
    let container = CadenceStore.live()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
