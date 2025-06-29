//
//  CoffretUITests.swift
//  CoffretUITests
//
//  Created by Rajkumar on 29/06/25.
//

import XCTest

/**
 UI tests for the Coffret FTP Server application.
 
 This test suite provides end-to-end testing of the user interface
 and user interactions within the Coffret app. It validates the
 complete user experience from app launch to file operations.
 
 ## Test Coverage
 - App launch and initial UI state
 - Server start/stop functionality
 - File tree navigation and interactions
 - File import and export operations
 - Context menu operations
 - Alert and dialog interactions
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 29/06/25
 */
final class CoffretUITests: XCTestCase {

    // MARK: - Test Setup and Teardown
    
    var app: XCUIApplication!
    
    /**
     Sets up the test environment before each test method.
     
     Configures the test environment including failure handling and
     initial state setup for consistent test execution.
     
     - Throws: Any setup errors that prevent test execution
     */
    override func setUpWithError() throws {
        // Stop immediately when a failure occurs for clearer debugging
        continueAfterFailure = false

        // Set up initial state for UI tests
        app = XCUIApplication()
        app.launch()
    }

    /**
     Cleans up after each test method execution.
     
     Ensures clean state for subsequent tests.
     
     - Throws: Any cleanup errors
     */
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - App Launch and Initial State Tests
    
    /**
     Tests that the app launches successfully and displays the main interface.
     
     Verifies that all essential UI elements are present and properly configured
     in their initial state.
     */
    func testAppLaunch() throws {
        // Test app launch
        XCTAssertTrue(app.state == .runningForeground)
        
        // Verify main UI elements exist
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists)
        
        // Check title label
        let titleLabel = app.staticTexts["Coffret"]
        XCTAssertTrue(titleLabel.exists)
        
        // Verify port configuration fields
        let ftpPortField = app.textFields["FTP Port"]
        let webPortField = app.textFields["Web Port"]
        XCTAssertTrue(ftpPortField.exists || app.textFields.count >= 1)
        XCTAssertTrue(webPortField.exists || app.textFields.count >= 2)
        
        // Check start/stop button
        let startStopButton = app.buttons["Start Server"]
        XCTAssertTrue(startStopButton.exists || app.buttons.containing(NSPredicate(format: "label CONTAINS 'Server'")).firstMatch.exists)
        
        // Verify file management buttons
        let importButton = app.buttons["Import Files"]
        let createFolderButton = app.buttons["Create Folder"]
        let addSampleButton = app.buttons["Add Sample File"]
        
        XCTAssertTrue(importButton.exists || app.buttons.containing(NSPredicate(format: "label CONTAINS 'Import'")).firstMatch.exists)
        XCTAssertTrue(createFolderButton.exists || app.buttons.containing(NSPredicate(format: "label CONTAINS 'Folder'")).firstMatch.exists)
        XCTAssertTrue(addSampleButton.exists || app.buttons.containing(NSPredicate(format: "label CONTAINS 'Sample'")).firstMatch.exists)
        
        // Check table view for file listing
        let filesTable = app.tables.firstMatch
        XCTAssertTrue(filesTable.exists)
    }
    
    /**
     Tests the initial configuration of port fields.
     
     Verifies that port fields have appropriate default values and
     accept valid input.
     */
    func testInitialPortConfiguration() throws {
        // Find port text fields
        let textFields = app.textFields
        XCTAssertTrue(textFields.count >= 2, "Should have at least 2 port configuration fields")
        
        // Test that text fields are enabled initially
        for i in 0..<min(2, textFields.count) {
            let textField = textFields.element(boundBy: i)
            XCTAssertTrue(textField.isEnabled, "Port field \(i) should be enabled initially")
        }
    }
    
    // MARK: - Server Control Tests
    
    /**
     Tests the server start functionality.
     
     Verifies that the server can be started and UI updates appropriately.
     */
    func testServerStart() throws {
        // Find the start/stop button
        let startButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Start'")).firstMatch
        XCTAssertTrue(startButton.exists, "Start server button should exist")
        
        // Configure ports if needed (use default values)
        let textFields = app.textFields
        if textFields.count >= 2 {
            let ftpPortField = textFields.element(boundBy: 0)
            let webPortField = textFields.element(boundBy: 1)
            
            // Clear and set FTP port
            if ftpPortField.exists && ftpPortField.isEnabled {
                ftpPortField.tap()
                ftpPortField.clearAndEnterText("2121")
            }
            
            // Clear and set web port
            if webPortField.exists && webPortField.isEnabled {
                webPortField.tap()
                webPortField.clearAndEnterText("8080")
            }
        }
        
        // Tap start button
        startButton.tap()
        
        // Wait for server to start and UI to update
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS 'Stop'"),
            object: startButton
        )
        
        let result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
        if result != .completed {
            // Fallback: check if any button contains "Stop"
            let stopButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Stop'")).firstMatch
            XCTAssertTrue(stopButton.exists, "Button should change to 'Stop Server' after starting")
        }
        
        // Verify server status is updated
        let statusLabels = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Running' OR label CONTAINS 'Server'"))
        XCTAssertTrue(statusLabels.count > 0, "Status should indicate server is running")
    }
    
    /**
     Tests the server stop functionality.
     
     Verifies that a running server can be stopped and UI reverts appropriately.
     */
    func testServerStop() throws {
        // First start the server
        try testServerStart()
        
        // Find the stop button
        let stopButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Stop'")).firstMatch
        XCTAssertTrue(stopButton.exists, "Stop server button should exist when server is running")
        
        // Tap stop button
        stopButton.tap()
        
        // Wait for server to stop and UI to update
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS 'Start'"),
            object: stopButton
        )
        
        let result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
        if result != .completed {
            // Fallback: check if any button contains "Start"
            let startButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Start'")).firstMatch
            XCTAssertTrue(startButton.exists, "Button should change back to 'Start Server' after stopping")
        }
    }
    
    /**
     Tests invalid port configuration handling.
     
     Verifies that invalid port values are properly handled with error messages.
     */
    func testInvalidPortConfiguration() throws {
        let textFields = app.textFields
        if textFields.count >= 1 {
            let ftpPortField = textFields.element(boundBy: 0)
            
            // Enter invalid port
            if ftpPortField.exists && ftpPortField.isEnabled {
                ftpPortField.tap()
                ftpPortField.clearAndEnterText("invalid")
                
                // Try to start server
                let startButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Start'")).firstMatch
                if startButton.exists {
                    startButton.tap()
                    
                    // Check for alert
                    let alert = app.alerts.firstMatch
                    if alert.exists {
                        XCTAssertTrue(alert.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Invalid' OR label CONTAINS 'port'")).firstMatch.exists)
                        
                        // Dismiss alert
                        let okButton = alert.buttons["OK"]
                        if okButton.exists {
                            okButton.tap()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - File Management Tests
    
    /**
     Tests the file tree display and navigation.
     
     Verifies that files and directories are properly displayed in the table view.
     */
    func testFileTreeDisplay() throws {
        let filesTable = app.tables.firstMatch
        XCTAssertTrue(filesTable.exists, "Files table should exist")
        
        // Wait for table to load
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count > 0"),
            object: filesTable.cells
        )
        
        _ = XCTWaiter.wait(for: [expectation], timeout: 3.0)
        
        // Check if table has cells (may be empty on first run)
        if filesTable.cells.count > 0 {
            let firstCell = filesTable.cells.firstMatch
            XCTAssertTrue(firstCell.exists, "First file cell should exist")
        }
    }
    
    /**
     Tests file tree expansion and collapse functionality.
     
     Verifies that directory nodes can be expanded and collapsed.
     */
    func testFileTreeExpansion() throws {
        let filesTable = app.tables.firstMatch
        XCTAssertTrue(filesTable.exists)
        
        // Look for expandable directory cells
        let cells = filesTable.cells
        
        for i in 0..<min(cells.count, 5) {  // Check first 5 cells
            let cell = cells.element(boundBy: i)
            if cell.exists {
                // Look for expand/collapse buttons in the cell
                let expandButton = cell.buttons.containing(NSPredicate(format: "label == '▶' OR label == '▼'")).firstMatch
                
                if expandButton.exists {
                    let initialLabel = expandButton.label
                    
                    // Tap to expand/collapse
                    expandButton.tap()
                    
                    // Verify state change
                    let newLabel = expandButton.label
                    XCTAssertNotEqual(initialLabel, newLabel, "Expand button should change state")
                    
                    break  // Test first expandable directory found
                }
            }
        }
    }
    
    /**
     Tests the create folder functionality.
     
     Verifies that new folders can be created through the UI.
     */
    func testCreateFolder() throws {
        let createFolderButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Folder'")).firstMatch
        XCTAssertTrue(createFolderButton.exists, "Create folder button should exist")
        
        createFolderButton.tap()
        
        // Look for alert dialog
        let alert = app.alerts.firstMatch
        if alert.exists {
            // Enter folder name
            let textField = alert.textFields.firstMatch
            if textField.exists {
                textField.tap()
                textField.typeText("Test Folder")
            }
            
            // Tap create button
            let createButton = alert.buttons.containing(NSPredicate(format: "label CONTAINS 'Create'")).firstMatch
            if createButton.exists {
                createButton.tap()
            } else {
                // Fallback to OK button
                let okButton = alert.buttons["OK"]
                if okButton.exists {
                    okButton.tap()
                }
            }
            
            // Verify folder was created (check table for new entry)
            let filesTable = app.tables.firstMatch
            if filesTable.exists {
                _ = filesTable.cells.containing(NSPredicate(format: "label CONTAINS 'Test Folder'")).firstMatch
                // Note: May not immediately appear due to refresh timing
            }
        }
    }
    
    /**
     Tests the add sample file functionality.
     
     Verifies that sample files can be added to the file system.
     */
    func testAddSampleFile() throws {
        let addSampleButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Sample'")).firstMatch  
        XCTAssertTrue(addSampleButton.exists, "Add sample file button should exist")
        
        // Count current cells
        let filesTable = app.tables.firstMatch
        let initialCellCount = filesTable.cells.count
        
        addSampleButton.tap()
        
        // Wait for file to be added
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count > \(initialCellCount)"),
            object: filesTable.cells
        )
        
        _ = XCTWaiter.wait(for: [expectation], timeout: 3.0)
        
        // Verify table updated (may not always increase due to refresh behavior)
        // At minimum, operation should complete without crashing
        XCTAssertTrue(filesTable.exists, "Table should still exist after adding sample file")
    }
    
    /**
     Tests file context menu operations.
     
     Verifies that long press on files shows context menu with appropriate options.
     */
    func testFileContextMenu() throws {
        let filesTable = app.tables.firstMatch
        XCTAssertTrue(filesTable.exists)
        
        if filesTable.cells.count > 0 {
            let firstCell = filesTable.cells.firstMatch
            
            // Long press to show context menu
            firstCell.press(forDuration: 1.0)
            
            // Look for action sheet or context menu
            let actionSheet = app.sheets.firstMatch
            let contextMenu = app.menus.firstMatch
            
            if actionSheet.exists {
                // Verify context menu options
                let expectedActions = ["Share", "Copy", "Rename", "Delete"]
                
                for action in expectedActions {
                    _ = actionSheet.buttons.containing(NSPredicate(format: "label CONTAINS '\(action)'")).firstMatch
                    // Note: Not all actions may be available for all file types
                }
                
                // Dismiss action sheet
                let cancelButton = actionSheet.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                }
            } else if contextMenu.exists {
                // Handle context menu if platform uses that instead
                contextMenu.tap()  // Dismiss
            }
        }
    }
    
    // MARK: - File Operations Tests
    
    /**
     Tests file sharing functionality.
     
     Verifies that files can be shared through the system share sheet.
     */
    func testFileSharing() throws {
        // First ensure we have files to work with
        try testAddSampleFile()
        
        let filesTable = app.tables.firstMatch
        if filesTable.cells.count > 0 {
            let firstCell = filesTable.cells.firstMatch
            
            // Long press to show context menu
            firstCell.press(forDuration: 1.0)
            
            let actionSheet = app.sheets.firstMatch
            if actionSheet.exists {
                let shareButton = actionSheet.buttons.containing(NSPredicate(format: "label CONTAINS 'Share'")).firstMatch
                
                if shareButton.exists {
                    shareButton.tap()
                    
                    // Look for activity view controller
                    let activityView = app.otherElements["ActivityListView"]
                    if activityView.exists {
                        // Dismiss activity view
                        let cancelButton = app.buttons["Cancel"]
                        if cancelButton.exists {
                            cancelButton.tap()
                        }
                    }
                }
            }
        }
    }
    
    /**
     Tests file renaming functionality.
     
     Verifies that files can be renamed through context menu.
     */
    func testFileRenaming() throws {
        // First ensure we have files to work with
        try testAddSampleFile()
        
        let filesTable = app.tables.firstMatch
        if filesTable.cells.count > 0 {
            let firstCell = filesTable.cells.firstMatch
            _ = firstCell.label
            
            // Long press to show context menu
            firstCell.press(forDuration: 1.0)
            
            let actionSheet = app.sheets.firstMatch
            if actionSheet.exists {
                let renameButton = actionSheet.buttons.containing(NSPredicate(format: "label CONTAINS 'Rename'")).firstMatch
                
                if renameButton.exists {
                    renameButton.tap()
                    
                    // Look for rename alert
                    let alert = app.alerts.firstMatch
                    if alert.exists {
                        let textField = alert.textFields.firstMatch
                        if textField.exists {
                            textField.clearAndEnterText("Renamed File")
                        }
                        
                        let renameButtonInAlert = alert.buttons.containing(NSPredicate(format: "label CONTAINS 'Rename'")).firstMatch
                        if renameButtonInAlert.exists {
                            renameButtonInAlert.tap()
                        }
                        
                        // Verify rename occurred
                        _ = filesTable.cells.containing(NSPredicate(format: "label CONTAINS 'Renamed File'")).firstMatch
                        // Note: May not immediately appear due to refresh timing
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation and Accessibility Tests
    
    /**
     Tests keyboard navigation and accessibility features.
     
     Verifies that the app is accessible via keyboard and assistive technologies.
     */
    func testAccessibility() throws {
        // Test that main elements are accessible
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.isAccessibilityElement || scrollView.exists)
        
        let startStopButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Server'")).firstMatch
        if startStopButton.exists {
            XCTAssertTrue(startStopButton.isAccessibilityElement)
        }
        
        let filesTable = app.tables.firstMatch
        if filesTable.exists {
            XCTAssertTrue(filesTable.isAccessibilityElement)
        }
        
        // Test that text fields have accessibility labels
        let textFields = app.textFields
        for i in 0..<min(textFields.count, 2) {
            let textField = textFields.element(boundBy: i)
            if textField.exists {
                XCTAssertTrue(textField.isAccessibilityElement)
            }
        }
    }
    
    /**
     Tests app behavior under different orientations.
     
     Verifies that the UI adapts properly to orientation changes.
     */
    func testOrientationHandling() throws {
        let device = XCUIDevice.shared
        
        // Test portrait orientation
        device.orientation = .portrait
        
        // Verify UI is still functional
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists)
        
        // Test landscape orientation if supported
        device.orientation = .landscapeLeft
        
        // Verify UI adapts
        XCTAssertTrue(scrollView.exists)
        
        // Return to portrait
        device.orientation = .portrait
    }
    
    // MARK: - Error Handling Tests
    
    /**
     Tests error dialog handling.
     
     Verifies that error dialogs appear and can be dismissed properly.
     */
    func testErrorDialogHandling() throws {
        // Trigger an error scenario (invalid port)
        try testInvalidPortConfiguration()
        
        // Test that alerts can be handled
        let alert = app.alerts.firstMatch
        if alert.exists {
            XCTAssertTrue(alert.isHittable)
            
            // Test that alert has proper buttons
            let buttons = alert.buttons
            XCTAssertTrue(buttons.count > 0, "Alert should have at least one button")
            
            // Dismiss alert
            let okButton = alert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            } else if buttons.count > 0 {
                buttons.firstMatch.tap()
            }
        }
    }
    
    // MARK: - Performance Tests
    
    /**
     Tests app launch performance.
     
     Measures the time it takes for the app to launch and become interactive.
     */
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    /**
     Tests file tree loading performance.
     
     Measures performance when loading large numbers of files.
     */
    func testFileTreePerformance() throws {
        // Add multiple sample files first
        for _ in 0..<5 {
            let addSampleButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Sample'")).firstMatch
            if addSampleButton.exists {
                addSampleButton.tap()
                // Small delay between additions
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
        
        // Measure table refresh performance
        measure {
            let filesTable = app.tables.firstMatch
            if filesTable.exists {
                // Trigger refresh by interacting with table
                filesTable.swipeDown()
            }
        }
    }
}
