import Foundation

/**
 Generates the HTML web interface for the FTP server.
 
 This class provides a static method to generate a complete HTML page with embedded
 CSS and JavaScript for the web-based file management interface. The interface
 includes features for file browsing, uploading, downloading, and basic file operations.
 
 ## Features
 - Responsive design with modern styling
 - Directory navigation with breadcrumb support
 - File upload with drag-and-drop functionality
 - File download and deletion
 - Directory creation
 - File type icons and file size formatting
 - AJAX-based operations for smooth user experience
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 29/06/25
 */
class WebInterfaceGenerator {
    
    /**
     Generates the complete HTML interface for the FTP server.
     
     This method returns a self-contained HTML page with embedded CSS and JavaScript
     that provides a full-featured web interface for file management operations.
     
     - Returns: A complete HTML string for the web interface
     */
    static func generateHTML() -> String {
        return """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>iOS FTP Server - Web Interface</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.95);
            border-radius: 20px;
            padding: 30px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            backdrop-filter: blur(10px);
        }
        
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #eee;
        }
        
        .header h1 {
            color: #333;
            font-size: 2.5em;
            margin-bottom: 10px;
            background: linear-gradient(45deg, #667eea, #764ba2);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        
        .controls {
            display: flex;
            gap: 15px;
            margin-bottom: 30px;
            flex-wrap: wrap;
            justify-content: center;
        }
        
        .btn {
            background: linear-gradient(45deg, #667eea, #764ba2);
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 25px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(102, 126, 234, 0.4);
        }
        
        .btn.danger {
            background: linear-gradient(45deg, #ff6b6b, #ee5a52);
            box-shadow: 0 4px 15px rgba(255, 107, 107, 0.3);
        }
        
        .btn.danger:hover {
            box-shadow: 0 6px 20px rgba(255, 107, 107, 0.4);
        }
        
        .file-upload {
            display: none;
        }
        
        .file-tree {
            background: white;
            border-radius: 15px;
            overflow: hidden;
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.08);
        }
        
        .file-item {
            display: flex;
            align-items: center;
            padding: 15px 20px;
            border-bottom: 1px solid #f0f0f0;
            cursor: pointer;
            transition: all 0.2s ease;
            position: relative;
        }
        
        .file-item:hover {
            background: linear-gradient(90deg, rgba(102, 126, 234, 0.05), rgba(118, 75, 162, 0.05));
            transform: translateX(5px);
        }
        
        .file-item.selected {
            background: linear-gradient(90deg, rgba(102, 126, 234, 0.1), rgba(118, 75, 162, 0.1));
            border-left: 4px solid #667eea;
        }
        
        .file-icon {
            width: 24px;
            height: 24px;
            margin-right: 15px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
        }
        
        .file-name {
            flex: 1;
            font-weight: 500;
            color: #333;
        }
        
        .file-size {
            color: #666;
            font-size: 14px;
            margin-left: 15px;
        }
        
        .file-actions {
            display: flex;
            gap: 10px;
            margin-left: 15px;
        }
        
        .action-btn {
            background: none;
            border: none;
            padding: 8px;
            border-radius: 50%;
            cursor: pointer;
            color: #666;
            transition: all 0.2s ease;
        }
        
        .action-btn:hover {
            background: rgba(102, 126, 234, 0.1);
            color: #667eea;
            transform: scale(1.1);
        }
        
        .breadcrumb {
            display: flex;
            align-items: center;
            margin-bottom: 20px;
            padding: 10px 20px;
            background: rgba(102, 126, 234, 0.05);
            border-radius: 10px;
        }
        
        .breadcrumb-item {
            color: #667eea;
            text-decoration: none;
            font-weight: 500;
            padding: 5px 10px;
            border-radius: 5px;
            transition: background 0.2s ease;
        }
        
        .breadcrumb-item:hover {
            background: rgba(102, 126, 234, 0.1);
        }
        
        .breadcrumb-separator {
            margin: 0 10px;
            color: #999;
        }
        
        .loading {
            text-align: center;
            padding: 40px;
            color: #666;
        }
        
        .spinner {
            display: inline-block;
            width: 30px;
            height: 30px;
            border: 3px solid rgba(102, 126, 234, 0.3);
            border-radius: 50%;
            border-top-color: #667eea;
            animation: spin 1s ease-in-out infinite;
        }
        
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            backdrop-filter: blur(5px);
        }
        
        .modal-content {
            background: white;
            margin: 15% auto;
            padding: 30px;
            border-radius: 15px;
            width: 90%;
            max-width: 400px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
        }
        
        .modal input {
            width: 100%;
            padding: 12px;
            border: 2px solid #eee;
            border-radius: 8px;
            font-size: 16px;
            margin: 15px 0;
            transition: border-color 0.2s ease;
        }
        
        .modal input:focus {
            outline: none;
            border-color: #667eea;
        }
        
        @media (max-width: 768px) {
            .container {
                padding: 20px;
                margin: 10px;
            }
            
            .controls {
                flex-direction: column;
            }
            
            .file-item {
                padding: 12px 15px;
            }
            
            .file-actions {
                margin-left: 10px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📁 iOS FTP Server</h1>
            <p>Web File Manager Interface</p>
        </div>
        
        <div class="controls">
            <input type="file" id="fileInput" class="file-upload" multiple>
            <button class="btn" onclick="document.getElementById('fileInput').click()">
                📤 Upload Files
            </button>
            <button class="btn" onclick="createFolder()">
                📁 New Folder
            </button>
            <button class="btn" onclick="refreshFiles()">
                🔄 Refresh
            </button>
            <button class="btn danger" onclick="deleteSelected()" id="deleteBtn" style="display: none;">
                🗑️ Delete Selected
            </button>
        </div>
        
        <div class="breadcrumb" id="breadcrumb">
            <a href="#" class="breadcrumb-item" onclick="navigateTo('')">🏠 Home</a>
        </div>
        
        <div class="file-tree" id="fileTree">
            <div class="loading">
                <div class="spinner"></div>
                <p>Loading files...</p>
            </div>
        </div>
    </div>
    
    <!-- Modal for creating folders -->
    <div id="folderModal" class="modal">
        <div class="modal-content">
            <h3>Create New Folder</h3>
            <input type="text" id="folderName" placeholder="Folder name">
            <div style="text-align: right; margin-top: 20px;">
                <button class="btn" onclick="closeFolderModal()">Cancel</button>
                <button class="btn" onclick="confirmCreateFolder()" style="margin-left: 10px;">Create</button>
            </div>
        </div>
    </div>
    
    <script>
        let currentPath = '';
        let selectedFiles = new Set();
        
        // Initialize
        document.addEventListener('DOMContentLoaded', function() {
            loadFiles();
            
            // File upload handler
            document.getElementById('fileInput').addEventListener('change', function(e) {
                uploadFiles(e.target.files);
            });
        });
        
        function loadFiles(path = '') {
            currentPath = path;
            updateBreadcrumb();
            
            fetch(`/api/files${path ? '/' + encodeURIComponent(path) : ''}`)
                .then(response => response.json())
                .then(files => {
                    displayFiles(files);
                })
                .catch(error => {
                    console.error('Error loading files:', error);
                    document.getElementById('fileTree').innerHTML = '<div class="loading"><p>Error loading files</p></div>';
                });
        }
        
        function displayFiles(files) {
            const fileTree = document.getElementById('fileTree');
            
            if (files.length === 0) {
                fileTree.innerHTML = '<div class="loading"><p>📂 Empty folder</p></div>';
                return;
            }
            
            let html = '';
            
            // Sort files: directories first, then by name
            files.sort((a, b) => {
                if (a.isDirectory && !b.isDirectory) return -1;
                if (!a.isDirectory && b.isDirectory) return 1;
                return a.name.localeCompare(b.name);
            });
            
            files.forEach(file => {
                const icon = file.isDirectory ? '📁' : getFileIcon(file.name);
                const size = file.isDirectory ? '' : formatFileSize(file.size);
                const path = file.path.startsWith('/') ? file.path.substring(1) : file.path;
                
                html += `
                    <div class="file-item" onclick="selectFile('${path}', ${file.isDirectory})" data-path="${path}">
                        <div class="file-icon">${icon}</div>
                        <div class="file-name">${file.name}</div>
                        <div class="file-size">${size}</div>
                        <div class="file-actions">
                            ${!file.isDirectory ? `<button class="action-btn" onclick="event.stopPropagation(); downloadFile('${path}')" title="Download">⬇️</button>` : ''}
                            <button class="action-btn" onclick="event.stopPropagation(); deleteFile('${path}')" title="Delete">🗑️</button>
                        </div>
                    </div>
                `;
            });
            
            fileTree.innerHTML = html;
        }
        
        function selectFile(path, isDirectory) {
            if (isDirectory) {
                loadFiles(path);
            } else {
                // Toggle selection for files
                const fileItem = document.querySelector(`[data-path="${path}"]`);
                if (selectedFiles.has(path)) {
                    selectedFiles.delete(path);
                    fileItem.classList.remove('selected');
                } else {
                    selectedFiles.add(path);
                    fileItem.classList.add('selected');
                }
                
                // Show/hide delete button
                const deleteBtn = document.getElementById('deleteBtn');
                deleteBtn.style.display = selectedFiles.size > 0 ? 'inline-block' : 'none';
            }
        }
        
        function downloadFile(path) {
            window.open(`/download/${encodeURIComponent(path)}`, '_blank');
        }
        
        function deleteFile(path) {
            if (confirm(`Are you sure you want to delete ${path}?`)) {
                fetch(`/api/delete/${encodeURIComponent(path)}`, {
                    method: 'DELETE'
                })
                .then(response => response.text())
                .then(() => {
                    loadFiles(currentPath);
                })
                .catch(error => {
                    console.error('Error deleting file:', error);
                    alert('Failed to delete file');
                });
            }
        }
        
        function deleteSelected() {
            if (selectedFiles.size === 0) return;
            
            const fileList = Array.from(selectedFiles).join(', ');
            if (confirm(`Are you sure you want to delete ${selectedFiles.size} file(s)?: ${fileList}`)) {
                const deletePromises = Array.from(selectedFiles).map(path => 
                    fetch(`/api/delete/${encodeURIComponent(path)}`, { method: 'DELETE' })
                );
                
                Promise.all(deletePromises)
                    .then(() => {
                        selectedFiles.clear();
                        loadFiles(currentPath);
                    })
                    .catch(error => {
                        console.error('Error deleting files:', error);
                        alert('Failed to delete some files');
                    });
            }
        }
        
        function uploadFiles(files) {
            for (let file of files) {
                const formData = new FormData();
                formData.append('file', file);
                
                fetch('/api/upload', {
                    method: 'POST',
                    body: formData
                })
                .then(response => response.text())
                .then(() => {
                    loadFiles(currentPath);
                })
                .catch(error => {
                    console.error('Error uploading file:', error);
                    alert(`Failed to upload ${file.name}`);
                });
            }
        }
        
        function createFolder() {
            document.getElementById('folderModal').style.display = 'block';
            document.getElementById('folderName').focus();
        }
        
        function closeFolderModal() {
            document.getElementById('folderModal').style.display = 'none';
            document.getElementById('folderName').value = '';
        }
        
        function confirmCreateFolder() {
            const folderName = document.getElementById('folderName').value.trim();
            if (!folderName) return;
            
            fetch('/api/mkdir', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ name: folderName })
            })
            .then(response => response.text())
            .then(() => {
                closeFolderModal();
                loadFiles(currentPath);
            })
            .catch(error => {
                console.error('Error creating folder:', error);
                alert('Failed to create folder');
            });
        }
        
        function refreshFiles() {
            loadFiles(currentPath);
        }
        
        function navigateTo(path) {
            loadFiles(path);
        }
        
        function updateBreadcrumb() {
            const breadcrumb = document.getElementById('breadcrumb');
            let html = '<a href="#" class="breadcrumb-item" onclick="navigateTo(\\'\\')">🏠 Home</a>';
            
            if (currentPath) {
                const parts = currentPath.split('/').filter(part => part);
                let accumulatedPath = '';
                
                parts.forEach(part => {
                    accumulatedPath += (accumulatedPath ? '/' : '') + part;
                    html += `<span class="breadcrumb-separator">›</span>`;
                    html += `<a href="#" class="breadcrumb-item" onclick="navigateTo('${accumulatedPath}')">${part}</a>`;
                });
            }
            
            breadcrumb.innerHTML = html;
        }
        
        function getFileIcon(filename) {
            const extension = filename.split('.').pop().toLowerCase();
            
            switch (extension) {
                case 'txt': case 'md': case 'readme':
                    return '📄';
                case 'jpg': case 'jpeg': case 'png': case 'gif': case 'bmp':
                    return '🖼️';
                case 'mp4': case 'avi': case 'mov': case 'mkv':
                    return '🎬';
                case 'mp3': case 'wav': case 'aac': case 'm4a':
                    return '🎵';
                case 'pdf':
                    return '📋';
                case 'zip': case 'rar': case '7z': case 'tar':
                    return '📦';
                case 'js': case 'html': case 'css': case 'py': case 'swift':
                    return '💻';
                default:
                    return '📄';
            }
        }
        
        function formatFileSize(bytes) {
            if (bytes === 0) return '0 B';
            const k = 1024;
            const sizes = ['B', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
        }
        
        // Handle modal clicks
        document.getElementById('folderModal').addEventListener('click', function(e) {
            if (e.target === this) {
                closeFolderModal();
            }
        });
        
        // Handle Enter key in folder name input
        document.getElementById('folderName').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                confirmCreateFolder();
            }
        });
    </script>
</body>
</html>
"""
    }
}
