#!/bin/bash
# Remove @MainActor from the Button/Toggle Styles
sed -i 's/^@MainActor//g' Sources/Sight/Preferences/SightTheme.swift
