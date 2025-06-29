//
//  FileTreeNodeTests.swift
//  CoffretTests
//
//  Created by Rajkumar on 30/06/25.
//

import Testing
import Foundation
@testable import Coffret

/**
 Comprehensive unit tests for FileTreeNode class.
 
 Tests all aspects of the file tree functionality including node creation,
 hierarchy management, directory operations, and edge cases.
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 30/06/25
 */
struct FileTreeNodeTests {
    
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
    
    // MARK: - Initialization Tests
    
    @Test func testFileTreeNodeBasicInitialization() async throws {
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
    
    @Test func testFileTreeNodeWithFileInitialization() async throws {
        let tempDir = createTemporaryDirectory()
        let testFile = tempDir.appendingPathComponent("test.txt")
        createTestFile(at: testFile)
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: testFile)
        
        #expect(node.url == testFile)
        #expect(node.name == "test.txt")
        #expect(node.isDirectory == false)
        #expect(node.level == 0)
        #expect(node.parent == nil)
        #expect(node.children.isEmpty)
    }
    
    @Test func testFileTreeNodeHierarchicalInitialization() async throws {
        let tempDir = createTemporaryDirectory()
        let subDir = tempDir.appendingPathComponent("subdir")
        try! FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        defer { cleanup(tempDir) }
        
        let parentNode = FileTreeNode(url: tempDir)
        let childNode = FileTreeNode(url: subDir, parent: parentNode)
        
        #expect(childNode.parent === parentNode)
        #expect(childNode.level == 1)
        #expect(parentNode.level == 0)
    }
    
    @Test func testFileTreeNodeDeepHierarchy() async throws {
        let tempDir = createTemporaryDirectory()
        let level1 = tempDir.appendingPathComponent("level1")
        let level2 = level1.appendingPathComponent("level2")
        let level3 = level2.appendingPathComponent("level3")
        
        try! FileManager.default.createDirectory(at: level3, withIntermediateDirectories: true)
        defer { cleanup(tempDir) }
        
        let rootNode = FileTreeNode(url: tempDir)
        let node1 = FileTreeNode(url: level1, parent: rootNode)
        let node2 = FileTreeNode(url: level2, parent: node1)
        let node3 = FileTreeNode(url: level3, parent: node2)
        
        #expect(rootNode.level == 0)
        #expect(node1.level == 1)
        #expect(node2.level == 2)
        #expect(node3.level == 3)
        
        #expect(node3.parent === node2)
        #expect(node2.parent === node1)
        #expect(node1.parent === rootNode)
        #expect(rootNode.parent == nil)
    }
    
    // MARK: - Children Loading Tests
    
    @Test func testLoadChildrenEmpty() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: tempDir)
        
        #expect(node.children.isEmpty)
        #expect(node.isDirectory)
    }
    
    @Test func testLoadChildrenWithFiles() async throws {
        let tempDir = createTemporaryDirectory()
        let file1 = tempDir.appendingPathComponent("file1.txt")
        let file2 = tempDir.appendingPathComponent("file2.txt")
        let file3 = tempDir.appendingPathComponent("file3.txt")
        
        createTestFile(at: file1, content: "Content 1")
        createTestFile(at: file2, content: "Content 2")
        createTestFile(at: file3, content: "Content 3")
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: tempDir)
        
        #expect(node.children.count == 3)
        #expect(node.children.allSatisfy { !$0.isDirectory })
        
        let names = node.children.map { $0.name }.sorted()
        #expect(names == ["file1.txt", "file2.txt", "file3.txt"])
    }
    
    @Test func testLoadChildrenWithDirectories() async throws {
        let tempDir = createTemporaryDirectory()
        let dir1 = tempDir.appendingPathComponent("dir1")
        let dir2 = tempDir.appendingPathComponent("dir2")
        let dir3 = tempDir.appendingPathComponent("dir3")
        
        try! FileManager.default.createDirectory(at: dir1, withIntermediateDirectories: true)
        try! FileManager.default.createDirectory(at: dir2, withIntermediateDirectories: true)
        try! FileManager.default.createDirectory(at: dir3, withIntermediateDirectories: true)
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: tempDir)
        
        #expect(node.children.count == 3)
        #expect(node.children.allSatisfy { $0.isDirectory })
        
        let names = node.children.map { $0.name }.sorted()
        #expect(names == ["dir1", "dir2", "dir3"])
    }
    
    @Test func testLoadChildrenMixed() async throws {
        let tempDir = createTemporaryDirectory()
        let file1 = tempDir.appendingPathComponent("file1.txt")
        let file2 = tempDir.appendingPathComponent("file2.txt")
        let dir1 = tempDir.appendingPathComponent("directory1")
        let dir2 = tempDir.appendingPathComponent("directory2")
        
        createTestFile(at: file1)
        createTestFile(at: file2)
        try! FileManager.default.createDirectory(at: dir1, withIntermediateDirectories: true)
        try! FileManager.default.createDirectory(at: dir2, withIntermediateDirectories: true)
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: tempDir)
        
        #expect(node.children.count == 4)
        
        // Test sorting: directories first, then files
        let directories = node.children.filter { $0.isDirectory }
        let files = node.children.filter { !$0.isDirectory }
        
        #expect(directories.count == 2)
        #expect(files.count == 2)
        
        // Verify directories come first in the sorted array
        for i in 0..<directories.count {
            #expect(node.children[i].isDirectory)
        }
        
        for i in directories.count..<node.children.count {
            #expect(!node.children[i].isDirectory)
        }
    }
    
    // MARK: - Expansion Tests
    
    @Test func testToggleExpansionDirectory() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: tempDir)
        
        // Initial state
        #expect(node.isExpanded == false)
        
        // Toggle to expand
        node.toggleExpansion()
        #expect(node.isExpanded == true)
        
        // Toggle to collapse
        node.toggleExpansion()
        #expect(node.isExpanded == false)
    }
    
    @Test func testToggleExpansionFile() async throws {
        let tempDir = createTemporaryDirectory()
        let testFile = tempDir.appendingPathComponent("test.txt")
        createTestFile(at: testFile)
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: testFile)
        
        #expect(node.isExpanded == false)
        
        // Toggle should have no effect on files
        node.toggleExpansion()
        #expect(node.isExpanded == false)
    }
    
    @Test func testToggleExpansionLoadsChildren() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: tempDir)
        
        // Create files after node creation
        let file1 = tempDir.appendingPathComponent("created_after.txt")
        createTestFile(at: file1)
        
        // Initially empty
        #expect(node.children.isEmpty)
        
        // Toggle expansion should reload children
        node.toggleExpansion()
        #expect(node.isExpanded == true)
        #expect(node.children.count == 1)
        #expect(node.children[0].name == "created_after.txt")
    }
    
    // MARK: - Refresh Tests
    
    @Test func testRefreshDirectory() async throws {
        let tempDir = createTemporaryDirectory()
        let initialFile = tempDir.appendingPathComponent("initial.txt")
        createTestFile(at: initialFile)
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: tempDir)
        
        // Initial state
        #expect(node.children.count == 1)
        #expect(node.children[0].name == "initial.txt")
        
        // Add more files
        let newFile1 = tempDir.appendingPathComponent("new1.txt")
        let newFile2 = tempDir.appendingPathComponent("new2.txt")
        createTestFile(at: newFile1)
        createTestFile(at: newFile2)
        
        // Refresh
        node.refresh()
        
        #expect(node.children.count == 3)
        let names = node.children.map { $0.name }.sorted()
        #expect(names == ["initial.txt", "new1.txt", "new2.txt"])
    }
    
    @Test func testRefreshFile() async throws {
        let tempDir = createTemporaryDirectory()
        let testFile = tempDir.appendingPathComponent("test.txt")
        createTestFile(at: testFile)
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: testFile)
        
        // Refresh should have no effect on files
        #expect(node.children.isEmpty)
        node.refresh()
        #expect(node.children.isEmpty)
    }
    
    @Test func testRefreshAfterFileDeletion() async throws {
        let tempDir = createTemporaryDirectory()
        let file1 = tempDir.appendingPathComponent("file1.txt")
        let file2 = tempDir.appendingPathComponent("file2.txt")
        let file3 = tempDir.appendingPathComponent("file3.txt")
        
        createTestFile(at: file1)
        createTestFile(at: file2)
        createTestFile(at: file3)
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: tempDir)
        
        // Initial state
        #expect(node.children.count == 3)
        
        // Delete a file
        try! FileManager.default.removeItem(at: file2)
        
        // Refresh
        node.refresh()
        
        #expect(node.children.count == 2)
        let names = node.children.map { $0.name }.sorted()
        #expect(names == ["file1.txt", "file3.txt"])
    }
    
    // MARK: - Sorting Tests
    
    @Test func testChildrenSortingDirectoriesFirst() async throws {
        let tempDir = createTemporaryDirectory()
        
        // Create in mixed order
        let fileA = tempDir.appendingPathComponent("a_file.txt")
        let dirB = tempDir.appendingPathComponent("b_directory")
        let fileC = tempDir.appendingPathComponent("c_file.txt")
        let dirD = tempDir.appendingPathComponent("d_directory")
        
        createTestFile(at: fileA)
        try! FileManager.default.createDirectory(at: dirB, withIntermediateDirectories: true)
        createTestFile(at: fileC)
        try! FileManager.default.createDirectory(at: dirD, withIntermediateDirectories: true)
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: tempDir)
        
        #expect(node.children.count == 4)
        
        // First two should be directories
        #expect(node.children[0].isDirectory)
        #expect(node.children[1].isDirectory)
        
        // Last two should be files
        #expect(!node.children[2].isDirectory)
        #expect(!node.children[3].isDirectory)
        
        // Directories should be sorted alphabetically
        #expect(node.children[0].name == "b_directory")
        #expect(node.children[1].name == "d_directory")
        
        // Files should be sorted alphabetically
        #expect(node.children[2].name == "a_file.txt")
        #expect(node.children[3].name == "c_file.txt")
    }
    
    @Test func testChildrenSortingCaseInsensitive() async throws {
        let tempDir = createTemporaryDirectory()
        
        let fileA = tempDir.appendingPathComponent("Apple.txt")
        let fileB = tempDir.appendingPathComponent("banana.txt")
        let fileC = tempDir.appendingPathComponent("Cherry.txt")
        let fileD = tempDir.appendingPathComponent("date.txt")
        
        createTestFile(at: fileA)
        createTestFile(at: fileB)
        createTestFile(at: fileC)
        createTestFile(at: fileD)
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: tempDir)
        
        #expect(node.children.count == 4)
        
        let names = node.children.map { $0.name }
        #expect(names == ["Apple.txt", "banana.txt", "Cherry.txt", "date.txt"])
    }
    
    // MARK: - Edge Cases Tests
    
    @Test func testFileTreeNodeWithSpecialCharacters() async throws {
        let tempDir = createTemporaryDirectory()
        let specialFile = tempDir.appendingPathComponent("special file & name (with) [brackets] #1.txt")
        createTestFile(at: specialFile)
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: specialFile)
        
        #expect(node.name == "special file & name (with) [brackets] #1.txt")
        #expect(!node.isDirectory)
    }
    
    @Test func testFileTreeNodeWithUnicodeCharacters() async throws {
        let tempDir = createTemporaryDirectory()
        let unicodeFile = tempDir.appendingPathComponent("测试文件_🎉_файл.txt")
        createTestFile(at: unicodeFile)
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: unicodeFile)
        
        #expect(node.name == "测试文件_🎉_файл.txt")
        #expect(!node.isDirectory)
    }
    
    @Test func testFileTreeNodeWithLongName() async throws {
        let tempDir = createTemporaryDirectory()
        let longName = String(repeating: "a", count: 200) + ".txt"
        let longFile = tempDir.appendingPathComponent(longName)
        createTestFile(at: longFile)
        defer { cleanup(tempDir) }
        
        let node = FileTreeNode(url: longFile)
        
        #expect(node.name == longName)
        #expect(node.name.count == 204) // 200 + ".txt"
    }
    
    @Test func testFileTreeNodeWithNonExistentPath() async throws {
        let nonExistentURL = URL(fileURLWithPath: "/path/that/does/not/exist")
        let node = FileTreeNode(url: nonExistentURL)
        
        #expect(node.url == nonExistentURL)
        #expect(node.name == "exist")
        #expect(node.children.isEmpty)
        #expect(!node.isDirectory) // Non-existent paths default to false
    }
    
    @Test func testFileTreeNodeWithSymlink() async throws {
        let tempDir = createTemporaryDirectory()
        let targetFile = tempDir.appendingPathComponent("target.txt")
        let symlinkFile = tempDir.appendingPathComponent("symlink.txt")
        
        createTestFile(at: targetFile, content: "Target content")
        
        // Create symlink (may fail on some systems, so we'll handle the error)
        do {
            try FileManager.default.createSymbolicLink(at: symlinkFile, withDestinationURL: targetFile)
            defer { cleanup(tempDir) }
            
            let node = FileTreeNode(url: symlinkFile)
            
            #expect(node.name == "symlink.txt")
            // Behavior with symlinks may vary by system
        } catch {
            // Symlink creation not supported, skip this test
            cleanup(tempDir)
        }
    }
    
    // MARK: - Performance Tests
    
    @Test func testLargeDirectoryPerformance() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        // Create 1000 files
        for i in 0..<1000 {
            let file = tempDir.appendingPathComponent("file\(String(format: "%04d", i)).txt")
            createTestFile(at: file, content: "Content \(i)")
        }
        
        let startTime = Date()
        let node = FileTreeNode(url: tempDir)
        let duration = Date().timeIntervalSince(startTime)
        
        #expect(node.children.count == 1000)
        #expect(duration < 5.0, "Loading 1000 files should take less than 5 seconds")
        
        // Test that children are properly sorted
        let firstChild = node.children.first!
        let lastChild = node.children.last!
        #expect(firstChild.name == "file0000.txt")
        #expect(lastChild.name == "file0999.txt")
    }
    
    @Test func testDeepHierarchyPerformance() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        var currentDir = tempDir
        var nodes: [FileTreeNode] = []
        
        // Create 50-level deep hierarchy
        for i in 0..<50 {
            currentDir = currentDir.appendingPathComponent("level\(i)")
            try! FileManager.default.createDirectory(at: currentDir, withIntermediateDirectories: true)
            
            let parent = nodes.last
            let node = FileTreeNode(url: currentDir, parent: parent)
            nodes.append(node)
        }
        
        // Verify hierarchy is correct
        #expect(nodes.count == 50)
        #expect(nodes.last!.level == 49)
        
        // Test hierarchy traversal
        var current = nodes.last
        var levels = 0
        while let node = current {
            levels += 1
            current = node.parent
        }
        
        #expect(levels == 50)
    }
}
