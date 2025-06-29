import Foundation
import Network

/**
 Handles individual FTP client connections and command processing.
 
 This class manages a single FTP client connection, processing FTP commands
 and handling file transfers. It implements core FTP protocol functionality
 including authentication, directory navigation, file listing, and file transfers.
 
 ## Supported FTP Commands
 - USER/PASS: Authentication
 - PWD: Print working directory
 - CWD: Change working directory
 - LIST/NLST: Directory listing
 - RETR: Download files
 - STOR: Upload files
 - PASV: Passive mode data connection
 - TYPE: Set transfer type
 - SYST: System information
 - QUIT: Disconnect
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 29/06/25
 */
class FTPConnection {
    
    // MARK: - Properties
    
    /// The network connection to the FTP client
    private let connection: NWConnection
    
    /// The root documents directory path
    private let documentsPath: URL
    
    /// Current working directory path
    private var currentDirectory: String = "/"
    
    /// Whether the client is authenticated
    private var isLoggedIn = false
    
    /// Data connection for file transfers
    private var dataConnection: NWConnection?
    
    /// Port number for data connection
    private var dataPort: UInt16 = 0
    
    // MARK: - Initialization
    
    /**
     Initializes a new FTP connection handler.
     
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
     Starts the FTP connection and begins listening for commands.
     
     Sends the initial welcome message and starts the command processing loop.
     */
    func start() {
        connection.start(queue: .global())
        sendResponse("220 iOS FTP Server Ready")
        receiveData()
    }
    
    /**
     Closes the FTP connection and cleans up resources.
     
     Cancels both control and data connections.
     */
    func close() {
        connection.cancel()
        dataConnection?.cancel()
    }
    
    // MARK: - Command Processing
    
    /**
     Continuously receives data from the client.
     
     This method sets up a receive loop to handle incoming FTP commands.
     */
    private func receiveData() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                let command = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                self?.handleCommand(command)
            }
            
            if !isComplete {
                self?.receiveData()
            }
        }
    }
    
    /**
     Processes FTP commands from the client.
     
     Parses the command and delegates to appropriate handler methods.
     
     - Parameter command: The FTP command string from the client
     */
    private func handleCommand(_ command: String) {
        let components = command.components(separatedBy: " ")
        let cmd = components[0].uppercased()
        
        switch cmd {
        case "USER":
            sendResponse("331 Username OK, need password")
        case "PASS":
            isLoggedIn = true
            sendResponse("230 User logged in")
        case "PWD":
            sendResponse("257 \"\(currentDirectory)\" is current directory")
        case "CWD":
            if components.count > 1 {
                changeDirectory(components[1])
            } else {
                sendResponse("550 Failed to change directory")
            }
        case "LIST", "NLST":
            listFiles()
        case "RETR":
            if components.count > 1 {
                downloadFile(components[1])
            } else {
                sendResponse("550 File not specified")
            }
        case "STOR":
            if components.count > 1 {
                uploadFile(components[1])
            } else {
                sendResponse("550 File not specified")
            }
        case "TYPE":
            sendResponse("200 Type set to I")
        case "PASV":
            enterPassiveMode()
        case "QUIT":
            sendResponse("221 Goodbye")
            close()
        case "SYST":
            sendResponse("215 UNIX Type: L8")
        default:
            sendResponse("502 Command not implemented")
        }
    }
    
    // MARK: - Response Handling
    
    /**
     Sends an FTP response to the client.
     
     - Parameter response: The response string to send
     */
    private func sendResponse(_ response: String) {
        let data = (response + "\r\n").data(using: .utf8)!
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Send error: \(error)")
            }
        })
    }
    
    // MARK: - Directory Operations
    
    /**
     Changes the current working directory.
     
     - Parameter path: The target directory path
     */
    private func changeDirectory(_ path: String) {
        if path == ".." {
            if currentDirectory != "/" {
                currentDirectory = (currentDirectory as NSString).deletingLastPathComponent
                if currentDirectory.isEmpty {
                    currentDirectory = "/"
                }
            }
            sendResponse("250 Directory changed")
        } else if path.hasPrefix("/") {
            let fullPath = documentsPath.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
            if FileManager.default.fileExists(atPath: fullPath.path) {
                currentDirectory = path
                sendResponse("250 Directory changed")
            } else {
                sendResponse("550 Directory not found")
            }
        } else {
            let newPath = currentDirectory == "/" ? "/\(path)" : "\(currentDirectory)/\(path)"
            let fullPath = documentsPath.appendingPathComponent(newPath.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
            if FileManager.default.fileExists(atPath: fullPath.path) {
                currentDirectory = newPath
                sendResponse("250 Directory changed")
            } else {
                sendResponse("550 Directory not found")
            }
        }
    }
    
    /**
     Lists files in the current directory.
     
     Sends directory listing over the data connection in LIST format.
     */
    private func listFiles() {
        let directoryPath = documentsPath.appendingPathComponent(currentDirectory.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: directoryPath, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey], options: [])
            
            var listing = ""
            for url in contents {
                let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                let isDirectory = resourceValues.isDirectory ?? false
                let fileSize = resourceValues.fileSize ?? 0
                let modificationDate = resourceValues.contentModificationDate ?? Date()
                
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM dd HH:mm"
                let dateString = formatter.string(from: modificationDate)
                
                let permissions = isDirectory ? "drwxr-xr-x" : "-rw-r--r--"
                listing += "\(permissions) 1 user user \(fileSize) \(dateString) \(url.lastPathComponent)\r\n"
            }
            
            sendResponse("150 Opening data connection for directory listing")
            
            if let dataConn = dataConnection {
                let data = listing.data(using: .utf8) ?? Data()
                dataConn.send(content: data, completion: .contentProcessed { _ in
                    dataConn.cancel()
                })
            }
            
            sendResponse("226 Directory listing completed")
        } catch {
            sendResponse("550 Failed to list directory")
        }
    }
    
    // MARK: - File Transfer Operations
    
    /**
     Downloads a file to the client.
     
     - Parameter filename: The name of the file to download
     */
    private func downloadFile(_ filename: String) {
        let filePath = documentsPath.appendingPathComponent(currentDirectory.trimmingCharacters(in: CharacterSet(charactersIn: "/"))).appendingPathComponent(filename)
        
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            sendResponse("550 File not found")
            return
        }
        
        do {
            let fileData = try Data(contentsOf: filePath)
            sendResponse("150 Opening data connection for file transfer")
            
            if let dataConn = dataConnection {
                dataConn.send(content: fileData, completion: .contentProcessed { _ in
                    dataConn.cancel()
                })
            }
            
            sendResponse("226 File transfer completed")
        } catch {
            sendResponse("550 Failed to read file")
        }
    }
    
    /**
     Uploads a file from the client.
     
     - Parameter filename: The name of the file to upload
     */
    private func uploadFile(_ filename: String) {
        let filePath = documentsPath.appendingPathComponent(currentDirectory.trimmingCharacters(in: CharacterSet(charactersIn: "/"))).appendingPathComponent(filename)
        
        sendResponse("150 Ready for data transfer")
        
        guard let dataConn = dataConnection else {
            sendResponse("425 No data connection")
            return
        }
        
        var receivedData = Data()
        
        func receiveFileData() {
            dataConn.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, isComplete, error in
                if let data = data {
                    receivedData.append(data)
                }
                
                if isComplete || error != nil {
                    do {
                        try receivedData.write(to: filePath)
                        self.sendResponse("226 File transfer completed")
                    } catch {
                        self.sendResponse("550 Failed to write file")
                    }
                    dataConn.cancel()
                } else {
                    receiveFileData()
                }
            }
        }
        
        receiveFileData()
    }
    
    // MARK: - Data Connection Management
    
    /**
     Enters passive mode for data connections.
     
     Creates a data listener and responds with connection information.
     */
    private func enterPassiveMode() {
        do {
            let dataListener = try NWListener(using: .tcp, on: .any)
            dataPort = dataListener.port?.rawValue ?? 0
            
            dataListener.newConnectionHandler = { [weak self] connection in
                self?.dataConnection = connection
                connection.start(queue: .global())
                dataListener.cancel()
            }
            
            dataListener.start(queue: .global())
            
            // Get local IP address for passive mode response
            if let localIP = getLocalIPAddress() {
                let ipComponents = localIP.components(separatedBy: ".")
                let p1 = dataPort / 256
                let p2 = dataPort % 256
                
                sendResponse("227 Entering Passive Mode (\(ipComponents.joined(separator: ",")),\(p1),\(p2))")
            } else {
                sendResponse("425 Can't enter passive mode")
            }
        } catch {
            sendResponse("425 Can't enter passive mode")
        }
    }
    
    // MARK: - Network Utilities
    
    /**
     Gets the local IP address for the Wi-Fi interface.
     
     - Returns: The local IP address string, or nil if not found
     */
    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: (interface?.ifa_name)!)
                    if name == "en0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!),
                                   &hostname, socklen_t(hostname.count),
                                   nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
}
