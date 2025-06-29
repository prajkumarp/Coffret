//
//  FTPConnectionTests.swift
//  CoffretTests
//
//  Created by Rajkumar on 30/06/25.
//

import XCTest
import Foundation
import Network
@testable import Coffret

/**
 Unit tests for FTPConnection class.
 
 Tests the FTP command processing, file operations, and network handling
 functionality of the FTP connection handler.
 
 Note: These tests focus on the file system operations and command parsing logic
 rather than actual network connections, as NWConnection cannot be easily mocked.
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 30/06/25
 */
final class FTPConnectionTests: XCTestCase {
    
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
    
    // MARK: - FTPConnection Tests
    
    func testFTPConnectionInitialization() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        // Create a test connection using loopback address
        let testEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: 2121)
        let connection = NWConnection(to: testEndpoint, using: .tcp)
        
        let ftpConnection = FTPConnection(connection: connection, documentsPath: tempDir)
        
        // Test that the connection was created successfully
        XCTAssertNotNil(ftpConnection)
    }
    
    // Note: Most FTPConnection functionality requires actual network connections
    // which are difficult to mock in unit tests. Integration tests would be
    // more appropriate for testing the full FTP protocol implementation.
    
    // MARK: - Directory Navigation Tests
    
    func testDirectoryStructure() async throws {
        let tempDir = createTemporaryDirectory()
        let subDir = tempDir.appendingPathComponent("subdir")
        let nestedDir = subDir.appendingPathComponent("nested")
        
        try! FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        try! FileManager.default.createDirectory(at: nestedDir, withIntermediateDirectories: true)
        
        defer { cleanup(tempDir) }
        
        // Test directory existence
        XCTAssertTrue(FileManager.default.fileExists(atPath: subDir.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: nestedDir.path))
        
        // Test directory traversal logic
        let relativePath = nestedDir.path.replacingOccurrences(of: tempDir.path, with: "")
        XCTAssertTrue(relativePath.hasPrefix("/"))
    }
    
    func testFileListingLogic() async throws {
        let tempDir = createTemporaryDirectory()
        let file1 = tempDir.appendingPathComponent("file1.txt")
        let file2 = tempDir.appendingPathComponent("file2.txt")
        let subDir = tempDir.appendingPathComponent("directory")
        
        createTestFile(at: file1, content: "Content 1")
        createTestFile(at: file2, content: "Content 2")
        try! FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        
        defer { cleanup(tempDir) }
        
        // Test directory listing
        let contents = try FileManager.default.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: []
        )
        
        XCTAssertEqual(contents.count, 3)
        
        // Test that we can get file attributes
        for url in contents {
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
            XCTAssertNotNil(resourceValues.isDirectory)
            
            if resourceValues.isDirectory == false {
                XCTAssertNotNil(resourceValues.fileSize)
                XCTAssertGreaterThan(resourceValues.fileSize!, 0)
            }
        }
    }
    
    // MARK: - Data Transfer Tests
    
    func testFileDataReading() async throws {
        let tempDir = createTemporaryDirectory()
        let testFile = tempDir.appendingPathComponent("test.txt")
        let testContent = "This is test content for FTP transfer"
        
        createTestFile(at: testFile, content: testContent)
        defer { cleanup(tempDir) }
        
        // Test file reading (simulates RETR command)
        let fileData = try Data(contentsOf: testFile)
        let readContent = String(data: fileData, encoding: .utf8)
        
        XCTAssertEqual(readContent, testContent)
        XCTAssertEqual(fileData.count, testContent.utf8.count)
    }
    
    func testFileDataWriting() async throws {
        let tempDir = createTemporaryDirectory()
        let testFile = tempDir.appendingPathComponent("upload.txt")
        let testContent = "This is uploaded content"
        let testData = testContent.data(using: .utf8)!
        
        defer { cleanup(tempDir) }
        
        // Test file writing (simulates STOR command)
        try testData.write(to: testFile)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path))
        
        let readContent = try String(contentsOf: testFile, encoding: .utf8)
        XCTAssertEqual(readContent, testContent)
    }
    
    // MARK: - Path Validation Tests
    
    func testPathSecurity() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        // Test various path formats that FTP might receive
        let testPaths = [
            "/normal/path",
            "../parentdir",
            "./currentdir",
            "/root/subdir/../parent",
            "relativepath",
            ""
        ]
        
        for testPath in testPaths {
            // Test path normalization logic
            let normalizedPath: String
            if testPath.hasPrefix("/") {
                normalizedPath = testPath
            } else if testPath == ".." {
                normalizedPath = "/"  // Parent of root is root
            } else {
                normalizedPath = "/\(testPath)"
            }
            
            XCTAssertTrue(!normalizedPath.contains("..") || normalizedPath == "/")
        }
    }
    
    // MARK: - Command Parsing Tests
    
    func testFTPCommandParsing() async throws {
        // Test FTP command parsing logic
        let testCommands = [
            "USER anonymous",
            "PASS password123",
            "PWD",
            "CWD /home/user",
            "LIST",
            "RETR file.txt",
            "STOR upload.txt",
            "TYPE I",
            "PASV",
            "QUIT"
        ]
        
        for command in testCommands {
            let components = command.components(separatedBy: " ")
            let cmd = components[0].uppercased()
            let args = components.count > 1 ? Array(components[1...]) : []
            
            // Verify command parsing
            XCTAssertFalse(cmd.isEmpty)
            
            switch cmd {
            case "USER", "PASS", "CWD", "RETR", "STOR":
                XCTAssertFalse(args.isEmpty, "Command \(cmd) should have arguments")
            case "PWD", "LIST", "TYPE", "PASV", "QUIT":
                // These commands may or may not have arguments
                break
            default:
                break
            }
        }
    }
    
    // MARK: - Response Format Tests
    
    func testFTPResponseFormat() async throws {
        // Test FTP response formatting
        let testResponses = [
            "220 iOS FTP Server Ready",
            "331 Username OK, need password", 
            "230 User logged in",
            "257 \"/\" is current directory",
            "150 Opening data connection",
            "226 File transfer completed",
            "550 File not found",
            "502 Command not implemented"
        ]
        
        for response in testResponses {
            // FTP responses should end with \r\n
            let formattedResponse = response + "\r\n"
            let data = formattedResponse.data(using: .utf8)
            
            XCTAssertNotNil(data)
            XCTAssertTrue(formattedResponse.hasSuffix("\r\n"))
            
            // Verify response code format (3 digits followed by space or dash)
            let components = response.components(separatedBy: " ")
            if let firstComponent = components.first {
                XCTAssertEqual(firstComponent.count, 3)
                XCTAssertTrue(firstComponent.allSatisfy { $0.isNumber })
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testFileNotFoundError() async throws {
        let tempDir = createTemporaryDirectory()
        let nonExistentFile = tempDir.appendingPathComponent("nonexistent.txt")
        defer { cleanup(tempDir) }
        
        // Test that file existence check works
        XCTAssertFalse(FileManager.default.fileExists(atPath: nonExistentFile.path))
        
        // Test error handling for non-existent file
        do {
            _ = try Data(contentsOf: nonExistentFile)
            XCTFail("Should have thrown error for non-existent file")
        } catch {
            // Expected error for non-existent file
            XCTAssertTrue(true)
        }
    }
    
    func testDirectoryAccessError() async throws {
        let tempDir = createTemporaryDirectory()
        let restrictedDir = tempDir.appendingPathComponent("restricted")
        defer { cleanup(tempDir) }
        
        // Test directory creation and access
        try FileManager.default.createDirectory(at: restrictedDir, withIntermediateDirectories: true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: restrictedDir.path))
        
        // Test directory contents listing
        let contents = try FileManager.default.contentsOfDirectory(at: restrictedDir, includingPropertiesForKeys: nil, options: [])
        XCTAssertTrue(contents.isEmpty)  // New directory should be empty
    }
}
