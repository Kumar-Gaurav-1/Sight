#!/bin/bash
# Apply fixes for strict concurrency CI failures

# MenuBarController.swift line 122: guard let strongSelf = self, let button = strongSelf.statusItem?.button else { return }
sed -i 's/guard let self = self, let button = self.statusItem?.button else { return }/guard let strongSelf = self, let button = strongSelf.statusItem?.button else { return }/g' Sources/Sight/MenuBar/MenuBarController.swift

# MenuBarViewModel.swift line 110: guard let strongSelf = self else { return }
sed -i 's/guard let self = self else { return }/guard let strongSelf = self else { return }/g' Sources/Sight/MenuBar/MenuBarViewModel.swift
sed -i 's/if self.stateMachine.isPaused && self.stateMachine.pauseSource == .user {/if strongSelf.stateMachine.isPaused \&\& strongSelf.stateMachine.pauseSource == .user {/g' Sources/Sight/MenuBar/MenuBarViewModel.swift
sed -i 's/self.stateMachine.resume()/strongSelf.stateMachine.resume()/g' Sources/Sight/MenuBar/MenuBarViewModel.swift

# TimerStateMachine.swift line 80: nonisolated(unsafe) public static let shared
sed -i 's/nonisolated(unsafe) public static var shared: TimerStateMachine!/nonisolated(unsafe) public static let shared: TimerStateMachine/g' Sources/Sight/Core/TimerStateMachine.swift
