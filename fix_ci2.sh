#!/bin/bash
# Remove @MainActor from static properties in SightTheme.swift
awk '
/@MainActor/ {
    getline next_line
    if (next_line ~ /static var accent: Color/ || next_line ~ /static var accentLight: Color/ || next_line ~ /static var accentGradient: LinearGradient/) {
        print next_line
    } else {
        print $0
        print next_line
    }
    next
}
{ print }
' Sources/Sight/Preferences/SightTheme.swift > temp_theme.swift
mv temp_theme.swift Sources/Sight/Preferences/SightTheme.swift

# InteractiveCharts.swift lines 212
# Add @MainActor to intensityColor method
awk '
/private func intensityColor/ {
    print "    @MainActor"
    print $0
    next
}
{ print }
' Sources/Sight/Preferences/InteractiveCharts.swift > temp_charts.swift
mv temp_charts.swift Sources/Sight/Preferences/InteractiveCharts.swift
