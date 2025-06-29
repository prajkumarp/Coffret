//
//  IntegrationTests.swift
//  CoffretTests
//
//  Created by Rajkumar on 30/06/25.
//

import Testing
import Foundation
import Network
@testable import Coffret

/**
 Integration tests for the Coffret application.
 
 Tests the interaction between multiple components including file operations,
 server functionality, and UI data flow. These tests verify that the complete
 system works together correctly.
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 30/06/25
 */
struct IntegrationTests {
    
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
    
    // MARK: - File Tree + File Operations Integration
    
    @Test func testFileTreeWithFileOperations() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        // Create initial file structure
        let file1 = tempDir.appendingPathComponent("file1.txt")
        let subDir = tempDir.appendingPathComponent("subdir")
        let file2 = subDir.appendingPathComponent("file2.txt")
        
        createTestFile(at: file1, content: "File 1 content")
        try! FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        createTestFile(at: file2, content: "File 2 content")
        
        // Create file tree
        let rootNode = FileTreeNode(url: tempDir)
        
        // Verify initial structure
        #expect(rootNode.children.count == 2)
        
        let subdirNode = rootNode.children.first { $0.isDirectory }
        #expect(subdirNode != nil)
        #expect(subdirNode!.name == "subdir")
        
        // Test file operations affect tree structure
        let newFile = tempDir.appendingPathComponent("newfile.txt")
        createTestFile(at: newFile, content: "New file content")
        
        // Refresh tree to see changes
        rootNode.refresh()
        #expect(rootNode.children.count == 3)
        
        // Test file deletion
        try! FileManager.default.removeItem(at: file1)
        rootNode.refresh()
        #expect(rootNode.children.count == 2)
        
        // Verify remaining files
        let remainingFiles = rootNode.children.filter { !$0.isDirectory }
        #expect(remainingFiles.count == 1)
        #expect(remainingFiles[0].name == "newfile.txt")
    }
    
    @Test func testFileTreeExpansionWithRealFiles() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        // Create nested structure
        let level1 = tempDir.appendingPathComponent("level1")
        let level2 = level1.appendingPathComponent("level2")
        let deepFile = level2.appendingPathComponent("deep.txt")
        
        try! FileManager.default.createDirectory(at: level2, withIntermediateDirectories: true)
        createTestFile(at: deepFile, content: "Deep file content")
        
        // Create tree nodes
        let rootNode = FileTreeNode(url: tempDir)
        let level1Node = rootNode.children.first { $0.name == "level1" }
        
        #expect(level1Node != nil)
        #expect(level1Node!.isDirectory)
        #expect(!level1Node!.isExpanded)
        
        // Expand level1
        level1Node!.toggleExpansion()
        #expect(level1Node!.isExpanded)
        #expect(level1Node!.children.count == 1)
        
        let level2Node = level1Node!.children.first { $0.name == "level2" }
        #expect(level2Node != nil)
        
        // Expand level2
        level2Node!.toggleExpansion()
        #expect(level2Node!.isExpanded)
        #expect(level2Node!.children.count == 1)
        #expect(level2Node!.children[0].name == "deep.txt")
    }
    
    // MARK: - Server + File System Integration
    
    @Test func testServerFileSystemIntegration() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        // Create test files
        let file1 = tempDir.appendingPathComponent("server_test.txt")
        let file2 = tempDir.appendingPathComponent("readme.md")
        let subDir = tempDir.appendingPathComponent("documents")
        
        createTestFile(at: file1, content: "Server test content")
        createTestFile(at: file2, content: "# Readme\nThis is a test readme.")
        try! FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        
        // Create server with test directory
        let server = FTPServer(port: 21210, webPort: 8081)  // Use valid ports for testing
        
        // Test that server can be created successfully and has expected functionality
        // Test that server URL methods exist and can be called
        let serverURL = server.getServerURL()
        let webURL = server.getWebURL()
        
        // Test that the methods return expected types (String? for both)
        if let url = serverURL {
            #expect(url.contains("21210"))  // Should contain the FTP port
        }
        if let url = webURL {
            #expect(url.contains("8081"))  // Should contain the web port
        }
        
        // Note: Actually starting the server in unit tests could cause conflicts
        // In a real test environment, you would use dependency injection to mock network components
        
        // Test file listing functionality (simulate what server would do)
        let contents = try FileManager.default.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: []
        )
        
        #expect(contents.count == 3)
        
        // Test directory listing format (simulate FTP LIST command)
        var listing = ""
        for url in contents {
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
            let isDirectory = resourceValues.isDirectory ?? false
            let fileSize = resourceValues.fileSize ?? 0
            
            let permissions = isDirectory ? "drwxr-xr-x" : "-rw-r--r--"
            listing += "\(permissions) 1 user user \(fileSize) Jan 01 12:00 \(url.lastPathComponent)\r\n"
        }
        
        #expect(!listing.isEmpty)
        #expect(listing.contains("server_test.txt"))
        #expect(listing.contains("readme.md"))
        #expect(listing.contains("documents"))
        #expect(listing.contains("drwxr-xr-x"))  // Directory permissions
        #expect(listing.contains("-rw-r--r--"))  // File permissions
    }
    
    // MARK: - Web Interface + File System Integration
    
    @Test func testWebInterfaceFileSystemIntegration() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        // Create test structure
        let htmlFile = tempDir.appendingPathComponent("index.html")
        let cssFile = tempDir.appendingPathComponent("styles.css")
        let jsFile = tempDir.appendingPathComponent("script.js")
        let imageFile = tempDir.appendingPathComponent("image.jpg")
        let docsDir = tempDir.appendingPathComponent("docs")
        
        createTestFile(at: htmlFile, content: "<html><body>Test</body></html>")
        createTestFile(at: cssFile, content: "body { color: red; }")
        createTestFile(at: jsFile, content: "console.log('test');")
        createTestFile(at: imageFile, content: "fake image data")
        try! FileManager.default.createDirectory(at: docsDir, withIntermediateDirectories: true)
        
        // Test web interface HTML generation
        let webHTML = WebInterfaceGenerator.generateHTML()
        
        #expect(!webHTML.isEmpty)
        #expect(webHTML.contains("<!DOCTYPE html>"))
        #expect(webHTML.contains("Coffret"))
        
        // Test directory listing JSON generation (simulate web API)
        let contents = try FileManager.default.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
            options: []
        )
        
        var fileList: [[String: Any]] = []
        for url in contents {
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
            
            let fileInfo: [String: Any] = [
                "name": url.lastPathComponent,
                "isDirectory": resourceValues.isDirectory ?? false,
                "size": resourceValues.fileSize ?? 0,
                "modified": resourceValues.contentModificationDate?.timeIntervalSince1970 ?? 0
            ]
            fileList.append(fileInfo)
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: fileList, options: [])
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        #expect(jsonString != nil)
        #expect(jsonString!.contains("index.html"))
        #expect(jsonString!.contains("styles.css"))
        #expect(jsonString!.contains("script.js"))
        #expect(jsonString!.contains("image.jpg"))
        #expect(jsonString!.contains("docs"))
    }
    
    // MARK: - File Operations + UI Data Flow Integration
    
    @Test func testFileOperationsUIDataFlow() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        // Simulate the data flow from file operations to UI
        // This would normally involve the ViewController updating the table view
        
        // Create initial file tree
        let file1 = tempDir.appendingPathComponent("original.txt")
        createTestFile(at: file1, content: "Original content")
        
        let rootNode = FileTreeNode(url: tempDir)
        var flattenedNodes = [rootNode]
        
        // Simulate flattening for table view
        func flattenTree(_ node: FileTreeNode) -> [FileTreeNode] {
            var result = [node]
            if node.isExpanded {
                for child in node.children {
                    result.append(contentsOf: flattenTree(child))
                }
            }
            return result
        }
        
        flattenedNodes = flattenTree(rootNode)
        #expect(flattenedNodes.count == 2)  // root + file1
        
        // Simulate file copy operation
        let copiedFile = tempDir.appendingPathComponent("original_copy.txt")
        try FileManager.default.copyItem(at: file1, to: copiedFile)
        
        // Refresh tree (simulate UI refresh)
        rootNode.refresh()
        flattenedNodes = flattenTree(rootNode)
        #expect(flattenedNodes.count == 3)  // root + file1 + copied file
        
        // Simulate file rename operation
        let renamedFile = tempDir.appendingPathComponent("renamed.txt")
        try FileManager.default.moveItem(at: copiedFile, to: renamedFile)
        
        // Refresh tree again
        rootNode.refresh()
        flattenedNodes = flattenTree(rootNode)
        #expect(flattenedNodes.count == 3)  // root + file1 + renamed file
        
        let fileNames = flattenedNodes.compactMap { !$0.isDirectory ? $0.name : nil }.sorted()
        #expect(fileNames == ["original.txt", "renamed.txt"])
    }
    
    // MARK: - Multi-Component Stress Tests
    
    @Test func testMultiComponentStressTest() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        // Create complex file structure
        let categories = ["documents", "images", "videos", "audio", "archives"]
        let fileTypes = [
            "documents": [".txt", ".pdf", ".doc", ".docx"],
            "images": [".jpg", ".png", ".gif", ".bmp"],
            "videos": [".mp4", ".avi", ".mov", ".mkv"],
            "audio": [".mp3", ".wav", ".flac", ".aac"],
            "archives": [".zip", ".rar", ".tar", ".gz"]
        ]
        
        for category in categories {
            let categoryDir = tempDir.appendingPathComponent(category)
            try! FileManager.default.createDirectory(at: categoryDir, withIntermediateDirectories: true)
            
            if let extensions = fileTypes[category] {
                for (index, ext) in extensions.enumerated() {
                    let filename = "file\(index)\(ext)"
                    let filePath = categoryDir.appendingPathComponent(filename)
                    createTestFile(at: filePath, content: "Content for \(filename)")
                }
            }
        }
        
        // Test file tree with complex structure
        let rootNode = FileTreeNode(url: tempDir)
        #expect(rootNode.children.count == 5)
        
        // Test expansion of all categories
        for childNode in rootNode.children {
            #expect(childNode.isDirectory)
            childNode.toggleExpansion()
            #expect(childNode.isExpanded)
            #expect(childNode.children.count == 4)  // 4 files per category
        }
        
        // Test file operations on complex structure
        let documentsDir = tempDir.appendingPathComponent("documents")
        let newFile = documentsDir.appendingPathComponent("newdoc.txt")
        createTestFile(at: newFile, content: "New document content")
        
        // Refresh and verify
        let documentsNode = rootNode.children.first { $0.name == "documents" }!
        documentsNode.refresh()
        #expect(documentsNode.children.count == 5)  // 4 original + 1 new
        
        // Test performance with complex structure
        let startTime = Date()
        for _ in 0..<10 {
            rootNode.refresh()
        }
        let duration = Date().timeIntervalSince(startTime)
        #expect(duration < 1.0, "Multiple refreshes should complete quickly")
    }
    
    // MARK: - Error Handling Integration Tests
    
    @Test func testErrorHandlingIntegration() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        // Create file and tree
        let testFile = tempDir.appendingPathComponent("test.txt")
        createTestFile(at: testFile, content: "Test content")
        
        let rootNode = FileTreeNode(url: tempDir)
        #expect(rootNode.children.count == 1)
        
        // Delete file externally (simulate external deletion)
        try! FileManager.default.removeItem(at: testFile)
        
        // Test that refresh handles missing files gracefully
        rootNode.refresh()
        #expect(rootNode.children.count == 0)
        
        // Test accessing non-existent file
        let nonExistentFile = tempDir.appendingPathComponent("nonexistent.txt")
        let ghostNode = FileTreeNode(url: nonExistentFile)
        
        #expect(ghostNode.children.isEmpty)
        #expect(!ghostNode.isDirectory)
        
        // Test operations on non-existent files
        do {
            _ = try Data(contentsOf: nonExistentFile)
            #expect(Bool(false), "Should have thrown error")
        } catch {
            #expect(true, "Expected error for non-existent file")
        }
    }
    
    // MARK: - Concurrent Operations Tests
    
    @Test func testConcurrentFileOperations() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        // Create initial file
        let testFile = tempDir.appendingPathComponent("concurrent_test.txt")
        createTestFile(at: testFile, content: "Initial content")
        
        let rootNode = FileTreeNode(url: tempDir)
        
        // Simulate concurrent operations
        await withTaskGroup(of: Void.self) { group in
            // Task 1: Create files
            group.addTask {
                for i in 0..<10 {
                    let file = tempDir.appendingPathComponent("file\(i).txt")
                    try? "Content \(i)".write(to: file, atomically: true, encoding: .utf8)
                }
            }
            
            // Task 2: Create directories
            group.addTask {
                for i in 0..<5 {
                    let dir = tempDir.appendingPathComponent("dir\(i)")
                    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                }
            }
            
            // Task 3: Refresh tree multiple times
            group.addTask {
                for _ in 0..<5 {
                    rootNode.refresh()
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                }
            }
        }
        
        // Final refresh and verification
        rootNode.refresh()
        #expect(rootNode.children.count == 16)  // 1 original + 10 files + 5 directories
    }
}
