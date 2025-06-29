//
//  CoffretUITestsLaunchTests.swift
//  CoffretUITests
//
//  Created by Rajkumar on 29/06/25.
//

import XCTest

/**
 Launch-specific UI tests for the Coffret FTP Server application.
 
 This test suite focuses on app launch scenarios, initial state validation,
 and launch performance testing. It ensures the app starts correctly under
 various conditions and device states.
 
 ## Test Coverage
 - Basic app launch functionality
 - Launch performance measurement
 - Initial UI state validation
 - Launch under different device conditions
 - Memory and resource usage during launch
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 29/06/25
 */
final class CoffretUITestsLaunchTests: XCTestCase {

    // MARK: - Test Configuration
    
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Basic Launch Tests
    
    /**
     Tests basic app launch functionality.
     
     Verifies that the app launches successfully and reaches a stable state
     with main UI elements visible and accessible.
     */
    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify app launched successfully
        XCTAssertTrue(app.state == .runningForeground)
        
        // Verify main UI elements are present
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5.0), "Main scroll view should appear")
        
        // Check for key UI elements
        let hasTitle = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Coffret'")).firstMatch.exists
        let hasTextFields = app.textFields.count >= 2  // Port configuration fields
        let hasButtons = app.buttons.count >= 4  // Server control and file operation buttons
        let hasTable = app.tables.firstMatch.exists  // File tree table
        
        XCTAssertTrue(hasTitle, "App title should be visible")
        XCTAssertTrue(hasTextFields, "Port configuration fields should be present")
        XCTAssertTrue(hasButtons, "Action buttons should be present")
        XCTAssertTrue(hasTable, "File tree table should be present")
        
        // Take screenshot for visual verification
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch State"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    /**
     Tests app launch with various device orientations.
     
     Verifies that the app launches correctly in both portrait and landscape modes.
     */
    func testLaunchInDifferentOrientations() throws {
        let device = XCUIDevice.shared
        let app = XCUIApplication()
        
        // Test portrait launch
        device.orientation = .portrait
        app.launch()
        
        XCTAssertTrue(app.state == .runningForeground)
        let scrollViewPortrait = app.scrollViews.firstMatch
        XCTAssertTrue(scrollViewPortrait.waitForExistence(timeout: 3.0))
        
        app.terminate()
        
        // Test landscape launch
        device.orientation = .landscapeLeft
        app.launch()
        
        XCTAssertTrue(app.state == .runningForeground)
        let scrollViewLandscape = app.scrollViews.firstMatch
        XCTAssertTrue(scrollViewLandscape.waitForExistence(timeout: 3.0))
        
        // Reset orientation
        device.orientation = .portrait
    }
    
    /**
     Tests app launch performance.
     
     Measures the time it takes for the app to launch and become interactive.
     This test helps identify performance regressions in app startup.
     */
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // Test launch performance
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    /**
     Tests memory usage during app launch.
     
     Monitors memory consumption during the launch process to ensure
     the app doesn't use excessive resources.
     */
    func testLaunchMemoryUsage() throws {
        if #available(iOS 13.0, *) {
            let app = XCUIApplication()
            
            measure(metrics: [XCTMemoryMetric()]) {
                app.launch()
                
                // Wait for app to fully load
                let scrollView = app.scrollViews.firstMatch
                _ = scrollView.waitForExistence(timeout: 5.0)
                
                // Perform some basic operations to load UI
                let filesTable = app.tables.firstMatch
                if filesTable.exists {
                    filesTable.swipeDown()  // Trigger refresh
                }
                
                app.terminate()
            }
        }
    }
    
    /**
     Tests app launch after backgrounding and foregrounding.
     
     Verifies that the app can be properly restored from background state.
     */
    func testLaunchFromBackground() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify initial launch
        XCTAssertTrue(app.state == .runningForeground)
        
        // Background the app
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.state == .runningBackground || app.state == .runningBackgroundSuspended)
        
        // Foreground the app
        app.activate()
        XCTAssertTrue(app.state == .runningForeground)
        
        // Verify UI is still functional
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "UI should be restored after foregrounding")
    }
    
    /**
     Tests accessibility features during app launch.
     
     Verifies that accessibility elements are properly configured and
     available immediately after launch.
     */
    func testLaunchAccessibility() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for main UI to load
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 3.0))
        
        // Test accessibility of key elements
        let startStopButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Server'")).firstMatch
        if startStopButton.exists {
            XCTAssertTrue(startStopButton.isAccessibilityElement, "Server button should be accessible")
        }
        
        let textFields = app.textFields
        for i in 0..<min(textFields.count, 2) {
            let textField = textFields.element(boundBy: i)
            if textField.exists {
                XCTAssertTrue(textField.isAccessibilityElement, "Text field \(i) should be accessible")
            }
        }
        
        let filesTable = app.tables.firstMatch
        if filesTable.exists {
            XCTAssertTrue(filesTable.isAccessibilityElement, "Files table should be accessible")
        }
    }
}
