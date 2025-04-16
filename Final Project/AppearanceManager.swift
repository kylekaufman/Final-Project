//
//  AppearanceManager.swift
//  Final Project
//
//  Created by Mufu Tebit on 4/15/25.
//


import SwiftUI

/// Manages the app's appearance settings
class AppearanceManager {
    /// Shared instance for app-wide access
    static let shared = AppearanceManager()
    
    /// AppStorage key for dark mode setting
    private let darkModeKey = "isDarkMode"
    
    /// Initialize with current system settings
    private init() {
        // Initialize from stored value or system setting
        if UserDefaults.standard.object(forKey: darkModeKey) == nil {
            // If not set yet, use system setting
            let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
            UserDefaults.standard.set(isDarkMode, forKey: darkModeKey)
        }
        
        // Apply the stored setting
        applyAppearance()
    }
    
    /// Apply dark mode setting app-wide
    func applyAppearance() {
        let isDarkMode = UserDefaults.standard.bool(forKey: darkModeKey)
        
        // Apply to windows
        DispatchQueue.main.async {
            let scenes = UIApplication.shared.connectedScenes
            let windowScenes = scenes.compactMap { $0 as? UIWindowScene }
            
            for windowScene in windowScenes {
                for window in windowScene.windows {
                    window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
                }
            }
        }
    }
    
    /// Get current dark mode setting
    var isDarkMode: Bool {
        return UserDefaults.standard.bool(forKey: darkModeKey)
    }
    
    /// Set dark mode and apply immediately
    func setDarkMode(_ isDarkMode: Bool) {
        UserDefaults.standard.set(isDarkMode, forKey: darkModeKey)
        applyAppearance()
    }
}