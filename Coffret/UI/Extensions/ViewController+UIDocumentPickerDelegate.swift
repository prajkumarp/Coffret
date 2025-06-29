import UIKit
import UniformTypeIdentifiers

/**
 Document picker delegate extension for ViewController.
 
 This extension implements UIDocumentPickerDelegate to handle file imports
 from the system document picker. It manages the secure import of files
 from other apps and handles name conflicts by creating unique filenames.
 
 ## Import Features
 - Multiple file selection support
 - Security-scoped resource handling
 - Automatic name conflict resolution
 - Error handling and user feedback
 - File tree refresh after import
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 29/06/25
 */
// MARK: - UIDocumentPickerDelegate
extension ViewController: UIDocumentPickerDelegate {
    
    /**
     Called when the user selects documents from the document picker.
     
     This method handles the import of selected files into the app's documents
     directory. It manages security-scoped resources, handles name conflicts,
     and provides error feedback to the user.
     
     - Parameters:
        - controller: The document picker controller
        - urls: Array of URLs representing the selected documents
     */
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        for url in urls {
            // Start accessing security-scoped resource for external files
            guard url.startAccessingSecurityScopedResource() else { continue }
            
            let fileName = url.lastPathComponent
            let destinationURL = documentsPath.appendingPathComponent(fileName)
            
            do {
                // Handle name conflicts by creating unique filename
                var finalURL = destinationURL
                var counter = 1
                while FileManager.default.fileExists(atPath: finalURL.path) {
                    let fileExtension = (fileName as NSString).pathExtension
                    let baseName = (fileName as NSString).deletingPathExtension
                    let newFileName = fileExtension.isEmpty ? "\(baseName)_\(counter)" : "\(baseName)_\(counter).\(fileExtension)"
                    finalURL = documentsPath.appendingPathComponent(newFileName)
                    counter += 1
                }
                
                // Copy the file to documents directory
                try FileManager.default.copyItem(at: url, to: finalURL)
            } catch {
                showAlert("Failed to import \(fileName): \(error.localizedDescription)")
            }
            
            // Stop accessing security-scoped resource
            url.stopAccessingSecurityScopedResource()
        }
        
        // Refresh the file tree to show imported files
        refreshFileTree()
    }
    
    /**
     Called when the user cancels the document picker.
     
     This method is called when the document picker is dismissed without
     selecting any documents. No action is required in this implementation.
     
     - Parameter controller: The document picker controller that was cancelled
     */
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // No action needed for cancellation
    }
}
