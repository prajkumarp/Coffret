# 📁 Coffret - iOS FTP Server

Transform your iPhone or iPad into a powerful FTP server with a beautiful web interface for seamless file sharing across your local network.

## ✨ Features

- 🚀 **Full FTP Server** - Complete FTP protocol implementation
- 🌐 **Web Interface** - Beautiful, responsive web UI for file management
- 📱 **Native iOS Interface** - Intuitive file browser and server controls
- 📤 **File Upload/Download** - Seamless file transfer capabilities
- 📁 **Folder Management** - Create, delete, and organize folders
- 🔄 **File Operations** - Copy, rename, delete, and share files
- 📊 **Real-time Status** - Live server status and connection info
- 🔒 **Secure** - Local network only, no external dependencies

## 🚀 Quick Start

1. **Launch Coffret** on your iOS device
2. **Configure ports** (defaults: FTP 2121, Web 8080) if needed
3. **Tap "Start Server"** to begin sharing files
4. **Connect from any device** on the same WiFi network using the displayed URLs

## 📡 How to Connect

### 🌐 Web Interface (Recommended)
The easiest way to access your files:
- Open any web browser on your computer or device
- Navigate to the **Web URL** shown in the app (e.g., `http://192.168.1.100:8080`)
- Upload, download, and manage files directly in your browser

### 📁 FTP Connection
For advanced users and FTP clients:
- **Server**: Your device's IP address (shown in app)
- **Port**: 2121 (or your custom port)
- **Username**: Any username (not validated)
- **Password**: Any password (not validated)
- **Mode**: Passive (PASV)

## 💻 Compatible Devices & Clients

### Web Browsers
- Safari, Chrome, Firefox, Edge on any device
- Mobile browsers on phones and tablets

### FTP Clients
- **iOS**: Files app, FTP Client Pro, FileExplorer
- **Android**: Files by Google, AndFTP, Solid Explorer
- **macOS**: Finder (⌘K → Connect to Server)
- **Windows**: File Explorer, FileZilla, WinSCP
- **Linux**: Nautilus, FileZilla, command line FTP

## 📱 Using the App

### Main Interface
- **Server Status**: Shows if server is running and connection URLs
- **Port Settings**: Customize FTP and Web server ports
- **File Browser**: Browse and manage files on your device
- **Server Controls**: Start/stop server with one tap

### File Management
- **Tap folders** to expand/collapse directory tree
- **Long press files** for context menu with operations
- **Import files** from other apps using the share sheet
- **Create folders** and organize your files

## 🔧 Configuration Tips

### Port Settings
- **Default ports work** for most users (FTP: 2121, Web: 8080)
- **Change ports** if you experience conflicts
- **Avoid ports below 1024** (system reserved)

### Network Requirements
- All devices must be on the **same WiFi network**
- Router should allow **local network communication**
- **Disable VPN** on devices if having connection issues

## 🌐 Web Interface Features

- **Drag & Drop Upload** - Simply drag files to upload
- **One-Click Download** - Direct download for any file
- **Folder Creation** - Create new directories instantly
- **File Preview** - Preview images and text files
- **Responsive Design** - Works perfectly on phones, tablets, and computers
- **Real-time Updates** - File list updates automatically

## 🔒 Security & Privacy

- **Local Network Only** - Server only accepts connections from your WiFi network
- **No Internet Access** - Files never leave your local network
- **No Authentication** - Designed for trusted home/office networks
- **Automatic Security** - Server stops when app goes to background
- **Private Files** - Only files in app's Documents folder are accessible

## 🛠 Troubleshooting

### Can't Connect to Server
- ✅ Ensure all devices are on the **same WiFi network**
- ✅ Check that **server is running** (green status in app)
- ✅ Verify the **URL is correct** (copy from app display)
- ✅ Try accessing from a **different device** to isolate the issue
- ✅ **Restart the server** (stop and start again)

### Web Interface Won't Load
- ✅ **Copy the exact URL** from the app (don't type it manually)
- ✅ Try a **different web browser**
- ✅ Check if another app is using the **same port**
- ✅ **Change the web port** in settings and restart server

### Slow File Transfer
- ✅ Move **closer to WiFi router**
- ✅ Close other **network-intensive apps**
- ✅ Use **5GHz WiFi** if available
- ✅ Try **wired connection** on computer if possible

### FTP Client Issues
- ✅ Ensure **Passive (PASV) mode** is enabled
- ✅ Use **port 2121** (or your custom FTP port)
- ✅ Any **username/password** will work (not validated)
- ✅ Try a **different FTP client** if problems persist

## � System Requirements

- **iOS 14.0** or later
- **WiFi connection** for file sharing
- **Local network permission** (automatically requested)

## 💡 Pro Tips

- **Use the web interface** for the best experience across all devices
- **Bookmark the web URL** for quick access from computers
- **Create folders** to organize files before sharing
- **Test with a small file** first when trying new clients
- **Keep the app active** while transferring large files

---

**Start sharing files effortlessly with Coffret! 📁✨**
