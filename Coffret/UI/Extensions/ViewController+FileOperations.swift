import UIKit
import Foundation

/**     
 File operations extension for ViewController.
 
 This extension provides file management functionality including sharing, copying,
 renaming, and deleting files and directories. It handles user interactions for
 file operations through alerts and activity controllers.
 
 ## Supported Operations
 - File sharing via system share sheet
 - File and directory copying
 - File and directory renaming
 - File and directory deletion
 - Directory creation within specific parent nodes
 - Error handling and user feedback
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 29/06/25
 */
                                                        
// MARK: - File Operations
extension ViewController {
    
    /**
     Shares a file using the system share sheet.
     
     Presents a UIActivityViewController to allow users to share files through
     various system sharing options (AirDrop, Messages, Mail, etc.).
     
     - Parameter node: The file tree node to share
     */
    func shareFile(_ node: FileTreeNode) {
        let activityVC = UIActivityViewController(activityItems: [node.url], applicationActivities: nil)
        
        // Configure popover presentation for iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityVC, animated: true)
    }
    
    /**
     Creates a copy of the specified file or directory.
     
     Creates a duplicate of the file/directory with "_copy" appended to the name.
     Handles name conflicts and preserves file extensions.
     
     - Parameter node: The file tree node to copy
     */
    func copyFile(_ node: FileTreeNode) {
        let fileName = node.name
        let fileExtension = (fileName as NSString).pathExtension
        let baseName = (fileName as NSString).deletingPathExtension
        
        // Generate copy name with extension handling
        var copyName = "\(baseName)_copy"
        if !fileExtension.isEmpty {
            copyName += ".\(fileExtension)"
        }
        
        let copyURL = node.url.deletingLastPathComponent().appendingPathComponent(copyName)
        
        do {
            try FileManager.default.copyItem(at: node.url, to: copyURL)
            refreshFileTree()
        } catch {
            showAlert("Failed to copy file: \(error.localizedDescription)")
        }
    }
    
    /**
     Prompts the user to rename a file or directory.
     
     Displays an alert with a text field pre-populated with the current name,
     allowing the user to enter a new name.
     
     - Parameter node: The file tree node to rename
     */
    func renameFile(_ node: FileTreeNode) {
        let alert = UIAlertController(title: "Rename", message: "Enter new name:", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = node.name
            textField.selectAll(nil)
        }
        
        alert.addAction(UIAlertAction(title: "Rename", style: .default) { _ in
            guard let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            
            let newURL = node.url.deletingLastPathComponent().appendingPathComponent(newName)
            
            do {
                try FileManager.default.moveItem(at: node.url, to: newURL)
                self.refreshFileTree()
            } catch {
                self.showAlert("Failed to rename: \(error.localizedDescription)")
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    /**
     Prompts the user to confirm deletion of a file or directory.
     
     Shows a confirmation alert before permanently deleting the selected item.
     Provides different messages for files vs directories.
     
     - Parameter node: The file tree node to delete
     */
    func deleteFile(_ node: FileTreeNode) {
        let itemType = node.isDirectory ? "folder" : "file"
        let alert = UIAlertController(
            title: "Delete \(itemType.capitalized)",
            message: "Are you sure you want to delete this \(itemType)? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            do {
                try FileManager.default.removeItem(at: node.url)
                self.refreshFileTree()
            } catch {
                self.showAlert("Failed to delete \(itemType): \(error.localizedDescription)")
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    /**
     Creates a new folder in the specified parent directory.
     
     Prompts the user for a folder name and creates the folder at the
     selected location. Updates the file tree upon success.
     
     - Parameter parentNode: The parent directory node where the folder will be created
     
     */
    func createFolderInNode(in parentNode: FileTreeNode) {
        let alert = UIAlertController(title: "Create Folder", message: "Enter folder name:", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Folder name"
        }
        
        alert.addAction(UIAlertAction(title: "Create", style: .default) { _ in
            guard let folderName = alert.textFields?.first?.text, !folderName.isEmpty else { return }
            
            let folderURL = parentNode.url.appendingPathComponent(folderName)
            
            do {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false, attributes: nil)
                self.refreshFileTree()
            } catch {
                self.showAlert("Failed to create folder: \(error.localizedDescription)")
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Utility Methods
    
    /**
     Refreshes the file tree display.
     
     Reloads the file tree data and updates the table view to reflect changes.
     */
    func refreshFileTree() {
        loadFileTree()
        filesTableView.reloadData()
    }
}
