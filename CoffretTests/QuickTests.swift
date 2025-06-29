//
//  QuickTests.swift
//  CoffretTests
//
//  Created by Rajkumar on 30/06/25.
//

import Testing
import Foundation
@testable import Coffret

/**
 Quick diagnostic tests to verify testing infrastructure.
 
 Simple tests that can help identify any basic setup issues.
 */
struct QuickTests {
    
    @Test func testBasicAssertions() async throws {
        // Basic assertions to verify testing framework
        #expect(true == true)
        #expect(1 + 1 == 2)
        #expect("hello".count == 5)
    }
    
    @Test func testFoundationAvailable() async throws {
        // Test that Foundation is working
        let url = URL(string: "https://example.com")
        #expect(url != nil)
        
        let date = Date()
        #expect(date.timeIntervalSince1970 > 0)
    }
    
    @Test func testFileManagerBasics() async throws {
        // Test basic file manager operations
        let tempDir = FileManager.default.temporaryDirectory
        #expect(tempDir.path.contains("tmp") || tempDir.path.contains("Temp"))
        
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        #expect(!documentsDir.isEmpty)
    }
    
    @Test func testCoffretModuleImport() async throws {
        // Test that we can access Coffret module classes
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        // This should work if the module is properly imported
        let node = FileTreeNode(url: tempDir)
        #expect(node.url == tempDir)
        #expect(node.isDirectory == true)
    }
}
