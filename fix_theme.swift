// Wait, SightTheme struct can be marked @MainActor entirely, or just properties.
// But memory says "SwiftUI Views and helper methods that reference @MainActor-isolated properties (e.g., SightTheme.accent) must be explicitly annotated with @MainActor. However, for custom styles (e.g., ButtonStyle, ToggleStyle), do not apply @MainActor to the entire struct..."
// Let's check SightTheme.swift
