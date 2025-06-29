import UIKit
import Foundation

/**
 Server management extension for ViewController.
 
 This extension handles FTP server lifecycle management including starting,
 stopping, and configuration. It manages the UI state changes that occur
 when the server status changes and provides user feedback.
 
 ## Server Management Features
 - Server start/stop functionality
 - Port validation and configuration
 - UI state management based on server status
 - Connection URL generation and display
 - Error handling and user feedback
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 29/06/25
 */
// MARK: - Server Actions
extension ViewController {
    
    /**
     Handles the start/stop button tap event.
     
     Toggles the server state between running and stopped based on the current state.
     
     - Parameter sender: The button that triggered the action
     */
    @IBAction func startStopButtonTapped(_ sender: UIButton) {
        if isServerRunning {
            stopServer()
        } else {
            startServer()
        }
    }
    
    /**
     Starts the FTP server with the configured ports.
     
     Validates the port configuration, creates a new FTP server instance,
     and updates the UI to reflect the running state. Displays connection
     URLs and disables port configuration fields.
     */
    private func startServer() {
        // Validate FTP port
        guard let portText = portTextField.text, let port = UInt16(portText), port > 0 else {
            showAlert("Invalid FTP port number")
            return
        }
        
        // Validate web port
        guard let webPortText = webPortTextField.text, let webPort = UInt16(webPortText), webPort > 0 else {
            showAlert("Invalid Web port number")
            return
        }
        
        // Create and start server
        ftpServer = FTPServer(port: port, webPort: webPort)
        
        do {
            try ftpServer?.start()
            isServerRunning = true
            
            // Update UI for running state
            startStopButton.setTitle("Stop Server", for: .normal)
            startStopButton.backgroundColor = .systemRed
            statusLabel.text = "Server Running"
            statusLabel.textColor = .systemGreen
            
            // Display connection URLs
            if let serverURL = ftpServer?.getServerURL() {
                urlLabel.text = "FTP: \(serverURL)"
            }
            
            if let webURL = ftpServer?.getWebURL() {
                webUrlLabel.text = "Web: \(webURL)"
            }
            
            // Disable port configuration while server is running
            portTextField.isEnabled = false
            webPortTextField.isEnabled = false
        } catch {
            showAlert("Failed to start server: \(error.localizedDescription)")
        }
    }
    
    /**
     Stops the FTP server.
     
     Shuts down the server, updates the UI to reflect the stopped state,
     and re-enables port configuration fields.
     */
    private func stopServer() {
        ftpServer?.stop()
        ftpServer = nil
        isServerRunning = false
        
        // Update UI for stopped state
        startStopButton.setTitle("Start Server", for: .normal)
        startStopButton.backgroundColor = .systemBlue
        statusLabel.text = "Server Stopped"
        statusLabel.textColor = .systemRed
        urlLabel.text = "FTP URL will appear here"
        webUrlLabel.text = "Web URL will appear here"
        
        // Re-enable port configuration
        portTextField.isEnabled = true
        webPortTextField.isEnabled = true
    }
    
    // MARK: - File Management Actions
    
    /**
     Handles the import files button tap.
     
     Presents a document picker to allow users to import files from other apps.
     */
    @objc func importFromFiles() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        present(documentPicker, animated: true)
    }
    
    /**
     Handles the create folder button tap.
     
     Prompts the user to create a new folder in the current directory.
     
     
     */
    @objc func createFolder() {
        let alert = UIAlertController(title: "Create Folder", message: "Enter folder name:", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Folder name"
        }
        
        alert.addAction(UIAlertAction(title: "Create", style: .default) { _ in
            guard let folderName = alert.textFields?.first?.text, !folderName.isEmpty else {
                return
            }
            
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let folderURL = documentsURL.appendingPathComponent(folderName)
            
            do {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                self.refreshFileTree()
            } catch {
                self.showAlert("Failed to create folder: \(error.localizedDescription)")
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    /**
     Handles the add sample file button tap.
     
     Creates a sample text file with basic content for demonstration purposes.
     */
    @objc func addSampleFile() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sampleURL = documentsURL.appendingPathComponent("sample.txt")
        
        let sampleContent = """
        Welcome to iOS FTP Server!
        
        This is a sample file created by the Coffret app.
        
        You can:
        - Access files via FTP client
        - Browse files through web interface
        - Upload and download files
        - Create and manage folders
        
        Server Features:
        - FTP protocol support
        - Web-based file manager
        - Multiple connection handling
        - File operations (copy, rename, delete)
        
        Created on: \(Date())
        """
        
        do {
            try sampleContent.write(to: sampleURL, atomically: true, encoding: .utf8)
            refreshFileTree()
        } catch {
            showAlert("Failed to create sample file: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Keyboard Management
    
    /**
     Dismisses the keyboard when the done button is tapped.
     */
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
