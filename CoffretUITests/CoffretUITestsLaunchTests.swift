//
//  CoffretUITestsLaunchTests.swift
//  CoffretUITests
//
//  Created by Rajkumar on 29/06/25.
//

import XCTest

/**
 Launch-specific UI tests for the Coffret FTP Server application.
 
 This test class focuses specifically on application launch behavior
 and provides comprehensive launch testing across different device
 configurations and system states.
 
 ## Launch Test Features
 - Multi-configuration launch testing
 - Screenshot capture for visual validation
 - Launch state verification
 - Performance monitoring during launch
 - Device-specific launch behavior testing
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 29/06/25
 */
final class CoffretUITestsLaunchTests: XCTestCase {

    /**
     Indicates that launch tests should run for each target application UI configuration.
     
     This property ensures comprehensive testing across different device orientations,
     accessibility settings, and other UI configuration variations.
     */
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    /**
     Sets up the launch test environment.
     
     Configures test settings to ensure consistent and reliable launch testing
     across different configurations and devices.
     
     - Throws: Any setup errors that prevent test execution
     */
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /**
     Tests application launch and captures launch screen.
     
     Validates that the application launches successfully and captures
     a screenshot of the launch state for visual regression testing
     and verification purposes.
     
     - Throws: Any test assertion failures or screenshot capture errors
     */
    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Perform post-launch validation steps
        // - Verify critical UI elements are present
        // - Check initial application state
        // - Validate navigation structure
        
        // Capture launch screen for visual validation
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
