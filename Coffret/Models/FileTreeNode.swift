import Foundation

/**
 A hierarchical file tree node representing files and directories in the FTP server.
 
 This class provides a tree structure for managing files and directories, supporting
 hierarchical navigation with expansion/collapse functionality. Each node maintains
 references to its parent and children, enabling efficient tree traversal.
 
 ## Features
 - Hierarchical file/directory representation
 - Lazy loading of directory contents
 - Expansion/collapse state management
 - Automatic sorting (directories first, then alphabetical)
 - Level-based indentation support
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 29/06/25
 */
class FileTreeNode {
    
    // MARK: - Properties
    
    /// The URL of the file or directory
    let url: URL
    
    /// The display name of the file or directory
    let name: String
    
    /// Whether this node represents a directory
    let isDirectory: Bool
    
    /// Child nodes (for directories)
    var children: [FileTreeNode] = []
    
    /// Parent node reference
    weak var parent: FileTreeNode?
    
    /// Whether this directory node is expanded in the UI
    var isExpanded: Bool = false
    
    /// The hierarchical level (0 for root, 1 for first level, etc.)
    var level: Int = 0
    
    // MARK: - Initialization
    
    /**
     Creates a new file tree node.
     
     - Parameters:
        - url: The file or directory URL
        - parent: The parent node (nil for root nodes)
     */
    init(url: URL, parent: FileTreeNode? = nil) {
        self.url = url
        self.name = url.lastPathComponent
        self.parent = parent
        self.level = (parent?.level ?? -1) + 1
        
        // Check if this is a directory
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        self.isDirectory = isDir.boolValue
        
        // Load children if this is a directory
        if isDirectory {
            loadChildren()
        }
    }
    
    // MARK: - Directory Management
    
    /**
     Loads the children of this directory node.
     
     This method reads the contents of the directory and creates child nodes
     for each item. Children are automatically sorted with directories first,
     followed by files in alphabetical order.
     
     - Note: Only works for directory nodes. Files nodes are ignored.
     */
    func loadChildren() {
        guard isDirectory else { return }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            
            // Create child nodes
            children = contents.map { FileTreeNode(url: $0, parent: self) }
            
            // Sort children: directories first, then alphabetical
            children.sort { first, second in
                if first.isDirectory && !second.isDirectory {
                    return true
                } else if !first.isDirectory && second.isDirectory {
                    return false
                } else {
                    return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
                }
            }
        } catch {
            print("Error loading children for \(url.path): \(error)")
        }
    }
    
    /**
     Toggles the expansion state of this directory node.
     
     If the directory is collapsed, it will be expanded and children will be loaded
     if they haven't been loaded yet. If expanded, it will be collapsed.
     
     - Note: Only works for directory nodes. File nodes are ignored.
     */
    func toggleExpansion() {
        guard isDirectory else { return }
        isExpanded.toggle()
        
        // Load children on first expansion if needed
        if isExpanded && children.isEmpty {
            loadChildren()
        }
    }
    
    /**
     Refreshes the contents of this directory node.
     
     This method clears the current children and reloads them from the file system.
     Useful for updating the tree when files are added, removed, or modified.
     
     - Note: Only works for directory nodes. File nodes are ignored.
     */
    func refresh() {
        if isDirectory {
            children.removeAll()
            loadChildren()
        }
    }
}
