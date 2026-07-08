#!/bin/bash
# Revert AppDelegate's TimerStateMachine.shared change and fix TimerStateMachine to use var instead of let for shared.
sed -i '' 's/nonisolated(unsafe) public static let shared: TimerStateMachine!/nonisolated(unsafe) public static var shared: TimerStateMachine!/g' Sources/Sight/Core/TimerStateMachine.swift

# Fix the Foundation Notification capture issue in AppDelegate
sed -i '' 's/let minutes = (notification.userInfo?\["minutes"\] as? Int) ?? 5/let userInfo = notification.userInfo\n                let minutes = (userInfo?\["minutes"\] as? Int) ?? 5/g' Sources/Sight/App/AppDelegate.swift
