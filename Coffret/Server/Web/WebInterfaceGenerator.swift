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
    <title>Coffret File Manager</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Helvetica Neue', Arial, sans-serif;
            background: #f2f2f7;
            min-height: 100vh;
            font-size: 13px;
            color: #1d1d1f;
            overflow-x: hidden;
        }
        
        .window {
            background: #ffffff;
            border-radius: 12px;
            box-shadow: 0 10px 50px rgba(0, 0, 0, 0.15);
            margin: 20px auto;
            max-width: 1200px;
            min-height: calc(100vh - 40px);
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }
        
        .titlebar {
            background: linear-gradient(180deg, #f6f6f6 0%, #e8e8e8 100%);
            border-bottom: 1px solid #d0d0d0;
            padding: 12px 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            min-height: 52px;
        }
        
        .traffic-lights {
            display: flex;
            gap: 8px;
        }
        
        .traffic-light {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            border: 0.5px solid rgba(0, 0, 0, 0.1);
        }
        
        .close { background: #ff5f57; }
        .minimize { background: #ffbd2e; }
        .maximize { background: #28ca42; }
        
        .window-title {
            font-weight: 600;
            font-size: 14px;
            color: #1d1d1f;
            position: absolute;
            left: 50%;
            transform: translateX(-50%);
        }
        
        .toolbar {
            background: #f6f6f6;
            border-bottom: 1px solid #e0e0e0;
            padding: 8px 20px;
            display: flex;
            align-items: center;
            gap: 12px;
            flex-wrap: wrap;
        }
        
        .nav-buttons {
            display: flex;
            gap: 4px;
            margin-right: 16px;
        }
        
        .nav-btn {
            width: 28px;
            height: 28px;
            border: none;
            border-radius: 6px;
            background: #ffffff;
            color: #666;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
            transition: all 0.1s;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }
        
        .nav-btn:hover {
            background: #f0f0f0;
            color: #333;
        }
        
        .nav-btn:active {
            transform: scale(0.95);
        }
        
        .nav-btn:disabled {
            opacity: 0.4;
            cursor: not-allowed;
        }
        
        .toolbar-btn {
            background: #ffffff;
            border: 1px solid #d0d0d0;
            border-radius: 6px;
            padding: 6px 12px;
            font-size: 12px;
            font-weight: 500;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 6px;
            transition: all 0.1s;
            color: #1d1d1f;
        }
        
        .toolbar-btn:hover {
            background: #f0f0f0;
            border-color: #b0b0b0;
        }
        
        .toolbar-btn.primary {
            background: #007aff;
            border-color: #007aff;
            color: white;
        }
        
        .toolbar-btn.primary:hover {
            background: #0056cc;
        }
        
        .toolbar-btn.danger {
            background: #ff3b30;
            border-color: #ff3b30;
            color: white;
        }
        
        .toolbar-btn.danger:hover {
            background: #d70015;
        }
        
        .path-bar {
            background: #ffffff;
            border-bottom: 1px solid #e0e0e0;
            padding: 8px 20px;
            display: flex;
            align-items: center;
            font-size: 12px;
        }
        
        .path-item {
            color: #007aff;
            text-decoration: none;
            padding: 4px 8px;
            border-radius: 4px;
            transition: background 0.1s;
        }
        
        .path-item:hover {
            background: #f0f0f0;
        }
        
        .path-separator {
            margin: 0 4px;
            color: #8e8e93;
            font-weight: normal;
        }
        
        .content-area {
            flex: 1;
            display: flex;
            background: #ffffff;
        }
        
        .sidebar {
            width: 200px;
            background: #f8f8f8;
            border-right: 1px solid #e0e0e0;
            padding: 12px 8px;
            flex-shrink: 0;
        }
        
        .sidebar-section {
            margin-bottom: 16px;
        }
        
        .sidebar-title {
            font-size: 11px;
            font-weight: 600;
            color: #8e8e93;
            text-transform: uppercase;
            margin-bottom: 4px;
            padding: 0 12px;
        }
        
        .sidebar-item {
            display: flex;
            align-items: center;
            padding: 6px 12px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 13px;
            transition: background 0.1s;
            margin-bottom: 1px;
        }
        
        .sidebar-item:hover {
            background: #e8e8e8;
        }
        
        .sidebar-item.active {
            background: #007aff;
            color: white;
        }
        
        .sidebar-icon {
            margin-right: 8px;
            font-size: 16px;
        }
        
        .main-view {
            flex: 1;
            display: flex;
            flex-direction: column;
        }
        
        .view-header {
            background: #fafafa;
            border-bottom: 1px solid #e0e0e0;
            padding: 8px 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 12px;
            color: #8e8e93;
        }
        
        .view-options {
            display: flex;
            gap: 12px;
            align-items: center;
        }
        
        .view-toggle {
            background: none;
            border: none;
            padding: 4px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
            color: #8e8e93;
            transition: all 0.1s;
        }
        
        .view-toggle:hover {
            background: #e8e8e8;
            color: #1d1d1f;
        }
        
        .view-toggle.active {
            background: #007aff;
            color: white;
        }
        
        .file-list {
            flex: 1;
            overflow-y: auto;
        }
        
        .file-item {
            display: flex;
            align-items: center;
            padding: 8px 20px;
            border-bottom: 1px solid #f0f0f0;
            cursor: pointer;
            transition: background 0.1s;
            position: relative;
        }
        
        .file-item:hover {
            background: #f8f8f8;
        }
        
        .file-item.selected {
            background: #007aff;
            color: white;
        }
        
        .file-item.selected .file-name,
        .file-item.selected .file-info {
            color: white;
        }
        
        .file-icon {
            width: 32px;
            height: 32px;
            margin-right: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            flex-shrink: 0;
        }
        
        .file-details {
            flex: 1;
            min-width: 0;
        }
        
        .file-name {
            font-size: 13px;
            font-weight: 500;
            color: #1d1d1f;
            margin-bottom: 2px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        
        .file-info {
            font-size: 11px;
            color: #8e8e93;
            display: flex;
            gap: 16px;
        }
        
        .file-actions {
            display: flex;
            gap: 4px;
            opacity: 0;
            transition: opacity 0.2s;
        }
        
        .file-item:hover .file-actions {
            opacity: 1;
        }
        
        .action-btn {
            width: 24px;
            height: 24px;
            border: none;
            border-radius: 4px;
            background: none;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 14px;
            color: #8e8e93;
            transition: all 0.1s;
        }
        
        .action-btn:hover {
            background: rgba(0, 0, 0, 0.05);
            color: #1d1d1f;
        }
        
        .file-item.selected .action-btn {
            color: rgba(255, 255, 255, 0.8);
        }
        
        .file-item.selected .action-btn:hover {
            background: rgba(255, 255, 255, 0.1);
            color: white;
        }
        
        .grid-view .file-list {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
            gap: 16px;
            padding: 20px;
        }
        
        .grid-view .file-item {
            flex-direction: column;
            padding: 16px 12px;
            border: none;
            border-radius: 8px;
            text-align: center;
            min-height: 120px;
        }
        
        .grid-view .file-icon {
            margin: 0 0 8px 0;
            font-size: 32px;
        }
        
        .grid-view .file-details {
            width: 100%;
        }
        
        .grid-view .file-name {
            text-align: center;
            font-size: 12px;
            line-height: 1.2;
            white-space: normal;
            overflow: hidden;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
        }
        
        .grid-view .file-info {
            justify-content: center;
            margin-top: 4px;
        }
        
        .grid-view .file-actions {
            position: absolute;
            top: 4px;
            right: 4px;
            opacity: 0;
        }
        
        .loading {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 60px 20px;
            color: #8e8e93;
        }
        
        .spinner {
            width: 20px;
            height: 20px;
            border: 2px solid #e0e0e0;
            border-radius: 50%;
            border-top-color: #007aff;
            animation: spin 1s linear infinite;
            margin-bottom: 12px;
        }
        
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        
        .empty-state {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 60px 20px;
            color: #8e8e93;
            text-align: center;
        }
        
        .empty-icon {
            font-size: 48px;
            margin-bottom: 16px;
            opacity: 0.5;
        }
        
        .upload-progress {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            background: rgba(0, 0, 0, 0.9);
            color: white;
            padding: 20px 40px;
            z-index: 2000;
            display: none;
            backdrop-filter: blur(10px);
        }
        
        .progress-content {
            max-width: 400px;
            margin: 0 auto;
            text-align: center;
        }
        
        .progress-bar {
            width: 100%;
            height: 4px;
            background: rgba(255, 255, 255, 0.2);
            border-radius: 2px;
            overflow: hidden;
            margin: 12px 0;
        }
        
        .progress-fill {
            height: 100%;
            background: #007aff;
            width: 0%;
            transition: width 0.3s ease;
        }
        
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.4);
            backdrop-filter: blur(5px);
        }
        
        .modal-content {
            background: white;
            margin: 15% auto;
            padding: 24px;
            border-radius: 12px;
            width: 90%;
            max-width: 400px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
        }
        
        .modal h3 {
            font-size: 16px;
            font-weight: 600;
            margin-bottom: 16px;
            color: #1d1d1f;
        }
        
        .modal input {
            width: 100%;
            padding: 12px;
            border: 1px solid #d0d0d0;
            border-radius: 8px;
            font-size: 14px;
            font-family: inherit;
            transition: border-color 0.2s;
        }
        
        .modal input:focus {
            outline: none;
            border-color: #007aff;
            box-shadow: 0 0 0 3px rgba(0, 122, 255, 0.1);
        }
        
        .modal-actions {
            display: flex;
            justify-content: flex-end;
            gap: 12px;
            margin-top: 20px;
        }
        
        .modal-btn {
            padding: 8px 16px;
            border: 1px solid #d0d0d0;
            border-radius: 6px;
            background: white;
            cursor: pointer;
            font-size: 13px;
            font-weight: 500;
            transition: all 0.1s;
        }
        
        .modal-btn.primary {
            background: #007aff;
            border-color: #007aff;
            color: white;
        }
        
        .modal-btn:hover {
            background: #f0f0f0;
        }
        
        .modal-btn.primary:hover {
            background: #0056cc;
        }
        
        .file-upload {
            display: none;
        }
        
        @media (max-width: 768px) {
            .window {
                margin: 0;
                border-radius: 0;
                min-height: 100vh;
            }
            
            .sidebar {
                display: none;
            }
            
            .toolbar {
                flex-wrap: wrap;
                gap: 8px;
            }
            
            .nav-buttons {
                margin-right: 8px;
            }
            
            .grid-view .file-list {
                grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
                gap: 12px;
                padding: 16px;
            }
        }
    </style>
</head>
<body>
    <div class="window">
        <div class="titlebar">
            <div class="window-title">Coffret</div>
        </div>
        
        <div class="toolbar">
            <div class="nav-buttons">
                <button class="nav-btn" onclick="navigateBack()" id="backBtn" disabled>⬅</button>
                <button class="nav-btn" onclick="navigateForward()" id="forwardBtn" disabled>➡</button>
            </div>
            
            <input type="file" id="fileInput" class="file-upload" multiple>
            <button class="toolbar-btn primary" onclick="document.getElementById('fileInput').click();">
                <span>⬆</span> Upload
            </button>
            <button class="toolbar-btn" onclick="createFolder()">
                <span>📁</span> New Folder
            </button>
            <button class="toolbar-btn" onclick="refreshFiles()">
                <span>↻</span> Refresh
            </button>
            <button class="toolbar-btn danger" onclick="deleteSelected()" id="deleteBtn" style="display: none;">
                <span>🗑</span> Delete
            </button>
        </div>
        
        <div class="path-bar" id="pathBar">
            <a href="#" class="path-item" onclick="navigateTo('')">Coffret</a>
        </div>
        
        <div class="content-area">
            <div class="sidebar">
                <div class="sidebar-section">
                    <div class="sidebar-title">Favorites</div>
                    <div class="sidebar-item active" onclick="navigateTo('')">
                        <span class="sidebar-icon">🏠</span>
                        Home
                    </div>
                </div>
                
                <div class="sidebar-section">
                    <div class="sidebar-title">Categories</div>
                    <div class="sidebar-item" onclick="filterByType('image')">
                        <span class="sidebar-icon">🖼</span>
                        Images
                    </div>
                    <div class="sidebar-item" onclick="filterByType('document')">
                        <span class="sidebar-icon">📄</span>
                        Documents
                    </div>
                    <div class="sidebar-item" onclick="filterByType('video')">
                        <span class="sidebar-icon">🎬</span>
                        Videos
                    </div>
                    <div class="sidebar-item" onclick="filterByType('audio')">
                        <span class="sidebar-icon">🎵</span>
                        Audio
                    </div>
                </div>
            </div>
            
            <div class="main-view">
                <div class="view-header">
                    <div class="file-count" id="fileCount">Loading...</div>
                    <div class="view-options">
                        <button class="view-toggle active" onclick="toggleView('list')" id="listViewBtn">☰</button>
                        <button class="view-toggle" onclick="toggleView('grid')" id="gridViewBtn">⊞</button>
                    </div>
                </div>
                
                <div class="file-list" id="fileList">
                    <div class="loading">
                        <div class="spinner"></div>
                        <p>Loading files...</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div id="uploadProgress" class="upload-progress">
        <div class="progress-content">
            <div id="uploadProgressText">Preparing upload...</div>
            <div class="progress-bar">
                <div class="progress-fill" id="uploadProgressBar"></div>
            </div>
        </div>
    </div>
    
    <div id="folderModal" class="modal">
        <div class="modal-content">
            <h3>New Folder</h3>
            <input type="text" id="folderName" placeholder="Untitled folder">
            <div class="modal-actions">
                <button class="modal-btn" onclick="closeFolderModal()">Cancel</button>
                <button class="modal-btn primary" onclick="confirmCreateFolder()">Create</button>
            </div>
        </div>
    </div>
    
    <script>
        let currentPath = '';
        let selectedFiles = new Set();
        let navigationHistory = [''];
        let historyIndex = 0;
        let currentView = 'list';
        let fileFilter = null;
        
        // Initialize
        document.addEventListener('DOMContentLoaded', function() {
            console.log('DOM Content Loaded - Initializing Finder-style interface');
            loadFiles();
            
            // File upload handler
            const fileInput = document.getElementById('fileInput');
            console.log('File input element:', fileInput);
            
            fileInput.addEventListener('change', function(e) {
                console.log('File input change event triggered');
                console.log('Selected files:', e.target.files);
                console.log('Number of files:', e.target.files.length);
                
                if (e.target.files.length > 0) {
                    for (let i = 0; i < e.target.files.length; i++) {
                        console.log(`File ${i}:`, e.target.files[i].name, e.target.files[i].size, 'bytes');
                    }
                    uploadFiles(e.target.files);
                } else {
                    console.log('No files selected');
                }
            });
        });
        
        function loadFiles(path = '') {
            currentPath = path;
            updatePathBar();
            updateNavigationButtons();
            clearSelection();
            
            fetch(`/api/files${path ? '/' + encodeURIComponent(path) : ''}`)
                .then(response => response.json())
                .then(files => {
                    displayFiles(files);
                    updateFileCount(files.length);
                })
                .catch(error => {
                    console.error('Error loading files:', error);
                    document.getElementById('fileList').innerHTML = '<div class="loading"><p>Error loading files</p></div>';
                });
        }
        
        function displayFiles(files) {
            const fileList = document.getElementById('fileList');
            
            // Filter files if a filter is active
            let filteredFiles = files;
            if (fileFilter) {
                filteredFiles = files.filter(file => {
                    if (file.isDirectory) return true; // Always show directories
                    return getFileCategory(file.name) === fileFilter;
                });
            }
            
            if (filteredFiles.length === 0) {
                fileList.innerHTML = `
                    <div class="empty-state">
                        <div class="empty-icon">📂</div>
                        <p>${fileFilter ? `No ${fileFilter} files found` : 'This folder is empty'}</p>
                    </div>
                `;
                return;
            }
            
            // Sort files: directories first, then by name
            filteredFiles.sort((a, b) => {
                if (a.isDirectory && !b.isDirectory) return -1;
                if (!a.isDirectory && b.isDirectory) return 1;
                return a.name.localeCompare(b.name);
            });
            
            let html = '';
            
            filteredFiles.forEach(file => {
                const icon = file.isDirectory ? '📁' : getFileIcon(file.name);
                const size = file.isDirectory ? '' : formatFileSize(file.size);
                const path = file.path.startsWith('/') ? file.path.substring(1) : file.path;
                const modDate = file.modified ? formatDate(new Date(file.modified)) : '';
                
                html += `
                    <div class="file-item" onclick="selectFile('${path}', ${file.isDirectory})" data-path="${path}" ondblclick="openFile('${path}', ${file.isDirectory})">
                        <div class="file-icon">${icon}</div>
                        <div class="file-details">
                            <div class="file-name">${file.name}</div>
                            <div class="file-info">
                                ${size ? `<span>${size}</span>` : ''}
                                ${modDate ? `<span>${modDate}</span>` : ''}
                            </div>
                        </div>
                        <div class="file-actions">
                            ${!file.isDirectory ? `<button class="action-btn" onclick="event.stopPropagation(); downloadFile('${path}')" title="Download">↓</button>` : ''}
                            <button class="action-btn" onclick="event.stopPropagation(); deleteFile('${path}')" title="Delete">🗑</button>
                        </div>
                    </div>
                `;
            });
            
            fileList.innerHTML = html;
        }
        
        function selectFile(path, isDirectory) {
            const fileItem = document.querySelector(`[data-path="${path}"]`);
            
            if (selectedFiles.has(path)) {
                selectedFiles.delete(path);
                fileItem.classList.remove('selected');
            } else {
                selectedFiles.add(path);
                fileItem.classList.add('selected');
            }
            
            updateDeleteButton();
        }
        
        function openFile(path, isDirectory) {
            if (isDirectory) {
                navigateTo(path);
            } else {
                downloadFile(path);
            }
        }
        
        function navigateTo(path) {
            // Add to history if navigating to a new path
            if (path !== currentPath) {
                navigationHistory = navigationHistory.slice(0, historyIndex + 1);
                navigationHistory.push(path);
                historyIndex = navigationHistory.length - 1;
            }
            
            // Clear any active filter when navigating
            fileFilter = null;
            updateSidebarSelection();
            
            loadFiles(path);
        }
        
        function navigateBack() {
            if (historyIndex > 0) {
                historyIndex--;
                loadFiles(navigationHistory[historyIndex]);
            }
        }
        
        function navigateForward() {
            if (historyIndex < navigationHistory.length - 1) {
                historyIndex++;
                loadFiles(navigationHistory[historyIndex]);
            }
        }
        
        function updateNavigationButtons() {
            document.getElementById('backBtn').disabled = historyIndex <= 0;
            document.getElementById('forwardBtn').disabled = historyIndex >= navigationHistory.length - 1;
        }
        
        function toggleView(viewType) {
            currentView = viewType;
            const fileList = document.getElementById('fileList');
            const listBtn = document.getElementById('listViewBtn');
            const gridBtn = document.getElementById('gridViewBtn');
            
            if (viewType === 'grid') {
                fileList.parentElement.classList.add('grid-view');
                listBtn.classList.remove('active');
                gridBtn.classList.add('active');
            } else {
                fileList.parentElement.classList.remove('grid-view');
                listBtn.classList.add('active');
                gridBtn.classList.remove('active');
            }
        }
        
        function filterByType(type) {
            fileFilter = type;
            updateSidebarSelection(type);
            loadFiles(currentPath);
        }
        
        function updateSidebarSelection(activeFilter = null) {
            const sidebarItems = document.querySelectorAll('.sidebar-item');
            sidebarItems.forEach(item => {
                item.classList.remove('active');
            });
            
            if (!activeFilter) {
                // Highlight home
                sidebarItems[0].classList.add('active');
            } else {
                // Find and highlight the filter item
                sidebarItems.forEach(item => {
                    if (item.textContent.trim().toLowerCase().includes(activeFilter)) {
                        item.classList.add('active');
                    }
                });
            }
        }
        
        function clearSelection() {
            selectedFiles.clear();
            document.querySelectorAll('.file-item.selected').forEach(item => {
                item.classList.remove('selected');
            });
            updateDeleteButton();
        }
        
        function updateDeleteButton() {
            const deleteBtn = document.getElementById('deleteBtn');
            deleteBtn.style.display = selectedFiles.size > 0 ? 'inline-block' : 'none';
        }
        
        function updateFileCount(count) {
            const fileCount = document.getElementById('fileCount');
            if (count === 0) {
                fileCount.textContent = 'No items';
            } else if (count === 1) {
                fileCount.textContent = '1 item';
            } else {
                fileCount.textContent = `${count} items`;
            }
        }
        
        function updatePathBar() {
            const pathBar = document.getElementById('pathBar');
            let html = '<a href="#" class="path-item" onclick="navigateTo(\\'\\')">Coffret</a>';
            
            if (currentPath) {
                const parts = currentPath.split('/').filter(part => part);
                let accumulatedPath = '';
                
                parts.forEach(part => {
                    accumulatedPath += (accumulatedPath ? '/' : '') + part;
                    html += `<span class="path-separator">›</span>`;
                    html += `<a href="#" class="path-item" onclick="navigateTo('${accumulatedPath}')">${part}</a>`;
                });
            }
            
            pathBar.innerHTML = html;
        }
        
        function downloadFile(path) {
            console.log('Download requested for path:', path);
            
            const fileName = path.split('/').pop();
            const downloadUrl = `/download/${encodeURIComponent(fileName)}`;
            console.log('Download URL:', downloadUrl);
            console.log('Filename:', fileName);
            
            fetch(downloadUrl)
                .then(response => {
                    console.log('Download response status:', response.status);
                    if (!response.ok) {
                        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                    }
                    return response.blob();
                })
                .then(blob => {
                    console.log('Download blob received, size:', blob.size);
                    const url = window.URL.createObjectURL(blob);
                    const a = document.createElement('a');
                    a.href = url;
                    a.download = fileName;
                    document.body.appendChild(a);
                    a.click();
                    window.URL.revokeObjectURL(url);
                    document.body.removeChild(a);
                    console.log('Download completed');
                })
                .catch(error => {
                    console.error('Download failed:', error);
                    window.open(downloadUrl, '_blank');
                });
        }
        
        function deleteFile(path) {
            if (confirm(`Are you sure you want to move "${path.split('/').pop()}" to the trash?`)) {
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
            
            const fileNames = Array.from(selectedFiles).map(path => path.split('/').pop()).join(', ');
            if (confirm(`Are you sure you want to move ${selectedFiles.size} item(s) to the trash?\\n\\n${fileNames}`)) {
                const deletePromises = Array.from(selectedFiles).map(path => 
                    fetch(`/api/delete/${encodeURIComponent(path)}`, { method: 'DELETE' })
                );
                
                Promise.all(deletePromises)
                    .then(() => {
                        clearSelection();
                        loadFiles(currentPath);
                    })
                    .catch(error => {
                        console.error('Error deleting files:', error);
                        alert('Failed to delete some files');
                    });
            }
        }
        
        function uploadFiles(files) {
            console.log('uploadFiles function called with:', files);
            
            if (!files || files.length === 0) {
                console.log('No files to upload, returning early');
                return;
            }
            
            console.log(`Starting upload of ${files.length} files`);
            
            const progressOverlay = document.getElementById('uploadProgress');
            const progressBarFill = document.getElementById('uploadProgressBar');
            const progressText = document.getElementById('uploadProgressText');
            
            progressOverlay.style.display = 'block';
            let completedUploads = 0;
            const totalFiles = files.length;
            
            function updateProgress() {
                const percentage = Math.round((completedUploads / totalFiles) * 100);
                progressBarFill.style.width = percentage + '%';
                progressText.textContent = `Uploading ${completedUploads} of ${totalFiles} files (${percentage}%)`;
            }
            
            updateProgress();
            
            async function uploadFile(file) {
                console.log(`Starting upload for file: ${file.name} (${file.size} bytes)`);
                
                const formData = new FormData();
                formData.append('file', file);
                formData.append('path', currentPath);
                
                try {
                    const response = await fetch('/api/upload', {
                        method: 'POST',
                        body: formData
                    });
                    
                    if (!response.ok) {
                        const errorText = await response.text();
                        throw new Error(`HTTP ${response.status}: ${errorText}`);
                    }
                    
                    completedUploads++;
                    updateProgress();
                    return true;
                } catch (error) {
                    console.error('Error uploading file:', error);
                    alert(`Failed to upload ${file.name}: ${error.message}`);
                    completedUploads++;
                    updateProgress();
                    return false;
                }
            }
            
            (async () => {
                try {
                    for (let i = 0; i < files.length; i++) {
                        await uploadFile(files[i]);
                        if (i < files.length - 1) {
                            await new Promise(resolve => setTimeout(resolve, 100));
                        }
                    }
                } finally {
                    setTimeout(() => {
                        progressOverlay.style.display = 'none';
                        progressBarFill.style.width = '0%';
                        loadFiles(currentPath);
                    }, 1000);
                }
            })();
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
                body: JSON.stringify({ 
                    name: folderName,
                    path: currentPath 
                })
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
        
        function getFileIcon(filename) {
            const extension = filename.split('.').pop().toLowerCase();
            
            switch (extension) {
                case 'txt': case 'md': case 'readme': case 'rtf':
                    return '📄';
                case 'jpg': case 'jpeg': case 'png': case 'gif': case 'bmp': case 'svg': case 'webp':
                    return '🖼';
                case 'mp4': case 'avi': case 'mov': case 'mkv': case 'webm': case 'm4v':
                    return '🎬';
                case 'mp3': case 'wav': case 'aac': case 'm4a': case 'flac': case 'ogg':
                    return '🎵';
                case 'pdf':
                    return '📕';
                case 'doc': case 'docx':
                    return '📘';
                case 'xls': case 'xlsx':
                    return '📗';
                case 'ppt': case 'pptx':
                    return '📙';
                case 'zip': case 'rar': case '7z': case 'tar': case 'gz':
                    return '📦';
                case 'js': case 'html': case 'css': case 'py': case 'swift': case 'java': case 'cpp': case 'c':
                    return '💻';
                case 'dmg': case 'pkg': case 'app':
                    return '📱';
                default:
                    return '📄';
            }
        }
        
        function getFileCategory(filename) {
            const extension = filename.split('.').pop().toLowerCase();
            
            if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg', 'webp'].includes(extension)) {
                return 'image';
            } else if (['mp4', 'avi', 'mov', 'mkv', 'webm', 'm4v'].includes(extension)) {
                return 'video';
            } else if (['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg'].includes(extension)) {
                return 'audio';
            } else {
                return 'document';
            }
        }
        
        function formatFileSize(bytes) {
            if (bytes === 0) return '0 bytes';
            const k = 1000;
            const sizes = ['bytes', 'KB', 'MB', 'GB', 'TB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
        }
        
        function formatDate(date) {
            const now = new Date();
            const diff = now - date;
            const days = Math.floor(diff / (1000 * 60 * 60 * 24));
            
            if (days === 0) {
                return 'Today';
            } else if (days === 1) {
                return 'Yesterday';
            } else if (days < 7) {
                return `${days} days ago`;
            } else {
                return date.toLocaleDateString();
            }
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
        
        // Handle keyboard shortcuts
        document.addEventListener('keydown', function(e) {
            if (e.metaKey || e.ctrlKey) {
                switch(e.key) {
                    case 'a':
                        e.preventDefault();
                        // Select all files
                        document.querySelectorAll('.file-item').forEach(item => {
                            const path = item.getAttribute('data-path');
                            selectedFiles.add(path);
                            item.classList.add('selected');
                        });
                        updateDeleteButton();
                        break;
                    case 'Backspace':
                        e.preventDefault();
                        deleteSelected();
                        break;
                }
            } else if (e.key === 'Escape') {
                clearSelection();
                closeFolderModal();
            }
        });
    </script>
</body>
</html>
"""
    }
}
