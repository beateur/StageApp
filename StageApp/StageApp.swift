//
//  StageAppApp.swift
//  StageApp
//
//  Created by Bilel Hattay on 29/05/2022.
//

import SwiftUI
import Firebase

@main
struct StageApp: App {
    
    init() {
       FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
