import Foundation
import Network

/**
 A lightweight FTP server implementation for iOS.
 
 This class provides a complete FTP server that can serve files from the device's
 documents directory. It supports both FTP protocol for file transfers and HTTP
 protocol for web-based file browsing.
 
 ## Features
 - FTP protocol support for file transfers
 - HTTP web interface for browser-based access
 - Multiple concurrent connections
 - Network interface detection
 - Automatic port configuration
 
 ## Usage
 ```swift
 let server = FTPServer(port: 2121, webPort: 8080)
 try server.start()
 // Server is now running
 server.stop()
 ```
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 29/06/25
 */
class FTPServer {
    
    // MARK: - Properties
    
    /// The FTP listener for incoming connections
    private var listener: NWListener?
    
    /// The HTTP web listener for incoming web connections
    private var webListener: NWListener?
    
    /// Array of active FTP connections
    private var connections: [FTPConnection] = []
    
    /// Array of active web connections
    private var webConnections: [WebConnection] = []
    
    /// The port number for FTP service
    private let port: UInt16
    
    /// The port number for web service
    private let webPort: UInt16
    
    /// The root directory path for file serving
    private let documentsPath: URL
    
    // MARK: - Initialization
    
    /**
     Initializes a new FTP server instance.
     
     - Parameters:
        - port: The port number for FTP service
        - webPort: The port number for web service (defaults to 8080)
     */
    init(port: UInt16, webPort: UInt16 = 8080) {
        self.port = port
        self.webPort = webPort
        self.documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    // MARK: - Server Control
    
    /**
     Starts both FTP and HTTP servers.
     
     This method creates and configures network listeners for both FTP and HTTP protocols,
     then starts accepting incoming connections on the specified ports.
     
     - Throws: Network errors if the servers cannot be started
     */
    func start() throws {
        // Configure and start FTP server
        let ftpParameters = NWParameters.tcp
        ftpParameters.allowLocalEndpointReuse = true
        
        listener = try NWListener(using: ftpParameters, on: NWEndpoint.Port(rawValue: port)!)
        
        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }
        
        listener?.start(queue: .global())
        
        // Configure and start HTTP web server
        let webParameters = NWParameters.tcp
        webParameters.allowLocalEndpointReuse = true
        
        webListener = try NWListener(using: webParameters, on: NWEndpoint.Port(rawValue: webPort)!)
        
        webListener?.newConnectionHandler = { [weak self] connection in
            self?.handleNewWebConnection(connection)
        }
        
        webListener?.start(queue: .global())
    }
    
    /**
     Stops both FTP and HTTP servers.
     
     This method cancels all listeners, closes active connections, and cleans up resources.
     */
    func stop() {
        listener?.cancel()
        webListener?.cancel()
        connections.forEach { $0.close() }
        webConnections.forEach { $0.close() }
        connections.removeAll()
        webConnections.removeAll()
    }
    
    // MARK: - Connection Handling
    
    /**
     Handles new FTP connections.
     
     Creates a new FTPConnection instance for each incoming connection and starts
     processing FTP commands.
     
     - Parameter connection: The new network connection
     */
    private func handleNewConnection(_ connection: NWConnection) {
        let ftpConnection = FTPConnection(connection: connection, documentsPath: documentsPath)
        connections.append(ftpConnection)
        ftpConnection.start()
    }
    
    /**
     Handles new HTTP web connections.
     
     Creates a new WebConnection instance for each incoming web connection and starts
     processing HTTP requests.
     
     - Parameter connection: The new network connection
     */
    private func handleNewWebConnection(_ connection: NWConnection) {
        let webConnection = WebConnection(connection: connection, documentsPath: documentsPath)
        webConnections.append(webConnection)
        webConnection.start()
    }
    
    // MARK: - URL Generation
    
    /**
     Gets the FTP server URL for client connections.
     
     - Returns: The complete FTP URL string, or nil if no network interface is available
     */
    func getServerURL() -> String? {
        guard let interface = getLocalIPAddress() else { return nil }
        return "ftp://\(interface):\(port)"
    }
    
    /**
     Gets the HTTP web server URL for browser access.
     
     - Returns: The complete HTTP URL string, or nil if no network interface is available
     */
    func getWebURL() -> String? {
        guard let interface = getLocalIPAddress() else { return nil }
        return "http://\(interface):\(webPort)"
    }
    
    // MARK: - Network Interface Detection
    
    /**
     Detects the local IP address for network interface.
     
     This method searches for the Wi-Fi interface (en0) and returns its IPv4 address.
     
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
                    if name == "en0" || name == "Wi-Fi" {
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
