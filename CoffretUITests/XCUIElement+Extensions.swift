//
//  XCUIElement+Extensions.swift
//  CoffretUITests
//
//  Created by Rajkumar on 30/06/25.
//

import XCTest

/**
 Extensions for XCUIElement to provide additional testing utilities.
 
 These extensions add convenient methods for common UI testing operations
 like clearing text fields, waiting for conditions, and performing
 complex interactions.
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 30/06/25
 */
extension XCUIElement {
    
    /**
     Clears the text field and enters new text.
     
     This method provides a reliable way to clear existing text and enter new text
     in text fields, handling various edge cases that can occur during UI testing.
     
     - Parameter text: The text to enter after clearing
     */
    func clearAndEnterText(_ text: String) {
        guard self.exists else { return }
        
        self.tap()
        
        // Select all text
        self.doubleTap()
        
        // Alternative approach: use keyboard shortcuts
        if self.value as? String != nil {
            // Use CMD+A to select all, then type
            self.typeText(XCUIKeyboardKey.command.rawValue + "a")
        }
        
        // Enter new text
        self.typeText(text)
    }
    
    /**
     Waits for the element to become hittable.
     
     This method waits for an element to become both existent and hittable,
     which is useful for elements that may be present but not yet interactive.
     
     - Parameter timeout: The maximum time to wait (default: 3.0 seconds)
     - Returns: True if the element became hittable within the timeout
     */
    func waitForHittable(timeout: TimeInterval = 3.0) -> Bool {
        let predicate = NSPredicate(format: "hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    /**
     Waits for the element to disappear.
     
     This method waits for an element to become non-existent, which is useful
     for verifying that dialogs, alerts, or other temporary UI elements have
     been dismissed.
     
     - Parameter timeout: The maximum time to wait (default: 3.0 seconds)
     - Returns: True if the element disappeared within the timeout
     */
    func waitForDisappearance(timeout: TimeInterval = 3.0) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    /**
     Performs a force touch on the element if available.
     
     This method attempts to perform a force touch (3D Touch) on the element,
     falling back to a long press if force touch is not available.
     
     - Parameter duration: The duration of the press (default: 1.0 seconds)
     */
    func forceTouch(duration: TimeInterval = 1.0) {
        if self.exists {
            // Try force touch first
            self.press(forDuration: duration, thenDragTo: self)
        }
    }
    
    /**
     Scrolls to make the element visible if it's not currently visible.
     
     This method attempts to scroll the containing scroll view to make
     the element visible and interactable.
     
     - Returns: True if the element is now visible and hittable
     */
    @discardableResult
    func scrollToVisible() -> Bool {
        if self.isHittable {
            return true
        }
        
        // Try to find a containing scroll view by traversing the element hierarchy
        // We'll check common ancestor elements that might contain scroll views
        let app = XCUIApplication()
        let scrollViews = app.scrollViews
        
        // Find a scroll view that contains this element
        for scrollView in scrollViews.allElementsBoundByIndex {
            if scrollView.exists {
                // Try to scroll to make the element visible
                scrollView.scrollToElement(element: self)
                if self.waitForHittable(timeout: 2.0) {
                    return true
                }
            }
        }
        
        return false
    }
}

/**
 Extensions for XCUIApplication to provide additional testing utilities.
 
 These extensions add convenient methods for common app-level testing operations.
 */
extension XCUIApplication {
    
    /**
     Waits for the app to reach a stable state.
     
     This method waits for the app to finish launching and for the main UI
     to become interactive.
     
     - Parameter timeout: The maximum time to wait (default: 10.0 seconds)
     - Returns: True if the app reached a stable state within the timeout
     */
    func waitForStableState(timeout: TimeInterval = 10.0) -> Bool {
        let predicate = NSPredicate(format: "state == %d", XCUIApplication.State.runningForeground.rawValue)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    /**
     Dismisses any visible alerts or dialogs.
     
     This method attempts to dismiss any alerts, action sheets, or other
     modal dialogs that might be visible.
     
     - Returns: True if any alerts were dismissed
     */
    @discardableResult
    func dismissVisibleAlerts() -> Bool {
        var dismissed = false
        
        // Dismiss alerts
        let alerts = self.alerts
        for alert in alerts.allElementsBoundByIndex {
            if alert.exists {
                // Try to find and tap a dismiss button
                let buttons = ["OK", "Cancel", "Dismiss", "Close"]
                for buttonTitle in buttons {
                    let button = alert.buttons[buttonTitle]
                    if button.exists {
                        button.tap()
                        dismissed = true
                        break
                    }
                }
                
                // If no standard button found, tap the first button
                if !dismissed && alert.buttons.count > 0 {
                    alert.buttons.firstMatch.tap()
                    dismissed = true
                }
            }
        }
        
        // Dismiss action sheets
        let sheets = self.sheets
        for sheet in sheets.allElementsBoundByIndex {
            if sheet.exists {
                let cancelButton = sheet.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                    dismissed = true
                }
            }
        }
        
        return dismissed
    }
    
    /**
     Takes a screenshot with metadata.
     
     This method takes a screenshot and returns an XCTAttachment with
     additional metadata for better test reporting.
     
     - Parameter name: The name for the screenshot
     - Parameter lifetime: The lifetime of the attachment
     - Returns: An XCTAttachment with the screenshot
     */
    func takeScreenshot(name: String, lifetime: XCTAttachment.Lifetime = .deleteOnSuccess) -> XCTAttachment {
        let screenshot = self.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = lifetime
        return attachment
    }
}

/**
 Extensions for XCUIElementQuery to provide additional querying utilities.
 
 These extensions add convenient methods for finding elements with specific
 characteristics or performing bulk operations on multiple elements.
 */
extension XCUIElementQuery {
    
    /**
     Finds the first element containing the specified text.
     
     This method searches through all elements in the query to find the first
     one that contains the specified text in its label or value.
     
     - Parameter text: The text to search for
     - Returns: The first matching element, or a non-existent element if none found
     */
    func firstContaining(_ text: String) -> XCUIElement {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@ OR value CONTAINS[c] %@", text, text)
        return self.matching(predicate).firstMatch
    }
    
    /**
     Finds all elements containing the specified text.
     
     This method searches through all elements in the query to find all
     that contain the specified text in their label or value.
     
     - Parameter text: The text to search for
     - Returns: An array of matching elements
     */
    func allContaining(_ text: String) -> [XCUIElement] {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@ OR value CONTAINS[c] %@", text, text)
        return self.matching(predicate).allElementsBoundByIndex
    }
    
    /**
     Checks if any element in the query is hittable.
     
     This method checks if at least one element in the query is both
     existent and hittable.
     
     - Returns: True if any element is hittable
     */
    var hasHittableElement: Bool {
        return self.allElementsBoundByIndex.contains { $0.isHittable }
    }
}

/**
 Extensions for XCUIElement to provide scroll view utilities.
 
 These extensions add methods for interacting with scroll views and
 performing scroll-based operations.
 */
extension XCUIElement {
    
    /**
     Scrolls to make a specific element visible within this scroll view.
     
     This method scrolls the scroll view to make the specified element visible.
     
     - Parameter element: The element to scroll to
     */
    func scrollToElement(element: XCUIElement) {
        while !element.isHittable {
            swipeUp()
            if element.isHittable {
                break
            }
        }
    }
    
    /**
     Scrolls to the top of the scroll view.
     
     This method scrolls to the very top of the scroll view content.
     */
    func scrollToTop() {
        guard self.elementType == .scrollView else { return }
        
        // Use coordinate-based scrolling for more reliable results
        let topCoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        topCoordinate.tap()
        
        // Alternative: Use swipe gestures
        self.swipeDown()
        self.swipeDown()
    }
    
    /**
     Scrolls to the bottom of the scroll view.
     
     This method scrolls to the very bottom of the scroll view content.
     */
    func scrollToBottom() {
        guard self.elementType == .scrollView else { return }
        
        // Use coordinate-based scrolling for more reliable results
        let bottomCoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        bottomCoordinate.tap()
        
        // Alternative: Use swipe gestures
        self.swipeUp()
        self.swipeUp()
    }
}
