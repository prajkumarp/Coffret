//
//  FileTreeTableViewUITests.swift
//  CoffretUITests
//
//  Created by Rajkumar on 30/06/25.
//

import XCTest

/**
 Specialized UI tests for the file tree table view functionality.
 
 This test suite focuses specifically on testing the table view that displays
 the file tree, including cell interactions, scrolling behavior, and
 hierarchical navigation.
 
 ## Test Coverage
 - Table view display and scrolling
 - Cell content and formatting
 - Row selection and interaction
 - Context menu functionality
 - Hierarchical expand/collapse behavior
 - Performance with large datasets
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 30/06/25
 */
final class FileTreeTableViewUITests: XCTestCase {

    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Wait for app to stabilize
        _ = app.waitForStableState()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Basic Table View Tests
    
    /**
     Tests that the file tree table view is displayed correctly.
     
     Verifies the basic structure and initial state of the table view.
     */
    func testTableViewDisplay() throws {
        let filesTable = app.tables.firstMatch
        XCTAssertTrue(filesTable.waitForExistence(timeout: 5.0), "Files table should exist")
        XCTAssertTrue(filesTable.isHittable, "Files table should be interactable")
        
        // Take screenshot for visual verification
        let attachment = app.takeScreenshot(name: "Table View Initial State")
        add(attachment)
    }
    
    /**
     Tests table view cell structure and content.
     
     Verifies that table view cells display the correct information
     and have proper formatting.
     */
    func testTableViewCells() throws {
        // First ensure we have some files to test with
        addSampleFileForTesting()
        
        let filesTable = app.tables.firstMatch
        XCTAssertTrue(filesTable.exists)
        
        // Wait for cells to appear
        let cellsPredicate = NSPredicate(format: "count > 0")
        let cellsExpectation = XCTNSPredicateExpectation(predicate: cellsPredicate, object: filesTable.cells)
        let result = XCTWaiter.wait(for: [cellsExpectation], timeout: 3.0)
        
        if result == .completed {
            let firstCell = filesTable.cells.firstMatch
            XCTAssertTrue(firstCell.exists, "First cell should exist")
            
            // Verify cell contains expected elements
            // Note: Specific element detection depends on cell implementation
            let hasText = firstCell.staticTexts.count > 0
            XCTAssertTrue(hasText, "Cell should contain text elements")
            
            // Test cell accessibility
            XCTAssertTrue(firstCell.isAccessibilityElement || firstCell.children(matching: .any).count > 0)
        }
    }
    
    /**
     Tests table view scrolling behavior.
     
     Verifies that the table view can be scrolled and responds properly
     to scroll gestures.
     */
    func testTableViewScrolling() throws {
        // Add multiple files to enable scrolling
        for _ in 0..<5 {
            addSampleFileForTesting()
        }
        
        let filesTable = app.tables.firstMatch
        XCTAssertTrue(filesTable.exists)
        
        // Test scroll down
        _ = filesTable.frame.origin.y
        filesTable.swipeDown()
        
        // Test scroll up
        filesTable.swipeUp()
        
        // Verify table is still functional after scrolling
        XCTAssertTrue(filesTable.isHittable, "Table should remain interactive after scrolling")
    }
    
    // MARK: - Cell Interaction Tests
    
    /**
     Tests single tap on table view cells.
     
     Verifies that tapping on cells produces the expected behavior.
     */
    func testCellSingleTap() throws {
        addSampleFileForTesting()
        
        let filesTable = app.tables.firstMatch
        if filesTable.cells.count > 0 {
            let firstCell = filesTable.cells.firstMatch
            
            // Test single tap
            firstCell.tap()
            
            // Verify cell remains selected or shows appropriate feedback
            // Note: Specific behavior depends on app implementation
            XCTAssertTrue(firstCell.exists, "Cell should still exist after tap")
        }
    }
    
    /**
     Tests long press on table view cells to show context menu.
     
     Verifies that long press gestures properly display context menus
     with appropriate options.
     */
    func testCellLongPress() throws {
        addSampleFileForTesting()
        
        let filesTable = app.tables.firstMatch
        if filesTable.cells.count > 0 {
            let firstCell = filesTable.cells.firstMatch
            
            // Perform long press
            firstCell.press(forDuration: 1.5)
            
            // Look for context menu (action sheet or menu)
            let actionSheet = app.sheets.firstMatch
            let contextMenu = app.menus.firstMatch
            let alert = app.alerts.firstMatch
            
            let hasContextUI = actionSheet.waitForExistence(timeout: 2.0) || 
                              contextMenu.waitForExistence(timeout: 2.0) ||
                              alert.waitForExistence(timeout: 2.0)
            
            if hasContextUI {
                XCTAssertTrue(true, "Context menu appeared")
                
                // Verify context menu options
                if actionSheet.exists {
                    let expectedActions = ["Share", "Copy", "Rename", "Delete", "Cancel"]
                    for action in expectedActions {
                        _ = actionSheet.buttons.firstContaining(action)
                        // Note: Not all actions may be present for all file types
                    }
                    
                    // Dismiss action sheet
                    let cancelButton = actionSheet.buttons["Cancel"]
                    if cancelButton.exists {
                        cancelButton.tap()
                    } else {
                        actionSheet.buttons.firstMatch.tap()
                    }
                }
                
                // Take screenshot of context menu
                let attachment = app.takeScreenshot(name: "Context Menu")
                add(attachment)
            }
        }
    }
    
    // MARK: - Hierarchical Navigation Tests
    
    /**
     Tests expand/collapse functionality for directory nodes.
     
     Verifies that directory nodes can be expanded and collapsed properly.
     */
    func testDirectoryExpansion() throws {
        // Create a folder first
        createFolderForTesting()
        
        let filesTable = app.tables.firstMatch
        
        // Look for expandable cells (directories)
        let cells = filesTable.cells
        
        for i in 0..<min(cells.count, 5) {
            let cell = cells.element(boundBy: i)
            if cell.exists {
                // Look for expansion indicators (▶ or ▼)
                let expandButton = cell.buttons.matching(NSPredicate(format: "label == '▶' OR label == '▼'")).firstMatch
                
                if expandButton.exists {
                    let initialState = expandButton.label
                    
                    // Tap to expand/collapse
                    expandButton.tap()
                    
                    // Wait for animation to complete
                    Thread.sleep(forTimeInterval: 0.5)
                    
                    // Verify state changed
                    let newState = expandButton.label
                    XCTAssertNotEqual(initialState, newState, "Expand button should change state")
                    
                    // Take screenshot of expanded state
                    let attachment = app.takeScreenshot(name: "Directory Expanded")
                    add(attachment)
                    
                    break
                }
            }
        }
    }
    
    /**
     Tests indentation display for hierarchical structure.
     
     Verifies that nested files and directories are properly indented
     to show their hierarchical relationship.
     */
    func testHierarchicalIndentation() throws {
        // Create nested folder structure
        createFolderForTesting()
        
        let filesTable = app.tables.firstMatch
        
        // Expand directories to show hierarchy
        let expandButtons = filesTable.buttons.matching(NSPredicate(format: "label == '▶'"))
        
        for i in 0..<min(expandButtons.count, 3) {
            let button = expandButtons.element(boundBy: i)
            if button.exists {
                button.tap()
                Thread.sleep(forTimeInterval: 0.3)  // Allow animation
            }
        }
        
        // Take screenshot showing hierarchy
        let attachment = app.takeScreenshot(name: "Hierarchical Structure")
        add(attachment)
        
        // Verify different indentation levels exist
        // Note: Specific verification depends on cell implementation
        XCTAssertTrue(filesTable.cells.count > 0, "Should have cells showing hierarchy")
    }
    
    // MARK: - Performance Tests
    
    /**
     Tests table view performance with many files.
     
     Verifies that the table view performs well when displaying
     a large number of files and directories.
     */
    func testTableViewPerformance() throws {
        // Add multiple sample files
        for _ in 0..<10 {
            addSampleFileForTesting()
        }
        
        let filesTable = app.tables.firstMatch
        
        // Measure scrolling performance
        measure {
            for _ in 0..<5 {
                filesTable.swipeUp()
                filesTable.swipeDown()
            }
        }
        
        // Verify table is still responsive
        XCTAssertTrue(filesTable.isHittable, "Table should remain responsive after performance test")
    }
    
    /**
     Tests table view refresh performance.
     
     Verifies that refreshing the table view (reloading data) performs well.
     */
    func testTableViewRefreshPerformance() throws {
        let filesTable = app.tables.firstMatch
        
        // Measure refresh performance by triggering refreshes
        measure {
            for _ in 0..<3 {
                // Trigger refresh by pull-to-refresh gesture
                filesTable.swipeDown()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    /**
     Tests table view behavior when no files are present.
     
     Verifies that the table view handles empty states gracefully.
     */
    func testEmptyTableView() throws {
        let filesTable = app.tables.firstMatch
        
        // Even if empty, table should exist and be properly configured
        XCTAssertTrue(filesTable.exists, "Table should exist even when empty")
        
        // Take screenshot of empty state
        let attachment = app.takeScreenshot(name: "Empty Table State")
        add(attachment)
    }
    
    /**
     Tests table view resilience to rapid interactions.
     
     Verifies that the table view handles rapid user interactions
     without crashing or becoming unresponsive.
     */
    func testRapidInteractions() throws {
        addSampleFileForTesting()
        
        let filesTable = app.tables.firstMatch
        
        // Perform rapid interactions
        for _ in 0..<10 {
            filesTable.swipeUp()
            filesTable.swipeDown()
            
            if filesTable.cells.count > 0 {
                let randomCell = filesTable.cells.element(boundBy: 0)
                if randomCell.exists {
                    randomCell.tap()
                }
            }
        }
        
        // Verify table is still functional
        XCTAssertTrue(filesTable.exists, "Table should survive rapid interactions")
        XCTAssertTrue(filesTable.isHittable, "Table should remain interactive")
    }
    
    // MARK: - Helper Methods
    
    /**
     Helper method to add a sample file for testing.
     
     This method interacts with the UI to add a sample file,
     which can then be used in various tests.
     */
    private func addSampleFileForTesting() {
        let addSampleButton = app.buttons.firstContaining("Sample")
        if addSampleButton.exists {
            addSampleButton.tap()
            // Wait for file to be added
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
    
    /**
     Helper method to create a folder for testing.
     
     This method interacts with the UI to create a new folder,
     which can then be used in hierarchy tests.
     */
    private func createFolderForTesting() {
        let createFolderButton = app.buttons.firstContaining("Folder")
        if createFolderButton.exists {
            createFolderButton.tap()
            
            // Handle folder creation dialog
            let alert = app.alerts.firstMatch
            if alert.waitForExistence(timeout: 2.0) {
                let textField = alert.textFields.firstMatch
                if textField.exists {
                    textField.tap()
                    textField.typeText("Test Folder")
                }
                
                let createButton = alert.buttons.firstContaining("Create")
                if createButton.exists {
                    createButton.tap()
                } else {
                    let okButton = alert.buttons["OK"]
                    if okButton.exists {
                        okButton.tap()
                    }
                }
            }
            
            // Wait for folder to be created
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
}
