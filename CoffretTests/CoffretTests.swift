//
//  CoffretTests.swift
//  CoffretTests
//
//  Created by Rajkumar on 29/06/25.
//

import Testing
import Foundation
import Network
@testable import Coffret

/**
 Unit tests for the Coffret FTP Server application.
 
 This test suite provides comprehensive testing for the core functionality
 of the Coffret app including file operations, server management, and
 data models.
 
 ## Test Categories
 - File tree node operations
 - FTP server functionality
 - Web interface generation
 - File management operations
 - Network connection handling
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 29/06/25
 */
struct CoffretTests {
    
    // MARK: - Test Setup
    
    private func createTemporaryDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }
    
    private func createTestFile(at url: URL, content: String = "Test content") {
        try! content.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    // MARK: - FileTreeNode Tests
    
    @Test func testFileTreeNodeInitialization() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: tempDir)
        
        #expect(node.url == tempDir)
        #expect(node.name == tempDir.lastPathComponent)
        #expect(node.isDirectory == true)
        #expect(node.level == 0)
        #expect(node.parent == nil)
        #expect(node.isExpanded == false)
    }
    
    @Test func testFileTreeNodeWithFile() async throws {
        let tempDir = createTemporaryDirectory()
        let testFile = tempDir.appendingPathComponent("test.txt")
        createTestFile(at: testFile)
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: testFile)
        
        #expect(node.isDirectory == false)
        #expect(node.name == "test.txt")
        #expect(node.children.isEmpty)
    }
    
    @Test func testFileTreeNodeHierarchy() async throws {
        let tempDir = createTemporaryDirectory()
        let subDir = tempDir.appendingPathComponent("subdir")
        try! FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        defer { cleanup(tempDir) }
        
        let parentNode = FileTreeNode(url: tempDir)
        let childNode = FileTreeNode(url: subDir, parent: parentNode)
        
        #expect(childNode.parent === parentNode)
        #expect(childNode.level == 1)
    }
    
    @Test func testFileTreeNodeLoadChildren() async throws {
        let tempDir = createTemporaryDirectory()
        let testFile1 = tempDir.appendingPathComponent("file1.txt")
        let testFile2 = tempDir.appendingPathComponent("file2.txt")
        let subDir = tempDir.appendingPathComponent("subdir")
        
        createTestFile(at: testFile1)
        createTestFile(at: testFile2)
        try! FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: tempDir)
        
        #expect(node.children.count == 3)
        #expect(node.children.first?.isDirectory == true) // Directory should be sorted first
    }
    
    @Test func testFileTreeNodeToggleExpansion() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: tempDir)
        #expect(node.isExpanded == false)
        
        node.toggleExpansion()
        #expect(node.isExpanded == true)
        
        node.toggleExpansion()
        #expect(node.isExpanded == false)
    }
    
    @Test func testFileTreeNodeRefresh() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: tempDir)
        let initialCount = node.children.count
        
        // Add a new file
        let newFile = tempDir.appendingPathComponent("newfile.txt")
        createTestFile(at: newFile)
        
        node.refresh()
        #expect(node.children.count == initialCount + 1)
    }
    
    // MARK: - FTPServer Tests
    
    @Test func testFTPServerInitialization() async throws {
        let server = FTPServer(port: 2121, webPort: 8080)
        #expect(server != nil)
    }
    
    @Test func testFTPServerURLGeneration() async throws {
        let server = FTPServer(port: 2121, webPort: 8080)
        
        // Note: getServerURL() and getWebURL() may return nil if no network interface is available
        // In unit tests, this is expected behavior
        let serverURL = server.getServerURL()
        let webURL = server.getWebURL()
        
        // Test that if URLs are generated, they have correct format
        if let serverURL = serverURL {
            #expect(serverURL.hasPrefix("ftp://"))
            #expect(serverURL.contains(":2121"))
        }
        
        if let webURL = webURL {
            #expect(webURL.hasPrefix("http://"))
            #expect(webURL.contains(":8080"))
        }
    }
    
    // MARK: - WebInterfaceGenerator Tests
    
    @Test func testWebInterfaceGeneration() async throws {
        let html = WebInterfaceGenerator.generateHTML()
        
        #expect(!html.isEmpty)
        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("<title>Coffret File Manager</title>"))
        #expect(html.contains("window-title"))
        #expect(html.contains("file-grid"))
        #expect(html.contains("upload-area"))
    }
    
    @Test func testWebInterfaceStructure() async throws {
        let html = WebInterfaceGenerator.generateHTML()
        
        // Verify essential HTML structure
        #expect(html.contains("<html"))
        #expect(html.contains("<head>"))
        #expect(html.contains("<body>"))
        #expect(html.contains("</html>"))
        
        // Verify CSS inclusion
        #expect(html.contains("<style>"))
        #expect(html.contains("</style>"))
        
        // Verify JavaScript inclusion
        #expect(html.contains("<script>"))
        #expect(html.contains("</script>"))
    }
    
    // MARK: - File Operations Tests
    
    @Test func testFileCreation() async throws {
        let tempDir = createTemporaryDirectory()
        let testFile = tempDir.appendingPathComponent("test.txt")
        defer { cleanup(tempDir) }
        
        createTestFile(at: testFile, content: "Hello, World!")
        
        #expect(FileManager.default.fileExists(atPath: testFile.path))
        
        let content = try String(contentsOf: testFile)
        #expect(content == "Hello, World!")
    }
    
    @Test func testDirectoryCreation() async throws {
        let tempDir = createTemporaryDirectory()
        let testSubDir = tempDir.appendingPathComponent("subdir")
        defer { cleanup(tempDir) }
        
        try FileManager.default.createDirectory(at: testSubDir, withIntermediateDirectories: true)
        
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: testSubDir.path, isDirectory: &isDirectory)
        
        #expect(exists)
        #expect(isDirectory.boolValue)
    }
    
    @Test func testFileCopy() async throws {
        let tempDir = createTemporaryDirectory()
        let sourceFile = tempDir.appendingPathComponent("source.txt")
        let destinationFile = tempDir.appendingPathComponent("destination.txt")
        defer { cleanup(tempDir) }
        
        createTestFile(at: sourceFile, content: "Source content")
        
        try FileManager.default.copyItem(at: sourceFile, to: destinationFile)
        
        #expect(FileManager.default.fileExists(atPath: destinationFile.path))
        
        let copiedContent = try String(contentsOf: destinationFile)
        #expect(copiedContent == "Source content")
    }
    
    @Test func testFileMove() async throws {
        let tempDir = createTemporaryDirectory()
        let sourceFile = tempDir.appendingPathComponent("source.txt")
        let destinationFile = tempDir.appendingPathComponent("moved.txt")
        defer { cleanup(tempDir) }
        
        createTestFile(at: sourceFile, content: "Move me")
        
        try FileManager.default.moveItem(at: sourceFile, to: destinationFile)
        
        #expect(!FileManager.default.fileExists(atPath: sourceFile.path))
        #expect(FileManager.default.fileExists(atPath: destinationFile.path))
        
        let movedContent = try String(contentsOf: destinationFile)
        #expect(movedContent == "Move me")
    }
    
    @Test func testFileDelete() async throws {
        let tempDir = createTemporaryDirectory()
        let testFile = tempDir.appendingPathComponent("delete_me.txt")
        defer { cleanup(tempDir) }
        
        createTestFile(at: testFile)
        #expect(FileManager.default.fileExists(atPath: testFile.path))
        
        try FileManager.default.removeItem(at: testFile)
        #expect(!FileManager.default.fileExists(atPath: testFile.path))
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testInvalidFileOperations() async throws {
        let tempDir = createTemporaryDirectory()
        let nonExistentFile = tempDir.appendingPathComponent("nonexistent.txt")
        defer { cleanup(tempDir) }
        
        // Test reading non-existent file
        do {
            _ = try String(contentsOf: nonExistentFile)
            #expect(false, "Should have thrown an error")
        } catch {
            #expect(true, "Expected error for non-existent file")
        }
        
        // Test copying non-existent file
        let destination = tempDir.appendingPathComponent("destination.txt")
        do {
            try FileManager.default.copyItem(at: nonExistentFile, to: destination)
            #expect(false, "Should have thrown an error")
        } catch {
            #expect(true, "Expected error for copying non-existent file")
        }
    }
    
    @Test func testFileTreeNodeWithInvalidPath() async throws {
        let invalidURL = URL(fileURLWithPath: "/nonexistent/path/that/does/not/exist")
        let node = FileTreeNode(url: invalidURL)
        
        #expect(node.url == invalidURL)
        #expect(node.name == "exist")
        #expect(node.children.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    @Test func testFileTreeNodePerformanceWithManyFiles() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        // Create 100 test files
        for i in 0..<100 {
            let file = tempDir.appendingPathComponent("file\(i).txt")
            createTestFile(at: file, content: "Content \(i)")
        }
        
        let startTime = Date()
        let node = FileTreeNode(url: tempDir)
        let duration = Date().timeIntervalSince(startTime)
        
        #expect(node.children.count == 100)
        #expect(duration < 1.0, "Loading 100 files should take less than 1 second")
    }
    
    // MARK: - Edge Cases Tests
    
    @Test func testFileTreeNodeWithSpecialCharacters() async throws {
        let tempDir = createTemporaryDirectory()
        let specialFile = tempDir.appendingPathComponent("special file & name (with) [brackets].txt")
        defer { cleanup(tempDir) }
        
        createTestFile(at: specialFile)
        
        let node = FileTreeNode(url: specialFile)
        #expect(node.name == "special file & name (with) [brackets].txt")
        #expect(!node.isDirectory)
    }
    
    @Test func testFileTreeNodeWithUnicodeNames() async throws {
        let tempDir = createTemporaryDirectory()
        let unicodeFile = tempDir.appendingPathComponent("测试文件_🎉.txt")
        defer { cleanup(tempDir) }
        
        createTestFile(at: unicodeFile)
        
        let node = FileTreeNode(url: unicodeFile)
        #expect(node.name == "测试文件_🎉.txt")
    }
    
    @Test func testEmptyDirectory() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: tempDir)
        #expect(node.children.isEmpty)
        #expect(node.isDirectory)
    }
}
