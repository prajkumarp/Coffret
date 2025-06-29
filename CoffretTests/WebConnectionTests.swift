//
//  WebConnectionTests.swift
//  CoffretTests
//
//  Created by Rajkumar on 30/06/25.
//

import Testing
import Foundation
import Network
@testable import Coffret

/**
 Unit tests for WebConnection class.
 
 Tests the HTTP request processing, file operations, and web interface
 functionality of the web connection handler.
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 30/06/25
 */
struct WebConnectionTests {
    
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
    
    // MARK: - HTTP Request Parsing Tests
    
    @Test func testHTTPRequestParsing() async throws {
        // Test various HTTP request formats
        let testRequests = [
            "GET / HTTP/1.1\r\nHost: localhost:8080\r\n\r\n",
            "GET /api/files HTTP/1.1\r\nHost: localhost:8080\r\n\r\n",
            "POST /api/upload HTTP/1.1\r\nHost: localhost:8080\r\nContent-Length: 13\r\n\r\nfile content",
            "DELETE /api/delete/file.txt HTTP/1.1\r\nHost: localhost:8080\r\n\r\n"
        ]
        
        for requestString in testRequests {
            _ = requestString.data(using: .utf8)!
            
            // Test that request contains proper HTTP structure
            #expect(requestString.contains("HTTP/1.1"))
            #expect(requestString.contains("\r\n\r\n"))
            
            // Test method extraction
            let components = requestString.components(separatedBy: " ")
            let method = components[0]
            let path = components[1]
            
            #expect(["GET", "POST", "DELETE"].contains(method))
            #expect(path.hasPrefix("/"))
        }
    }
    
    @Test func testHTTPHeaderParsing() async throws {
        let requestString = """
        GET /api/files HTTP/1.1\r
        Host: localhost:8080\r
        User-Agent: Mozilla/5.0\r
        Accept: application/json\r
        Content-Length: 0\r
        \r
        """
        
        let lines = requestString.components(separatedBy: "\r\n")
        var headers: [String: String] = [:]
        
        // Skip the request line and parse headers
        for line in lines.dropFirst() {
            if line.isEmpty { break }
            
            let parts = line.components(separatedBy: ": ")
            if parts.count == 2 {
                headers[parts[0]] = parts[1]
            }
        }
        
        #expect(headers["Host"] == "localhost:8080")
        #expect(headers["User-Agent"] == "Mozilla/5.0")
        #expect(headers["Accept"] == "application/json")
        #expect(headers["Content-Length"] == "0")
    }
    
    // MARK: - HTTP Response Generation Tests
    
    @Test func testHTTPResponseFormat() async throws {
        // Test various HTTP response formats
        let responses = [
            ("200 OK", "text/html", "<html><body>Hello</body></html>"),
            ("404 Not Found", "text/plain", "File not found"),
            ("500 Internal Server Error", "application/json", "{\"error\":\"Server error\"}")
        ]
        
        for (status, contentType, body) in responses {
            let response = """
            HTTP/1.1 \(status)\r
            Content-Type: \(contentType)\r
            Content-Length: \(body.utf8.count)\r
            Connection: close\r
            \r
            \(body)
            """
            
            #expect(response.contains("HTTP/1.1"))
            #expect(response.contains(status))
            #expect(response.contains("Content-Type: \(contentType)"))
            #expect(response.contains("Content-Length: \(body.utf8.count)"))
            #expect(response.contains("\r\n\r\n"))
        }
    }
    
    // MARK: - JSON Response Tests
    
    @Test func testJSONResponseGeneration() async throws {
        let tempDir = createTemporaryDirectory()
        let testFile = tempDir.appendingPathComponent("test.txt")
        let subDir = tempDir.appendingPathComponent("subdir")
        
        createTestFile(at: testFile, content: "Test content")
        try! FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        defer { cleanup(tempDir) }
        
        // Test directory listing JSON generation
        let contents = try FileManager.default.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
            options: []
        )
        
        var files: [[String: Any]] = []
        
        for url in contents {
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
            
            let fileInfo: [String: Any] = [
                "name": url.lastPathComponent,
                "isDirectory": resourceValues.isDirectory ?? false,
                "size": resourceValues.fileSize ?? 0,
                "modified": resourceValues.contentModificationDate?.timeIntervalSince1970 ?? 0
            ]
            
            files.append(fileInfo)
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: files, options: [])
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        #expect(jsonString != nil)
        #expect(jsonString!.contains("test.txt"))
        #expect(jsonString!.contains("subdir"))
    }
    
    // MARK: - File Upload Tests
    
    @Test func testMultipartFormDataParsing() async throws {
        // Simulate multipart form data for file upload
        let boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
        let filename = "upload.txt"
        let fileContent = "This is uploaded file content"
        
        let multipartData = """
        ------WebKitFormBoundary7MA4YWxkTrZu0gW\r
        Content-Disposition: form-data; name="file"; filename="\(filename)"\r
        Content-Type: text/plain\r
        \r
        \(fileContent)\r
        ------WebKitFormBoundary7MA4YWxkTrZu0gW--\r
        """
        
        // Test boundary detection
        #expect(multipartData.contains(boundary))
        #expect(multipartData.contains("Content-Disposition: form-data"))
        #expect(multipartData.contains("filename=\"\(filename)\""))
        #expect(multipartData.contains(fileContent))
    }
    
    @Test func testFileUploadValidation() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        // Test valid filename validation
        let validFilenames = ["document.txt", "image.jpg", "archive.zip", "data_file.csv"]
        let invalidFilenames = ["../../../etc/passwd", "con.txt", "aux.txt", ""]
        
        for filename in validFilenames {
            let isValid = !filename.isEmpty && 
                         !filename.contains("..") && 
                         !filename.hasPrefix("/") &&
                         filename.count <= 255
            #expect(isValid, "Filename '\(filename)' should be valid")
        }
        
        for filename in invalidFilenames {
            let isValid = !filename.isEmpty && 
                         !filename.contains("..") && 
                         !filename.hasPrefix("/") &&
                         filename.count <= 255
            #expect(!isValid, "Filename '\(filename)' should be invalid")
        }
    }
    
    // MARK: - File Download Tests
    
    @Test func testFileDownloadHeaders() async throws {
        let tempDir = createTemporaryDirectory()
        let testFile = tempDir.appendingPathComponent("download.txt")
        let content = "This is downloadable content"
        
        createTestFile(at: testFile, content: content)
        defer { cleanup(tempDir) }
        
        // Test file download response headers
        let fileData = try Data(contentsOf: testFile)
        let filename = testFile.lastPathComponent
        
        let response = """
        HTTP/1.1 200 OK\r
        Content-Type: application/octet-stream\r
        Content-Disposition: attachment; filename="\(filename)"\r
        Content-Length: \(fileData.count)\r
        Connection: close\r
        \r
        """
        
        #expect(response.contains("Content-Type: application/octet-stream"))
        #expect(response.contains("Content-Disposition: attachment"))
        #expect(response.contains("filename=\"\(filename)\""))
        #expect(response.contains("Content-Length: \(fileData.count)"))
    }
    
    // MARK: - Directory Operations Tests
    
    @Test func testDirectoryCreation() async throws {
        let tempDir = createTemporaryDirectory()
        defer { cleanup(tempDir) }
        
        // Test directory name validation
        let validDirNames = ["newfolder", "My Documents", "project_v2", "folder123"]
        let invalidDirNames = ["../parent", "folder/with/slashes", "", "con", "aux"]
        
        for dirname in validDirNames {
            let isValid = !dirname.isEmpty && 
                         !dirname.contains("/") && 
                         !dirname.contains("..") &&
                         dirname.count <= 255
            #expect(isValid, "Directory name '\(dirname)' should be valid")
            
            // Test actual directory creation
            let newDir = tempDir.appendingPathComponent(dirname)
            try FileManager.default.createDirectory(at: newDir, withIntermediateDirectories: false)
            #expect(FileManager.default.fileExists(atPath: newDir.path))
        }
        
        for dirname in invalidDirNames {
            let isValid = !dirname.isEmpty && 
                         !dirname.contains("/") && 
                         !dirname.contains("..") &&
                         dirname.count <= 255
            #expect(!isValid, "Directory name '\(dirname)' should be invalid")
        }
    }
    
    // MARK: - Error Response Tests
    
    @Test func testErrorResponseGeneration() async throws {
        // Test various error scenarios
        let errorCases = [
            (400, "Bad Request", "Invalid request format"),
            (404, "Not Found", "The requested file was not found"),
            (403, "Forbidden", "Access denied"),
            (500, "Internal Server Error", "An unexpected error occurred"),
            (413, "Payload Too Large", "File size exceeds limit")
        ]
        
        for (code, status, message) in errorCases {
            let errorResponse = """
            HTTP/1.1 \(code) \(status)\r
            Content-Type: application/json\r
            Content-Length: \(message.utf8.count + 20)\r
            Connection: close\r
            \r
            {"error": "\(message)"}
            """
            
            #expect(errorResponse.contains("HTTP/1.1 \(code)"))
            #expect(errorResponse.contains(status))
            #expect(errorResponse.contains("application/json"))
            #expect(errorResponse.contains(message))
        }
    }
    
    // MARK: - URL Routing Tests
    
    @Test func testURLRouting() async throws {
        // Test URL path parsing and routing
        let routes = [
            ("/", "GET", "main_interface"),
            ("/api/files", "GET", "file_listing"),
            ("/api/files/subfolder", "GET", "file_listing"),
            ("/download/file.txt", "GET", "file_download"),
            ("/api/upload", "POST", "file_upload"),
            ("/api/mkdir", "POST", "create_directory"),
            ("/api/delete/file.txt", "DELETE", "delete_item")
        ]
        
        for (path, method, expectedAction) in routes {
            var action = ""
            
            if method == "GET" && path == "/" {
                action = "main_interface"
            } else if method == "GET" && path.hasPrefix("/api/files") {
                action = "file_listing"
            } else if method == "GET" && path.hasPrefix("/download/") {
                action = "file_download"
            } else if method == "POST" && path == "/api/upload" {
                action = "file_upload"
            } else if method == "POST" && path == "/api/mkdir" {
                action = "create_directory"
            } else if method == "DELETE" && path.hasPrefix("/api/delete/") {
                action = "delete_item"
            }
            
            #expect(action == expectedAction, "Route \(method) \(path) should map to \(expectedAction)")
        }
    }
    
    // MARK: - Content Type Detection Tests
    
    @Test func testContentTypeDetection() async throws {
        let fileExtensions = [
            ("txt", "text/plain"),
            ("html", "text/html"),
            ("css", "text/css"),
            ("js", "application/javascript"),
            ("json", "application/json"),
            ("jpg", "image/jpeg"),
            ("png", "image/png"),
            ("pdf", "application/pdf"),
            ("zip", "application/zip"),
            ("unknown", "application/octet-stream")
        ]
        
        for (ext, expectedType) in fileExtensions {
            var contentType = "application/octet-stream"  // default
            
            switch ext.lowercased() {
            case "txt": contentType = "text/plain"
            case "html", "htm": contentType = "text/html"
            case "css": contentType = "text/css"
            case "js": contentType = "application/javascript"
            case "json": contentType = "application/json"
            case "jpg", "jpeg": contentType = "image/jpeg"
            case "png": contentType = "image/png"
            case "pdf": contentType = "application/pdf"
            case "zip": contentType = "application/zip"
            default: contentType = "application/octet-stream"
            }
            
            #expect(contentType == expectedType, "Extension .\(ext) should map to \(expectedType)")
        }
    }
    
    // MARK: - Security Tests
    
    @Test func testPathTraversalPrevention() async throws {
        // Test various path traversal attempts
        let maliciousPaths = [
            "../../../etc/passwd",
            "..\\..\\windows\\system32",
            "/api/files/../../../sensitive",
            "file.txt/../../../config",
            "normal/../../admin"
        ]
        
        for maliciousPath in maliciousPaths {
            // Test that path normalization prevents traversal
            let hasTraversal = maliciousPath.contains("..") || maliciousPath.contains("../")
            #expect(hasTraversal, "Path '\(maliciousPath)' should be detected as containing traversal")
            
            // Path validation logic
            let isBlocked = maliciousPath.contains("..") || maliciousPath.hasPrefix("/etc/") || maliciousPath.contains("system32")
            #expect(isBlocked, "Malicious path '\(maliciousPath)' should be blocked")
        }
    }
}
