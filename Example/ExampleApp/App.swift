//
//  ExampleApp.swift
//  ExampleApp
    

import SwiftUI

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


extension Bool {
    var str: String { String(self).capitalized }
}
extension Double {
    var str: String { String(self).capitalized }
}

extension View {
    func leftAlignment() -> some View {
        self.frame(maxWidth: .infinity, alignment: .trailing)
    }
}

extension Date {
    var formatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: self)
    }
}
