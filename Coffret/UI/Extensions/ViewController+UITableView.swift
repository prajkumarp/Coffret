import UIKit
import Foundation

/**
 Table view data source and delegate extension for ViewController.
 
 This extension implements UITableViewDataSource and UITableViewDelegate protocols
 to provide hierarchical file tree display functionality. It handles cell configuration,
 user interactions, and file tree navigation with expand/collapse support.
 
 ## Table View Features
 - Hierarchical file tree display with indentation
 - File type icons (folder/document)
 - File size and item count display
 - Expand/collapse functionality for directories
 - Touch interactions for navigation
 - Long press gestures for context actions
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 29/06/25
 */
// MARK: - UITableViewDataSource & UITableViewDelegate
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    /**
     Returns the number of rows in the table view section.
     
     - Parameters:
        - tableView: The table view requesting the information
        - section: The section index
     
     - Returns: The number of flattened file tree nodes
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return flattenedNodes.count
    }
    
    /**
     Configures and returns a table view cell for the specified index path.
     
     Sets up the cell with file/directory information including name, icon,
     size/item count, and appropriate indentation based on hierarchy level.
     
     - Parameters:
        - tableView: The table view requesting the cell
        - indexPath: The index path specifying the location of the cell
     
     - Returns: A configured UITableViewCell
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileTreeCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "FileTreeCell")
        let node = flattenedNodes[indexPath.row]
        
        // Configure basic cell content
        cell.textLabel?.text = node.name
        cell.imageView?.image = UIImage(systemName: node.isDirectory ? "folder.fill" : "doc.fill")
        
        // Set hierarchical indentation
        cell.indentationLevel = node.level
        cell.indentationWidth = 20
        
        // Configure subtitle based on item type
        if !node.isDirectory {
            // Show file size for files
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: node.url.path)
                if let fileSize = attributes[.size] as? UInt64 {
                    let formatter = ByteCountFormatter()
                    formatter.allowedUnits = [.useAll]
                    formatter.countStyle = .file
                    cell.detailTextLabel?.text = formatter.string(fromByteCount: Int64(fileSize))
                } else {
                    cell.detailTextLabel?.text = ""
                }
            } catch {
                cell.detailTextLabel?.text = ""
            }
        } else {
            // Show item count for directories
            let childCount = node.children.count
            cell.detailTextLabel?.text = "\(childCount) item\(childCount != 1 ? "s" : "")"
        }
        
        // Configure accessory view for directories
        if node.isDirectory {
            cell.accessoryType = node.isExpanded ? .none : .disclosureIndicator
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    /**
     Handles table view cell selection.
     
     For directories, toggles the expand/collapse state and updates the table view.
     For files, stores the selected node for potential operations.
     
     - Parameters:
        - tableView: The table view containing the selected cell
        - indexPath: The index path of the selected cell
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let node = flattenedNodes[indexPath.row]
        selectedNode = node
        
        if node.isDirectory {
            // Toggle directory expansion
            node.toggleExpansion()
            updateFlattenedNodes()
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    // MARK: - Context Menu Support
    
    /**
     Handles long press gestures on table view cells.
     
     Presents a context menu with available actions for the selected file or directory.
     
     - Parameter gestureRecognizer: The long press gesture recognizer
     */
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let point = gestureRecognizer.location(in: filesTableView)
            
            if let indexPath = filesTableView.indexPathForRow(at: point) {
                let node = flattenedNodes[indexPath.row]
                selectedNode = node
                
                // Create context menu
                let alertController = UIAlertController(title: node.name, message: nil, preferredStyle: .actionSheet)
                
                // Share action
                alertController.addAction(UIAlertAction(title: "Share", style: .default) { _ in
                    self.shareFile(node)
                })
                
                // Copy action
                alertController.addAction(UIAlertAction(title: "Copy", style: .default) { _ in
                    self.copyFile(node)
                })
                
                // Rename action
                alertController.addAction(UIAlertAction(title: "Rename", style: .default) { _ in
                    self.renameFile(node)
                })
                
                // Delete action
                alertController.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                    self.deleteFile(node)
                })
                
                // Cancel action
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                
                // Configure popover for iPad
                if let popover = alertController.popoverPresentationController {
                    popover.sourceView = filesTableView
                    popover.sourceRect = filesTableView.rectForRow(at: indexPath)
                }
                
                present(alertController, animated: true)
            }
        }
    }
}
