import UIKit
import Foundation

/**
 Custom table view cell for displaying file tree nodes.
 
 This cell provides a specialized layout for displaying hierarchical file structures
 with appropriate indentation, icons, and file information. It supports both files
 and directories with expand/collapse functionality.
 
 ## Cell Components
 - Indentation constraint for hierarchical display
 - Expand/collapse button for directories
 - File type icon (folder/document)
 - File/directory name label
 - File size label (for files only)
 
 ## Features
 - Dynamic indentation based on tree level
 - File size formatting with ByteCountFormatter
 - Directory expansion state visualization
 - Automatic file attribute reading
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 29/06/25
 */
class FileTreeTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlets
    
    /// Constraint for controlling indentation based on tree level
    @IBOutlet weak var indentationConstraint: NSLayoutConstraint!
    
    /// Button for expanding/collapsing directories
    @IBOutlet weak var expandButton: UIButton!
    
    /// Label displaying file/directory icon
    @IBOutlet weak var iconLabel: UILabel!
    
    /// Label displaying file/directory name
    @IBOutlet weak var nameLabel: UILabel!
    
    /// Label displaying file size (files only)
    @IBOutlet weak var sizeLabel: UILabel!
    
    // MARK: - Configuration
    
    /**
     Configures the cell with a file tree node.
     
     Updates all cell components based on the provided node's properties
     including name, type, size, and hierarchy level.
     
     - Parameter node: The FileTreeNode to display in this cell
     */
    func configure(with node: FileTreeNode) {
        // Set basic properties
        nameLabel.text = node.name
        iconLabel.text = node.isDirectory ? "📁" : "📄"
        
        // Configure indentation based on hierarchy level
        indentationConstraint.constant = CGFloat(node.level * 20)
        
        // Configure expand/collapse button for directories
        if node.isDirectory {
            expandButton.isHidden = false
            expandButton.setTitle(node.isExpanded ? "▼" : "▶", for: .normal)
        } else {
            expandButton.isHidden = true
        }
        
        // Display file size for files
        if !node.isDirectory {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: node.url.path)
                if let fileSize = attributes[.size] as? UInt64 {
                    sizeLabel.text = formatFileSize(fileSize)
                } else {
                    sizeLabel.text = ""
                }
            } catch {
                sizeLabel.text = ""
            }
        } else {
            // Clear size label for directories
            sizeLabel.text = ""
        }
    }
    
    // MARK: - Private Methods
    
    /**
     Formats file size in human-readable format.
     
     Uses ByteCountFormatter to convert bytes to appropriate units
     (B, KB, MB, GB, etc.) with proper formatting.
     
     - Parameter bytes: The file size in bytes
     - Returns: Formatted file size string
     */
    private func formatFileSize(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
