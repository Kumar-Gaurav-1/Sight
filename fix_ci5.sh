#!/bin/bash
# Adding @MainActor to SightPreferencesView
awk '
/public struct SightPreferencesView: View/ {
    print "@MainActor"
    print $0
    next
}
{ print }
' Sources/Sight/Preferences/SightPreferencesView.swift > temp_pref.swift
mv temp_pref.swift Sources/Sight/Preferences/SightPreferencesView.swift
