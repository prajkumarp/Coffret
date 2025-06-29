# 📁 Coffret - iOS FTP Server

A powerful iOS app that turns your iPhone/iPad into a fully functional FTP server with a beautiful web interface for file management. Built with a clean, modular architecture for maintainability and extensibility.

## ✨ Features

- 🚀 **Full FTP Server** - Complete FTP protocol implementation
- 🌐 **Web Interface** - Beautiful, responsive web UI for file management
- 📱 **Native iOS UI** - Intuitive native interface for local file operations
- 📤 **File Upload/Download** - Seamless file transfer capabilities
- 📁 **Folder Management** - Create, delete, and organize folders
- 🔄 **File Operations** - Copy, rename, delete, and share files
- 📊 **Real-time Status** - Live server status and connection info
- 🔒 **Secure** - Local network only, no external dependencies

## 🚀 Quick Start

1. **Launch the app** on your iOS device
2. **Configure ports** (default: FTP 2121, Web 8080)
3. **Tap "Start Server"** to begin
4. **Connect from any device** on the same network

## 📡 How to Connect

### FTP Connection
- **Server**: Your iPhone's IP address (shown in app)
- **Port**: 2121 (or your custom port)
- **Username**: Any username
- **Password**: Any password
- **Mode**: Passive (PASV)

### Web Interface
- Open your browser and navigate to the Web URL shown in the app
- Example: `http://192.168.1.100:8080`

## 💻 Supported FTP Clients

- **iOS**: FTP Client Pro, FileExplorer
- **Android**: AndFTP, Solid Explorer
- **macOS**: Finder (Go → Connect to Server)
- **Windows**: FileZilla, WinSCP, Windows Explorer
- **Linux**: FileZilla, Nautilus, command line FTP

## 🏗 Project Architecture

The project has been designed with a clean, modular architecture for better maintainability and development:

```
Coffret/
├── Server/                          # Server-related components
│   ├── FTP/                        # FTP server implementation
│   │   ├── FTPServer.swift         # Main FTP server class
│   │   └── FTPConnection.swift     # FTP connection handler
│   └── Web/                        # Web server implementation
│       ├── WebConnection.swift     # Web server connection handler
│       └── WebInterfaceGenerator.swift # HTML interface generator
├── UI/                             # User Interface components
│   ├── Controllers/                # View Controllers
│   │   └── ViewController.swift    # Main view controller
│   ├── Views/                      # Custom Views and Cells
│   │   └── FileTreeTableViewCell.swift # File tree table view cell
│   └── Extensions/                 # View Controller Extensions
│       ├── ViewController+FileOperations.swift
│       ├── ViewController+ServerActions.swift
│       ├── ViewController+UIDocumentPickerDelegate.swift
│       └── ViewController+UITableView.swift
├── Models/                         # Data Models
│   └── FileTreeNode.swift         # File tree node model
├── AppDelegate.swift              # App delegate
└── SceneDelegate.swift             # Scene delegate
```

### Core Components

#### 🖥 Server Components
- **FTPServer**: Main server class managing both FTP and Web listeners
- **FTPConnection**: Handles individual FTP client connections and protocol commands
- **WebConnection**: HTTP server for REST API and web interface
- **WebInterfaceGenerator**: Modern, responsive HTML interface generator

#### 📱 UI Components
- **ViewController**: Main interface with programmatic UI and scrollable layout
- **Extensions**: Organized functionality (File Operations, Server Actions, Delegates)
- **FileTreeTableViewCell**: Custom cell for hierarchical file display

#### 📊 Models
- **FileTreeNode**: Hierarchical file system representation with expansion/collapse

## 🔧 Configuration

### Ports
- **FTP Port**: Default 2121 (can be changed)
- **Web Port**: Default 8080 (can be changed)
- Avoid ports below 1024 (requires root access)

### Network Requirements
- All devices must be on the same WiFi network
- Router should allow local network communication
- Firewall should not block the configured ports

## 📱 App Interface

### Main Screen
- **Port Configuration**: Set FTP and Web server ports
- **Server Control**: Start/stop server with one tap
- **Status Display**: Real-time server status and URLs
- **File Browser**: Navigate and manage local files

### File Operations
- **Long Press**: Context menu with file operations
- **Tap Folders**: Expand/collapse directory tree
- **Import**: Add files from other apps
- **Create**: New folders and sample files

## 🌐 Web Interface Features

- **File Browser**: Navigate through directories
- **Upload**: Drag & drop or click to upload files
- **Download**: Direct download links for all files
- **Create Folders**: New directory creation
- **Delete Files**: Remove files and folders
- **Responsive Design**: Works on all screen sizes

## 🔒 Security Notes

- Server only accepts connections from local network
- No authentication required (suitable for private networks)
- Files are served from app's Documents directory
- Server automatically stops when app goes to background

## 🛠 Technical Details

### Supported FTP Commands
- `USER`, `PASS` - Authentication
- `PWD`, `CWD` - Directory navigation
- `LIST`, `NLST` - Directory listing
- `RETR`, `STOR` - File transfer
- `PASV` - Passive mode
- `TYPE`, `SYST`, `QUIT` - Protocol commands

### File Types
- All file types supported
- Automatic MIME type detection
- Binary transfer mode
- Preserves file attributes

## 📋 Requirements

- iOS 14.0 or later
- Network framework support
- Local network access permission

## 🐛 Troubleshooting

### Can't Connect to Server
1. Ensure all devices are on same WiFi
2. Check if ports are not blocked by firewall
3. Verify server is running (check status in app)
4. Try different port numbers if needed

### Slow File Transfer
1. Move closer to WiFi router
2. Close other network-intensive apps
3. Use 5GHz WiFi if available

### Web Interface Not Loading
1. Check web URL is correct
2. Try accessing from different browser
3. Ensure web port is not in use by other apps

## 🔄 Updates & Support

This app provides a complete FTP server solution for iOS devices. For issues or feature requests, the code is well-documented and can be extended as needed.

## 📄 License

Built with love for the iOS development community. Feel free to use, modify, and distribute as needed.

---

**Happy file sharing! 📁✨**
