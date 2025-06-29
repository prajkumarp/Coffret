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
    
    /**
     Continuously receives HTTP requests from the client.
     
     Sets up a receive loop to handle incoming HTTP requests.
     */
    private func receiveRequest() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.handleHTTPRequest(data)
            }
            
            if !isComplete && error == nil {
                self?.receiveRequest()
            } else {
                self?.close()
            }
        }
    }
    
    /**
     Processes HTTP requests from the client.
     
     Parses the HTTP request and routes it to the appropriate handler.
     
     - Parameter data: The raw HTTP request data
     */
    private func handleHTTPRequest(_ data: Data) {
        guard let request = String(data: data, encoding: .utf8) else {
            sendHTTPResponse(statusCode: 400, body: "Bad Request")
            return
        }
        
        let lines = request.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            sendHTTPResponse(statusCode: 400, body: "Bad Request")
            return
        }
        
        let components = requestLine.components(separatedBy: " ")
        guard components.count >= 2 else {
            sendHTTPResponse(statusCode: 400, body: "Bad Request")
            return
        }
        
        let method = components[0]
        let path = components[1]
        
        // Parse HTTP headers
        var headers: [String: String] = [:]
        var bodyStartIndex = 0
        
        for (index, line) in lines.enumerated() {
            if line.isEmpty {
                bodyStartIndex = index + 1
                break
            }
            if line.contains(":") {
                let headerComponents = line.components(separatedBy: ": ")
                if headerComponents.count >= 2 {
                    headers[headerComponents[0]] = headerComponents[1]
                }
            }
        }
        
        // Extract request body if present
        let bodyLines = Array(lines[bodyStartIndex...])
        let body = bodyLines.joined(separator: "\r\n")
        
        // Route request to appropriate handler
        switch method {
        case "GET":
            handleGETRequest(path: path)
        case "POST":
            handlePOSTRequest(path: path, body: body, headers: headers)
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
     
     - Parameters:
        - path: The requested URL path
        - body: The request body content
        - headers: The HTTP headers
     */
    private func handlePOSTRequest(path: String, body: String, headers: [String: String]) {
        if path == "/api/upload" {
            handleFileUpload(body: body, headers: headers)
        } else if path == "/api/mkdir" {
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
        let decodedPath = path.removingPercentEncoding ?? path
        let fullPath = documentsPath.appendingPathComponent(decodedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: fullPath, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
            
            var fileInfos: [[String: Any]] = []
            
            for file in files {
                let resourceValues = try file.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                let isDirectory = resourceValues.isDirectory ?? false
                let fileSize = resourceValues.fileSize ?? 0
                let modDate = resourceValues.contentModificationDate ?? Date()
                
                let relativePath = String(file.path.dropFirst(documentsPath.path.count))
                
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
            
            sendHTTPResponse(statusCode: 200, body: jsonString, contentType: "application/json")
        } catch {
            sendHTTPResponse(statusCode: 500, body: "Internal Server Error")
        }
    }
    
    /**
     Sends a file for download.
     
     - Parameter filePath: The path of the file to download
     */
    private func sendFileDownload(filePath: String) {
        let decodedPath = filePath.removingPercentEncoding ?? filePath
        let fullPath = documentsPath.appendingPathComponent(decodedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        
        guard FileManager.default.fileExists(atPath: fullPath.path) else {
            sendHTTPResponse(statusCode: 404, body: "File Not Found")
            return
        }
        
        do {
            let fileData = try Data(contentsOf: fullPath)
            let fileName = fullPath.lastPathComponent
            sendHTTPResponse(statusCode: 200, body: fileData, contentType: "application/octet-stream", fileName: fileName)
        } catch {
            sendHTTPResponse(statusCode: 500, body: "Internal Server Error")
        }
    }
    
    // MARK: - File Operations
    
    /**
     Handles file upload from the client.
     
     Parses the multipart form data and saves the uploaded file to the server.
     This implementation provides basic multipart form data parsing for file uploads.
     
     - Parameters:
        - body: The request body containing the file data
        - headers: The HTTP headers including Content-Type
     */
    private func handleFileUpload(body: String, headers: [String: String]) {
        // Validate Content-Type for multipart form data
        guard let contentType = headers["Content-Type"],
              contentType.contains("multipart/form-data") else {
            sendHTTPResponse(statusCode: 400, body: "Invalid Content-Type")
            return
        }
        
        // Extract boundary from Content-Type header
        let boundaryPrefix = "boundary="
        guard let boundaryRange = contentType.range(of: boundaryPrefix),
              let boundary = contentType[boundaryRange.upperBound...].components(separatedBy: ";").first else {
            sendHTTPResponse(statusCode: 400, body: "Invalid boundary")
            return
        }
        
        // Parse multipart data (simplified implementation)
        let parts = body.components(separatedBy: "--\(boundary)")
        
        for part in parts {
            if part.contains("Content-Disposition: form-data") && part.contains("filename=") {
                let lines = part.components(separatedBy: "\r\n")
                
                // Extract filename from Content-Disposition header
                var fileName = "uploaded_file"
                for line in lines {
                    if line.contains("filename=") {
                        let components = line.components(separatedBy: "filename=\"")
                        if components.count > 1 {
                            fileName = components[1].components(separatedBy: "\"")[0]
                        }
                        break
                    }
                }
                
                // Extract file content (starts after empty line)
                var contentStarted = false
                var fileContent = ""
                for line in lines {
                    if contentStarted {
                        fileContent += line + "\r\n"
                    } else if line.isEmpty {
                        contentStarted = true
                    }
                }
                
                // Clean up content
                fileContent = fileContent.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Save uploaded file
                let fileURL = documentsPath.appendingPathComponent(fileName)
                do {
                    try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
                    sendHTTPResponse(statusCode: 200, body: "File uploaded successfully", contentType: "application/json")
                } catch {
                    sendHTTPResponse(statusCode: 500, body: "Failed to save file")
                }
                return
            }
        }
        
        sendHTTPResponse(statusCode: 400, body: "No file found in request")
    }
    
    /**
     Handles directory creation requests.
     
     Creates a new directory at the specified path within the documents directory.
     
     - Parameter body: The JSON request body containing the directory name
     */
    private func handleCreateDirectory(body: String) {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dirName = json["name"] as? String else {
            sendHTTPResponse(statusCode: 400, body: "Invalid request")
            return
        }
        
        let dirURL = documentsPath.appendingPathComponent(dirName)
        
        do {
            try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: false, attributes: nil)
            sendHTTPResponse(statusCode: 200, body: "Directory created successfully")
        } catch {
            sendHTTPResponse(statusCode: 500, body: "Failed to create directory")
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
        
        if let fileName = fileName {
            response += "Content-Disposition: attachment; filename=\"\(fileName)\"\r\n"
        }
        
        response += "\r\n"
        
        let responseData = response.data(using: .utf8)! + body
        
        connection.send(content: responseData, completion: .contentProcessed { _ in
            self.close()
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
