# Coffret - iOS FTP Server

A comprehensive iOS FTP server application with both FTP and Web interface capabilities.

## Project Structure

The project has been reorganized into a modular structure for better maintainability and ease of development:

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
├── SceneDelegate.swift             # Scene delegate
└── ViewController.swift            # Legacy file (to be removed)
```

## Architecture Overview

### Server Components

#### FTPServer (`Server/FTP/FTPServer.swift`)
- Main FTP server class that manages both FTP and Web listeners
- Handles incoming connections and delegates to appropriate connection handlers
- Manages server lifecycle (start/stop)
- Provides server URL information

#### FTPConnection (`Server/FTP/FTPConnection.swift`)
- Handles individual FTP client connections
- Implements FTP protocol commands (USER, PASS, LIST, RETR, STOR, etc.)
- Manages passive mode data connections
- Handles file operations through FTP protocol

#### WebConnection (`Server/Web/WebConnection.swift`)
- Handles HTTP requests for the web interface
- Provides REST API endpoints for file operations
- Serves the web interface HTML
- Handles file uploads, downloads, and directory operations

#### WebInterfaceGenerator (`Server/Web/WebInterfaceGenerator.swift`)
- Generates the complete HTML web interface
- Includes CSS styling and JavaScript functionality
- Provides a modern, responsive file manager interface

### UI Components

#### ViewController (`UI/Controllers/ViewController.swift`)
- Main view controller managing the app's primary interface
- Handles server control (start/stop)
- Manages file tree display
- Coordinates between UI and server components

#### Extensions
- **FileOperations**: File management operations (copy, rename, delete, share)
- **ServerActions**: Server control actions and settings
- **UIDocumentPickerDelegate**: File import functionality
- **UITableView**: Table view data source and delegate methods

#### FileTreeTableViewCell (`UI/Views/FileTreeTableViewCell.swift`)
- Custom table view cell for displaying file tree items
- Handles indentation, icons, and file size formatting
- Supports expandable directory structure

### Models

#### FileTreeNode (`Models/FileTreeNode.swift`)
- Represents a file or directory in the file tree
- Manages hierarchical file structure
- Handles expansion/collapse state
- Provides file system operations

## Features

### FTP Server
- Standard FTP protocol support
- Passive mode data connections
- File upload/download
- Directory listing and navigation
- Authentication support

### Web Interface
- Modern, responsive design
- File upload/download
- Directory creation and navigation
- File deletion
- Real-time file management
- Beautiful gradient UI with modern styling

### Mobile Interface
- Native iOS file management
- File import from Files app
- Context menus for file operations
- Hierarchical file tree view
- Sample file creation

## Usage

1. **Start the Server**: Configure FTP and Web ports, then tap "Start Server"
2. **Access via FTP**: Use any FTP client with the displayed FTP URL
3. **Access via Web**: Open the displayed Web URL in any browser
4. **Manage Files**: Use the mobile interface to manage files locally

## Development

### Adding New Features

1. **Server Features**: Add to appropriate server classes in `Server/` directory
2. **UI Features**: Add to `UI/Controllers/` or create new extensions in `UI/Extensions/`
3. **Models**: Add new data models to `Models/` directory
4. **Views**: Add custom views to `UI/Views/` directory

### Code Organization

- Keep related functionality together in focused classes
- Use extensions to separate concerns within view controllers
- Maintain clear separation between server logic and UI logic
- Document public interfaces and complex algorithms

## Dependencies

- iOS 14.0+
- Network framework for server implementation
- UniformTypeIdentifiers for file type handling
- UIKit for user interface

## Recent Updates

### Documentation Improvements
- Added comprehensive Swift documentation with proper markup
- Implemented class-level documentation with features and usage examples
- Added method-level documentation with parameter descriptions
- Organized code with MARK comments for better navigation

### Bug Fixes (Latest)
- Fixed URLResourceKey issues by using `.contentModificationDateKey` instead of `.modificationDateKey`
- Resolved duplicate method conflicts between main ViewController and extensions
- Fixed missing `rebuildFlattenedNodes` method by using correct `updateFlattenedNodes`
- Consolidated file operation methods to prevent ambiguous references

### Code Quality Improvements
- Separated concerns using extensions for better organization
- Removed duplicate code and method conflicts
- Improved error handling and user feedback
- Enhanced documentation for all Swift files


