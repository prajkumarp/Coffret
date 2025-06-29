import UIKit
import UniformTypeIdentifiers
import MobileCoreServices

/**
 Main view controller for the Coffret FTP Server application.
 
 This class manages the primary user interface for the FTP server, providing controls
 for starting/stopping the server, managing files, and displaying connection information.
 It integrates file management capabilities with FTP server functionality.
 
 ## Key Features
 - FTP server start/stop controls
 - Port configuration for FTP and web services
 - File tree navigation and management
 - File import, export, and manipulation
 - Real-time server status and URL display
 - Touch-friendly interface with gesture support
 
 ## UI Components
 - Server configuration section (ports, start/stop)
 - Status display (server state, connection URLs)
 - File management buttons (import, create folder, add sample)
 - File tree table view with hierarchical display
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 29/06/25
 */
class ViewController: UIViewController {
    
    // MARK: - UI Elements
    
    /// Main scroll view for content
    let scrollView = UIScrollView()
    
    /// Content container view
    let contentView = UIView()
    
    /// App title label
    let titleLabel = UILabel()
    
    /// FTP port configuration field
    let portTextField = UITextField()
    
    /// Web server port configuration field
    let webPortTextField = UITextField()
    
    /// Server start/stop control button
    let startStopButton = UIButton(type: .system)
    
    /// Server status display label
    let statusLabel = UILabel()
    
    /// FTP URL display label
    let urlLabel = UILabel()
    
    /// Web URL display label
    let webUrlLabel = UILabel()
    
    /// File tree display table view
    let filesTableView = UITableView()
    
    /// File import button
    let importButton = UIButton(type: .system)
    
    /// Create folder button
    let createFolderButton = UIButton(type: .system)
    
    /// Add sample file button
    let addSampleButton = UIButton(type: .system)
    
    // MARK: - Server Properties
    
    /// The FTP server instance
    var ftpServer: FTPServer?
    
    /// Current server running state
    var isServerRunning = false
    
    /// Root node of the file tree
    var rootNode: FileTreeNode?
    
    /// Flattened list of visible nodes for table view
    var flattenedNodes: [FileTreeNode] = []
    
    /// Currently selected file tree node
    var selectedNode: FileTreeNode?
    
    // MARK: - View Lifecycle
    
    /**
     Called after the view loads.
     
     Sets up the user interface and loads the initial file tree.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadFileTree()
    }
    
    // MARK: - UI Setup
    
    /**
     Configures the user interface components and layout.
     
     Sets up all UI elements including scroll view, text fields, buttons,
     table view, and their respective constraints and styling.
     */
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "iOS FTP Server"
        
        // Configure scroll view hierarchy
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure title label
        titleLabel.text = "📁 iOS FTP Server"
        titleLabel.font = .boldSystemFont(ofSize: 28)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Port fields
        setupTextField(portTextField, placeholder: "FTP Port", defaultValue: "2121")
        setupTextField(webPortTextField, placeholder: "Web Port", defaultValue: "8080")
        
        // Start/Stop button
        startStopButton.setTitle("Start Server", for: .normal)
        startStopButton.backgroundColor = .systemBlue
        startStopButton.setTitleColor(.white, for: .normal)
        startStopButton.layer.cornerRadius = 12
        startStopButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        startStopButton.addTarget(self, action: #selector(startStopButtonTapped), for: .touchUpInside)
        startStopButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(startStopButton)
        
        // Status labels
        setupLabel(statusLabel, text: "Server Stopped", color: .systemRed)
        setupLabel(urlLabel, text: "FTP URL will appear here", color: .systemBlue)
        setupLabel(webUrlLabel, text: "Web URL will appear here", color: .systemBlue)
        
        // Action buttons
        setupActionButton(importButton, title: "📥 Import Files", color: .systemGreen, action: #selector(importFromFiles))
        setupActionButton(createFolderButton, title: "📁 Create Folder", color: .systemOrange, action: #selector(createFolder))
        setupActionButton(addSampleButton, title: "📝 Add Sample File", color: .systemPurple, action: #selector(addSampleFile))
        
        // Files table view
        filesTableView.delegate = self
        filesTableView.dataSource = self
        filesTableView.layer.cornerRadius = 12
        filesTableView.layer.borderWidth = 1
        filesTableView.layer.borderColor = UIColor.systemGray4.cgColor
        filesTableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(filesTableView)
        
        // Add long press gesture for context menu
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        filesTableView.addGestureRecognizer(longPress)
        
        setupConstraints()
    }
    
    private func setupTextField(_ textField: UITextField, placeholder: String, defaultValue: String) {
        textField.placeholder = placeholder
        textField.text = defaultValue
        textField.borderStyle = .roundedRect
        textField.keyboardType = .numberPad
        textField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textField)
        
        // Add toolbar to dismiss keyboard
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.setItems([doneButton], animated: false)
        textField.inputAccessoryView = toolbar
    }
    
    private func setupLabel(_ label: UILabel, text: String, color: UIColor) {
        label.text = text
        label.textColor = color
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
    }
    
    private func setupActionButton(_ button: UIButton, title: String, color: UIColor, action: Selector) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(button)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Port fields
            portTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            portTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            portTextField.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.45),
            portTextField.heightAnchor.constraint(equalToConstant: 44),
            
            webPortTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            webPortTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            webPortTextField.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.45),
            webPortTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Start/Stop button
            startStopButton.topAnchor.constraint(equalTo: portTextField.bottomAnchor, constant: 20),
            startStopButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            startStopButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            startStopButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Status labels
            statusLabel.topAnchor.constraint(equalTo: startStopButton.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            urlLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            urlLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            urlLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            webUrlLabel.topAnchor.constraint(equalTo: urlLabel.bottomAnchor, constant: 10),
            webUrlLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            webUrlLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Action buttons
            importButton.topAnchor.constraint(equalTo: webUrlLabel.bottomAnchor, constant: 30),
            importButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            importButton.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.3),
            importButton.heightAnchor.constraint(equalToConstant: 44),
            
            createFolderButton.topAnchor.constraint(equalTo: webUrlLabel.bottomAnchor, constant: 30),
            createFolderButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            createFolderButton.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.3),
            createFolderButton.heightAnchor.constraint(equalToConstant: 44),
            
            addSampleButton.topAnchor.constraint(equalTo: webUrlLabel.bottomAnchor, constant: 30),
            addSampleButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            addSampleButton.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.3),
            addSampleButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Files table view
            filesTableView.topAnchor.constraint(equalTo: importButton.bottomAnchor, constant: 20),
            filesTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            filesTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            filesTableView.heightAnchor.constraint(equalToConstant: 400),
            filesTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
//    @objc private func dismissKeyboard() {
//        view.endEditing(true)
//    }
    
    func loadFileTree() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        rootNode = FileTreeNode(url: documentsPath)
        rootNode?.isExpanded = true
        updateFlattenedNodes()
    }
    
    func updateFlattenedNodes() {
        flattenedNodes.removeAll()
        if let root = rootNode {
            addNodeToFlattenedList(root)
        }
        
        DispatchQueue.main.async {
            self.filesTableView.reloadData()
        }
    }
    
    private func addNodeToFlattenedList(_ node: FileTreeNode) {
        flattenedNodes.append(node)
        
        if node.isExpanded {
            for child in node.children {
                addNodeToFlattenedList(child)
            }
        }
    }
    
//    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
//        if gesture.state == .began {
//            let point = gesture.location(in: filesTableView)
//            if let indexPath = filesTableView.indexPathForRow(at: point) {
//                selectedNode = flattenedNodes[indexPath.row]
//                showContextMenu(for: selectedNode!)
//            }
//        }
//    }
    
    private func showContextMenu(for node: FileTreeNode) {
        let alert = UIAlertController(title: node.name, message: nil, preferredStyle: .actionSheet)
        
        // Share action
        alert.addAction(UIAlertAction(title: "Share", style: .default) { _ in
            self.shareFile(node)
        })
        
        // Copy action
        alert.addAction(UIAlertAction(title: "Copy", style: .default) { _ in
            self.copyFile(node)
        })
        
        // Rename action
        alert.addAction(UIAlertAction(title: "Rename", style: .default) { _ in
            self.renameFile(node)
        })
        
        // Delete action
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.deleteFile(node)
        })
        
        // If it's a directory, add create folder option
        if node.isDirectory {
            alert.addAction(UIAlertAction(title: "Create Subfolder", style: .default) { _ in
                self.createFolderInNode(in: node)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Configure for iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = filesTableView
            popover.sourceRect = CGRect(x: filesTableView.bounds.midX, y: filesTableView.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
    
    // MARK: - Server Management Methods
    // (These methods are now handled in ViewController+ServerActions.swift)
    
    // MARK: - Alert Helper
    // (This method is duplicated in extensions - will be consolidated)
    func showAlert(_ message: String) {
        let alert = UIAlertController(title: "FTP Server", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
//    @objc private func addSampleFile() {
//        let sampleContent = """
//        📁 iOS FTP Server Sample File
//        =============================
//        
//        This is a sample file created by the iOS FTP Server app.
//        Timestamp: \(Date())
//        
//        You can:
//        • Edit this file through FTP clients
//        • Create new files and folders
//        • Upload files via the web interface
//        • Download files to other devices
//        
//        Features:
//        ✅ FTP Server with authentication
//        ✅ Web interface for file management
//        ✅ File upload/download
//        ✅ Folder creation
//        ✅ File operations (copy, rename, delete)
//        
//        Enjoy using your iOS FTP Server! 🚀
//        """
//        
//        let fileName = "sample_\(Int(Date().timeIntervalSince1970)).txt"
//        
//        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let fileURL = documentsPath.appendingPathComponent(fileName)
//        
//        do {
//            try sampleContent.write(to: fileURL, atomically: true, encoding: .utf8)
//            refreshFileTree()
//            showAlert("Sample file created successfully! 📝")
//        } catch {
//            showAlert("Failed to create sample file: \(error.localizedDescription)")
//        }
//    }
}
