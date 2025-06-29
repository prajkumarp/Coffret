import Foundation
import Network

/**
 Handles HTTP web connections for browser-based file access.
 
 This class provides a web interface for the FTP server, allowing users to browse,
 upload, download, and manage files through a web browser. It implements a basic
 HTTP server with REST API endpoints for file operations.
 
 ## Supported Operations
 - File browsing and directory listing
 - File upload and download
 - Directory creation
 - File and directory deletion
 - Web interface serving
 
 ## API Endpoints
 - `GET /` - Main web interface
 - `GET /api/files/{path}` - Directory listing
 - `GET /download/{path}` - File download
 - `POST /api/upload` - File upload
 - `POST /api/mkdir` - Create directory
 - `DELETE /api/delete/{path}` - Delete file/directory
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 29/06/25
 */
class WebConnection {
    
    // MARK: - Properties
    
    /// The network connection to the web client
    private let connection: NWConnection
    
    /// The root documents directory path
    private let documentsPath: URL
    
    // MARK: - Initialization
    
    /**
     Initializes a new web connection handler.
     
     - Parameters:
        - connection: The network connection to the client
        - documentsPath: The root directory for file operations
     */
    init(connection: NWConnection, documentsPath: URL) {
        self.connection = connection
        self.documentsPath = documentsPath
    }
    
    // MARK: - Connection Management
    
    /**
     Starts the web connection and begins listening for HTTP requests.
     */
    func start() {
        connection.start(queue: .global())
        receiveRequest()
    }
    
    /**
     Closes the web connection and cleans up resources.
     */
    func close() {
        connection.cancel()
    }
    
    // MARK: - Request Handling
    
    /// Buffer to accumulate incoming request data
    private var requestBuffer = Data()
    
    /**
     Continuously receives HTTP requests from the client.
     
     Sets up a proper receive loop to handle incoming HTTP requests.
     Handles both small requests and large file uploads properly.
     */
    private func receiveRequest() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Receive error: \(error)")
                self.close()
                return
            }
            
            if let data = data, !data.isEmpty {
                self.requestBuffer.append(data)
                
                // Try to process complete HTTP requests from the buffer
                self.processBufferedRequests()
            }
            
            // Continue receiving more data unless the connection is complete
            if !isComplete {
                self.receiveRequest()
            }
        }
    }
    
    /**
     Processes complete HTTP requests from the accumulated buffer.
     
     Handles both simple GET requests and large POST requests (file uploads).
     */
    private func processBufferedRequests() {
        while !requestBuffer.isEmpty {
            // Try to find a complete HTTP request in the buffer
            if let request = extractCompleteRequest() {
                handleHTTPRequest(request)
            } else {
                // Not enough data for a complete request yet
                break
            }
        }
    }
    
    /**
     Extracts a complete HTTP request from the buffer if available.
     
     - Returns: Complete request data if found, nil otherwise
     */
    private func extractCompleteRequest() -> Data? {
        print("🔍 extractCompleteRequest called - buffer size: \(requestBuffer.count) bytes")
        
        guard requestBuffer.count >= 4 else {
            print("🔍 Buffer too small for minimum HTTP request")
            return nil
        }
        
        // Debug: Show first 200 bytes of buffer as string if possible
        let previewSize = min(requestBuffer.count, 200)
        if let preview = String(data: requestBuffer.prefix(previewSize), encoding: .utf8) {
            print("🔍 Buffer preview (first \(previewSize) bytes):")
            print("'\(preview)'")
        } else {
            print("🔍 Buffer contains non-UTF8 data")
        }
        
        // Look for the end of headers manually to avoid any Data.range issues
        let headerEndPattern: [UInt8] = [0x0D, 0x0A, 0x0D, 0x0A] // \r\n\r\n
        var headerEndIndex: Int?
        
        // Ensure we have enough bytes to search for the pattern
        if requestBuffer.count >= 4 {
            // Use withUnsafeBytes for safe byte access
            headerEndIndex = requestBuffer.withUnsafeBytes { bytes in
                guard let buffer = bytes.bindMemory(to: UInt8.self).baseAddress else {
                    print("🔍 Could not bind buffer memory")
                    return nil
                }
                
                let bufferSize = bytes.count
                print("🔍 Searching in buffer of size: \(bufferSize)")
                
                // Ensure we have at least 4 bytes to search
                guard bufferSize >= 4 else {
                    print("🔍 Buffer too small: \(bufferSize) bytes")
                    return nil
                }
                
                // Search for the pattern safely - stop at bufferSize - 4 to avoid overflow
                let maxSearchIndex = bufferSize - 4
                for i in 0...maxSearchIndex {
                    let byte0 = buffer[i]
                    let byte1 = buffer[i + 1]
                    let byte2 = buffer[i + 2]
                    let byte3 = buffer[i + 3]
                    
                    if byte0 == 0x0D && byte1 == 0x0A && byte2 == 0x0D && byte3 == 0x0A {
                        print("🔍 Found header end pattern at position \(i)")
                        return i + 4
                    }
                }
                
                print("🔍 Header end pattern not found in buffer")
                return nil
            }
        }
        
        guard let headerEnd = headerEndIndex else {
            print("🔍 Headers not complete yet (no \\r\\n\\r\\n found)")
            return nil
        }
        
        print("🔍 Header end found at byte index: \(headerEnd)")
        
        // Validate headerEnd is within bounds
        guard headerEnd >= 4 && headerEnd <= requestBuffer.count else {
            print("❌ Invalid header end index: \(headerEnd), buffer size: \(requestBuffer.count)")
            return nil
        }
        
        // Extract headers for parsing - be very careful with bounds
        let headerEndWithoutMarker = headerEnd - 4
        guard headerEndWithoutMarker >= 0 && headerEndWithoutMarker <= requestBuffer.count else {
            print("❌ Invalid header calculation: headerEnd-4 = \(headerEndWithoutMarker)")
            return nil
        }
        
        let headerData = requestBuffer.prefix(headerEndWithoutMarker)
        guard let headerString = String(data: headerData, encoding: .utf8) else {
            print("❌ Could not decode headers as UTF-8")
            return nil
        }
        
        print("🔍 Headers:")
        print(headerString)
        
        // Parse Content-Length if present
        let headerLines = headerString.components(separatedBy: "\r\n")
        var contentLength = 0
        
        for line in headerLines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.lowercased().hasPrefix("content-length:") {
                let components = trimmedLine.components(separatedBy: ":")
                if components.count >= 2 {
                    let lengthString = components[1].trimmingCharacters(in: .whitespaces)
                    contentLength = Int(lengthString) ?? 0
                    print("🔍 Found Content-Length header: '\(trimmedLine)' -> \(contentLength)")
                }
                break
            }
        }
        
        print("🔍 Content-Length: \(contentLength)")
        let totalRequestSize = headerEnd + contentLength
        print("🔍 Total request size needed: \(totalRequestSize) bytes (headers: \(headerEnd) + body: \(contentLength))")
        print("🔍 Current buffer size: \(requestBuffer.count) bytes")
        
        // Validate total request size
        guard totalRequestSize >= headerEnd else {
            print("❌ Invalid total request size calculation")
            return nil
        }
        
        // Check if we have the complete request
        if requestBuffer.count >= totalRequestSize {
            print("✅ Complete request available - extracting \(totalRequestSize) bytes")
            
            // Validate we can safely extract the request
            guard totalRequestSize <= requestBuffer.count else {
                print("❌ Cannot extract \(totalRequestSize) bytes from \(requestBuffer.count) byte buffer")
                return nil
            }
            
            let completeRequest = requestBuffer.prefix(totalRequestSize)
            requestBuffer = requestBuffer.dropFirst(totalRequestSize)
            print("🔍 Remaining buffer size after extraction: \(requestBuffer.count)")
            return Data(completeRequest)
        } else {
            let needed = totalRequestSize - requestBuffer.count
            print("⏳ Request not complete yet - need \(needed) more bytes")
            return nil
        }
    }
    
    /**
     Processes HTTP requests from the client.
     
     Parses the HTTP request and routes it to the appropriate handler.
     Now properly handles binary data for file uploads.
     
     - Parameter data: The raw HTTP request data
     */
    private func handleHTTPRequest(_ data: Data) {
        print("🔍 handleHTTPRequest called with \(data.count) bytes")
        
        // Find the end of headers (double CRLF) without converting all data to string
        guard let headerEndRange = data.range(of: "\r\n\r\n".data(using: .utf8)!) else {
            print("❌ Could not find header end in request")
            sendHTTPResponse(statusCode: 400, body: "Bad Request")
            return
        }
        
        // Only parse headers as string, not the entire request
        let headerData = data[..<headerEndRange.lowerBound]
        guard let headerString = String(data: headerData, encoding: .utf8) else {
            print("❌ Could not decode headers as UTF-8")
            sendHTTPResponse(statusCode: 400, body: "Bad Request")
            return
        }
        
        let lines = headerString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            print("❌ No request line found")
            sendHTTPResponse(statusCode: 400, body: "Bad Request")
            return
        }
        
        let components = requestLine.components(separatedBy: " ")
        guard components.count >= 2 else {
            print("❌ Invalid request line format")
            sendHTTPResponse(statusCode: 400, body: "Bad Request")
            return
        }
        
        let method = components[0]
        let path = components[1]
        
        print("📍 Processing \(method) request to \(path)")
        
        // Parse HTTP headers
        var headers: [String: String] = [:]
        
        for line in lines.dropFirst() {
            if line.contains(":") {
                let headerComponents = line.components(separatedBy: ": ")
                if headerComponents.count >= 2 {
                    headers[headerComponents[0]] = headerComponents[1]
                }
            }
        }
        
        // Extract body data (everything after the double CRLF)
        let bodyData = data[headerEndRange.upperBound...]
        
        // Route request to appropriate handler
        switch method {
        case "GET":
            handleGETRequest(path: path)
        case "POST":
            handlePOSTRequest(path: path, bodyData: Data(bodyData), headers: headers)
        case "DELETE":
            handleDELETERequest(path: path)
        default:
            sendHTTPResponse(statusCode: 405, body: "Method Not Allowed")
        }
    }
    
    // MARK: - HTTP Method Handlers
    
    /**
     Handles HTTP GET requests.
     
     Routes GET requests to appropriate handlers based on the path.
     
     - Parameter path: The requested URL path
     */
    private func handleGETRequest(path: String) {
        if path == "/" || path == "/index.html" {
            sendWebInterface()
        } else if path.hasPrefix("/api/files") {
            let queryPath = path.replacingOccurrences(of: "/api/files", with: "")
            sendFileList(for: queryPath)
        } else if path.hasPrefix("/download/") {
            let filePath = String(path.dropFirst(10)) // Remove "/download/"
            sendFileDownload(filePath: filePath)
        } else {
            sendHTTPResponse(statusCode: 404, body: "Not Found")
        }
    }
    
    /**
     Handles HTTP POST requests.
     
     Routes POST requests for file uploads and directory creation.
     Now properly handles binary data for file uploads.
     
     - Parameters:
        - path: The requested URL path
        - bodyData: The raw request body data
        - headers: The HTTP headers
     */
    private func handlePOSTRequest(path: String, bodyData: Data, headers: [String: String]) {
        if path == "/api/upload" {
            handleFileUpload(bodyData: bodyData, headers: headers)
        } else if path == "/api/mkdir" {
            // Convert to string for JSON data
            let body = String(data: bodyData, encoding: .utf8) ?? ""
            handleCreateDirectory(body: body)
        } else {
            sendHTTPResponse(statusCode: 404, body: "Not Found")
        }
    }
    
    /**
     Handles HTTP DELETE requests.
     
     Routes DELETE requests for file and directory deletion.
     
     - Parameter path: The requested URL path
     */
    private func handleDELETERequest(path: String) {
        if path.hasPrefix("/api/delete/") {
            let filePath = String(path.dropFirst(12)) // Remove "/api/delete/"
            handleFileDelete(filePath: filePath)
        } else {
            sendHTTPResponse(statusCode: 404, body: "Not Found")
        }
    }
    
    // MARK: - Response Handlers
    
    /**
     Sends the main web interface HTML.
     */
    private func sendWebInterface() {
        let html = WebInterfaceGenerator.generateHTML()
        sendHTTPResponse(statusCode: 200, body: html, contentType: "text/html")
    }
    
    /**
     Sends a directory listing as JSON.
     
     - Parameter path: The directory path to list
     */
    private func sendFileList(for path: String) {
        print("📂 File list request for path: '\(path)'")
        
        let decodedPath = path.removingPercentEncoding ?? path
        let fullPath = documentsPath.appendingPathComponent(decodedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        
        print("📂 Decoded path: '\(decodedPath)'")
        print("📂 Full path: '\(fullPath.path)'")
        print("📂 Documents path: '\(documentsPath.path)'")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: fullPath, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
            
            var fileInfos: [[String: Any]] = []
            
            for file in files {
                let resourceValues = try file.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                let isDirectory = resourceValues.isDirectory ?? false
                let fileSize = resourceValues.fileSize ?? 0
                let modDate = resourceValues.contentModificationDate ?? Date()
                
                // Construct relative path more carefully
                let absolutePath = file.path
                let documentsPathString = documentsPath.path
                
                var relativePath: String
                if absolutePath.hasPrefix(documentsPathString) {
                    relativePath = String(absolutePath.dropFirst(documentsPathString.count))
                    // Ensure path starts with /
                    if !relativePath.hasPrefix("/") {
                        relativePath = "/" + relativePath
                    }
                } else {
                    relativePath = "/" + file.lastPathComponent
                }
                
                print("📂 File: '\(file.lastPathComponent)' -> path: '\(relativePath)'")
                
                fileInfos.append([
                    "name": file.lastPathComponent,
                    "path": relativePath,
                    "isDirectory": isDirectory,
                    "size": fileSize,
                    "modified": ISO8601DateFormatter().string(from: modDate)
                ])
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: fileInfos, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "[]"
            
            print("📂 Returning \(fileInfos.count) files")
            sendHTTPResponse(statusCode: 200, body: jsonString, contentType: "application/json")
        } catch {
            print("❌ Error listing files: \(error)")
            sendHTTPResponse(statusCode: 500, body: "Internal Server Error")
        }
    }
    
    /**
     Sends a file for download.
     
     - Parameter filePath: The path of the file to download
     */
    private func sendFileDownload(filePath: String) {
        print("📥 Download request for file: '\(filePath)'")
        
        // URL decode the path properly
        let decodedPath = filePath.removingPercentEncoding ?? filePath
        print("📥 Decoded path: '\(decodedPath)'")
        
        // Clean the path - remove leading/trailing slashes and handle special characters
        let cleanPath = decodedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        print("📥 Clean path: '\(cleanPath)'")
        
        let fullPath = documentsPath.appendingPathComponent(cleanPath)
        print("📥 Full path: '\(fullPath.path)'")
        print("📥 Documents path: '\(documentsPath.path)'")
        
        // Check if file exists
        let fileExists = FileManager.default.fileExists(atPath: fullPath.path)
        print("📥 File exists: \(fileExists)")
        
        // If file doesn't exist, try to list what files are actually in the documents directory
        if !fileExists {
            print("📥 File not found, listing documents directory contents:")
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: documentsPath.path)
                for file in contents {
                    print("📥   Found file: '\(file)'")
                }
            } catch {
                print("📥   Error listing directory: \(error)")
            }
        }
        
        guard fileExists else {
            print("❌ File not found at path: '\(fullPath.path)'")
            sendHTTPResponse(statusCode: 404, body: "File Not Found")
            return
        }
        
        do {
            let fileData = try Data(contentsOf: fullPath)
            let fileName = fullPath.lastPathComponent
            print("✅ Sending file: '\(fileName)' (\(fileData.count) bytes)")
            sendHTTPResponse(statusCode: 200, body: fileData, contentType: "application/octet-stream", fileName: fileName)
        } catch {
            print("❌ Error reading file: \(error)")
            sendHTTPResponse(statusCode: 500, body: "Internal Server Error")
        }
    }
    
    // MARK: - File Operations
    
    /**
     Handles file upload from the client.
     
     Parses the multipart form data and saves the uploaded file to the server.
     This implementation properly handles binary data for file uploads and supports
     uploading to specific directories within the documents folder.
     
     - Parameters:
        - bodyData: The raw request body data containing the multipart form data
        - headers: The HTTP headers including Content-Type
     */
    private func handleFileUpload(bodyData: Data, headers: [String: String]) {
        print("📤 Upload request received - Body size: \(bodyData.count) bytes")
        print("📤 Headers: \(headers)")
        
        // Validate Content-Type for multipart form data
        guard let contentType = headers["Content-Type"],
              contentType.contains("multipart/form-data") else {
            print("❌ Invalid Content-Type: \(headers["Content-Type"] ?? "nil")")
            sendHTTPResponse(statusCode: 400, body: "Invalid Content-Type")
            return
        }
        
        // Extract boundary from Content-Type header
        let boundaryPrefix = "boundary="
        guard let boundaryRange = contentType.range(of: boundaryPrefix),
              let boundary = contentType[boundaryRange.upperBound...].components(separatedBy: ";").first else {
            print("❌ Invalid boundary in Content-Type: \(contentType)")
            sendHTTPResponse(statusCode: 400, body: "Invalid boundary")
            return
        }
        
        print("📋 Using boundary: \(boundary)")
        
        // Convert boundary to data for binary parsing
        let boundaryData = "--\(boundary)".data(using: .utf8)!
        
        var fileName = "uploaded_file"
        var targetPath = ""
        var fileData = Data()
        
        // Parse multipart data by splitting on boundary
        let parts = splitData(bodyData, separator: boundaryData)
        print("📋 Found \(parts.count) parts in multipart data")
        
        for (index, part) in parts.enumerated() {
            if part.isEmpty { 
                print("📋 Part \(index): Empty, skipping")
                continue 
            }
            
            print("📋 Processing part \(index) with size: \(part.count) bytes")
            
            // Find the end of headers (double CRLF)
            let headerSeparator = "\r\n\r\n".data(using: .utf8)!
            guard let headerEndRange = part.range(of: headerSeparator) else {
                print("📋 Part \(index): No header separator found, skipping")
                continue
            }
            
            // Extract headers portion and convert to string
            let headerData = part[..<headerEndRange.lowerBound]
            guard let headerString = String(data: headerData, encoding: .utf8) else {
                print("📋 Part \(index): Could not decode headers as UTF-8, skipping")
                continue
            }
            
            let headerLines = headerString.components(separatedBy: "\r\n")
            print("📋 Part \(index) headers: \(headerLines)")
            
            // Parse headers to determine content type
            var isFile = false
            var isPath = false
            
            for line in headerLines {
                if line.contains("Content-Disposition: form-data") {
                    if line.contains("filename=") {
                        isFile = true
                        // Extract filename
                        if let filenameRange = line.range(of: "filename=\"") {
                            let remaining = line[filenameRange.upperBound...]
                            if let endQuote = remaining.firstIndex(of: "\"") {
                                fileName = String(remaining[..<endQuote])
                            }
                        }
                        print("📋 Part \(index): File field with filename: \(fileName)")
                    } else if line.contains("name=\"path\"") {
                        isPath = true
                        print("📋 Part \(index): Path field")
                    }
                }
            }
            
            // Extract content data (after the double CRLF)
            let contentData = part[headerEndRange.upperBound...]
            
            if isFile {
                // Remove trailing CRLF if present
                fileData = Data(contentData)
                if fileData.suffix(2) == Data([0x0D, 0x0A]) {
                    fileData = fileData.dropLast(2)
                }
                print("📋 Extracted file data: \(fileData.count) bytes")
            } else if isPath {
                // Extract path value
                if let pathString = String(data: contentData, encoding: .utf8) {
                    targetPath = pathString.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("📋 Extracted target path: '\(targetPath)'")
                }
            }
        }
        
        if fileData.isEmpty {
            print("❌ No file data found in upload")
            sendHTTPResponse(statusCode: 400, body: "No file data received")
            return
        }
        
        // Build the target URL for the file
        var targetURL = documentsPath
        if !targetPath.isEmpty {
            // Remove leading slash if present
            let cleanPath = targetPath.hasPrefix("/") ? String(targetPath.dropFirst()) : targetPath
            if !cleanPath.isEmpty {
                targetURL = targetURL.appendingPathComponent(cleanPath)
            }
        }
        
        print("📋 Target URL: \(targetURL.path)")
        
        // Ensure the target directory exists
        do {
            try FileManager.default.createDirectory(at: targetURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("⚠️ Warning: Could not create directory \(targetURL.path): \(error)")
        }
        
        // Save uploaded file
        let fileURL = targetURL.appendingPathComponent(fileName)
        print("💾 Attempting to save file: \(fileName) (\(fileData.count) bytes) to \(fileURL.path)")
        
        do {
            try fileData.write(to: fileURL)
            print("✅ File saved successfully: \(fileURL.path)")
            sendHTTPResponse(statusCode: 200, body: "File uploaded successfully", contentType: "application/json")
        } catch {
            print("❌ Failed to save file: \(error.localizedDescription)")
            sendHTTPResponse(statusCode: 500, body: "Failed to save file: \(error.localizedDescription)")
        }
    }
    
    /**
     Helper method to split binary data on a separator.
     
     - Parameters:
        - data: The data to split
        - separator: The separator data
     - Returns: Array of data chunks
     */
    private func splitData(_ data: Data, separator: Data) -> [Data] {
        var parts: [Data] = []
        var searchRange = data.startIndex..<data.endIndex
        
        while let range = data.range(of: separator, in: searchRange) {
            if range.lowerBound > searchRange.lowerBound {
                parts.append(data[searchRange.lowerBound..<range.lowerBound])
            }
            searchRange = range.upperBound..<data.endIndex
        }
        
        if searchRange.lowerBound < data.endIndex {
            parts.append(data[searchRange])
        }
        
        return parts
    }
    
    /**
     Handles directory creation requests.
     
     Creates a new directory at the specified path within the documents directory.
     Now supports creating directories in subdirectories based on current path.
     
     - Parameter body: The JSON request body containing the directory name and optional path
     */
    private func handleCreateDirectory(body: String) {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dirName = json["name"] as? String else {
            sendHTTPResponse(statusCode: 400, body: "Invalid request")
            return
        }
        
        // Get the target path from the request (optional)
        let targetPath = json["path"] as? String ?? ""
        
        // Build the target URL for the directory
        var targetURL = documentsPath
        if !targetPath.isEmpty {
            // Remove leading slash if present
            let cleanPath = targetPath.hasPrefix("/") ? String(targetPath.dropFirst()) : targetPath
            if !cleanPath.isEmpty {
                targetURL = targetURL.appendingPathComponent(cleanPath)
            }
        }
        
        let dirURL = targetURL.appendingPathComponent(dirName)
        
        do {
            try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
            sendHTTPResponse(statusCode: 200, body: "Directory created successfully", contentType: "application/json")
        } catch {
            sendHTTPResponse(statusCode: 500, body: "Failed to create directory: \(error.localizedDescription)")
        }
    }
    
    /**
     Handles file and directory deletion requests.
     
     Deletes the specified file or directory from the server.
     
     - Parameter filePath: The path of the file or directory to delete
     */
    private func handleFileDelete(filePath: String) {
        let decodedPath = filePath.removingPercentEncoding ?? filePath
        let fullPath = documentsPath.appendingPathComponent(decodedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        
        do {
            try FileManager.default.removeItem(at: fullPath)
            sendHTTPResponse(statusCode: 200, body: "File deleted successfully")
        } catch {
            sendHTTPResponse(statusCode: 500, body: "Failed to delete file")
        }
    }
    
    // MARK: - HTTP Response Utilities
    
    /**
     Sends an HTTP response to the client.
     
     - Parameters:
        - statusCode: The HTTP status code
        - body: The response body content as string
        - contentType: The MIME type of the response body
        - fileName: The file name for download attachments (optional)
     */
    private func sendHTTPResponse(statusCode: Int, body: String, contentType: String = "text/plain", fileName: String? = nil) {
        sendHTTPResponse(statusCode: statusCode, body: body.data(using: .utf8) ?? Data(), contentType: contentType, fileName: fileName)
    }
    
    /**
     Sends an HTTP response to the client.
     
     Constructs a complete HTTP response with headers and body, then sends it over the connection.
     
     - Parameters:
        - statusCode: The HTTP status code
        - body: The response body data
        - contentType: The MIME type of the response body
        - fileName: The file name for download attachments (optional)
     */
    private func sendHTTPResponse(statusCode: Int, body: Data, contentType: String = "text/plain", fileName: String? = nil) {
        var response = "HTTP/1.1 \(statusCode) \(httpStatusText(statusCode))\r\n"
        response += "Content-Type: \(contentType)\r\n"
        response += "Content-Length: \(body.count)\r\n"
        response += "Access-Control-Allow-Origin: *\r\n"
        response += "Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS\r\n"
        response += "Access-Control-Allow-Headers: Content-Type\r\n"
        
        // Keep connection alive for regular requests, close for file downloads
        if fileName != nil {
            response += "Connection: close\r\n"
        } else {
            response += "Connection: keep-alive\r\n"
        }
        
        if let fileName = fileName {
            response += "Content-Disposition: attachment; filename=\"\(fileName)\"\r\n"
        }
        
        response += "\r\n"
        
        let responseData = response.data(using: .utf8)! + body
        
        connection.send(content: responseData, completion: .contentProcessed { _ in
            // Only close connection for file downloads or errors
            if fileName != nil || statusCode >= 400 {
                self.close()
            }
            // For other requests, keep connection alive
        })
    }
    
    /**
     Returns the HTTP status text for a given status code.
     
     - Parameter code: The HTTP status code
     - Returns: The corresponding status text string
     */
    private func httpStatusText(_ code: Int) -> String {
        switch code {
        case 200: return "OK"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 405: return "Method Not Allowed"
        case 500: return "Internal Server Error"
        default: return "Unknown"
        }
    }
}
