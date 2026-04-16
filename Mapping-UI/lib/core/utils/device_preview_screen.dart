import 'package:flutter/material.dart';

/// Màn hình preview ứng dụng trên các kích thước thiết bị khác nhau
class DevicePreviewScreen extends StatefulWidget {
  final Widget child;

  const DevicePreviewScreen({super.key, required this.child});

  @override
  State<DevicePreviewScreen> createState() => _DevicePreviewScreenState();
}

class _DevicePreviewScreenState extends State<DevicePreviewScreen> {
  int _selectedDeviceIndex = 0;
  bool _showDeviceList = false;

  // Danh sách các thiết bị phổ biến
  static const List<DeviceInfo> devices = [
    // iPhone
    DeviceInfo(name: 'iPhone SE', width: 375, height: 667, pixelRatio: 2.0),
    DeviceInfo(name: 'iPhone 8', width: 375, height: 667, pixelRatio: 2.0),
    DeviceInfo(name: 'iPhone 8 Plus', width: 414, height: 736, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone X/XS/11 Pro', width: 375, height: 812, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone XR/11', width: 414, height: 896, pixelRatio: 2.0),
    DeviceInfo(name: 'iPhone XS Max/11 Pro Max', width: 414, height: 896, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone 12 mini', width: 360, height: 780, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone 12/12 Pro', width: 390, height: 844, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone 12 Pro Max', width: 428, height: 926, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone 13 mini', width: 375, height: 812, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone 13/13 Pro', width: 390, height: 844, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone 13 Pro Max', width: 428, height: 926, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone 14', width: 390, height: 844, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone 14 Plus', width: 428, height: 926, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone 14 Pro', width: 393, height: 852, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone 14 Pro Max', width: 430, height: 932, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone 15', width: 393, height: 852, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone 15 Plus', width: 430, height: 932, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone 15 Pro', width: 393, height: 852, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone 15 Pro Max', width: 430, height: 932, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone 16', width: 393, height: 852, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone 16 Pro', width: 402, height: 874, pixelRatio: 3.0),
    DeviceInfo(name: 'iPhone 16 Pro Max', width: 440, height: 956, pixelRatio: 3.0),
    
    // Android phổ biến
    DeviceInfo(name: 'Samsung Galaxy S21', width: 360, height: 800, pixelRatio: 3.0),
    DeviceInfo(name: 'Samsung Galaxy S22', width: 360, height: 780, pixelRatio: 3.0),
    DeviceInfo(name: 'Samsung Galaxy S23', width: 360, height: 780, pixelRatio: 3.0),
    DeviceInfo(name: 'Samsung Galaxy S24', width: 360, height: 780, pixelRatio: 3.0),
    DeviceInfo(name: 'Pixel 6', width: 411, height: 914, pixelRatio: 2.625),
    DeviceInfo(name: 'Pixel 7', width: 411, height: 914, pixelRatio: 2.625),
    DeviceInfo(name: 'Pixel 8', width: 411, height: 914, pixelRatio: 2.75),
    
    // Tablet
    DeviceInfo(name: 'iPad Mini', width: 768, height: 1024, pixelRatio: 2.0),
    DeviceInfo(name: 'iPad Air', width: 820, height: 1180, pixelRatio: 2.0),
    DeviceInfo(name: 'iPad Pro 11"', width: 834, height: 1194, pixelRatio: 2.0),
    DeviceInfo(name: 'iPad Pro 12.9"', width: 1024, height: 1366, pixelRatio: 2.0),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedDevice = devices[_selectedDeviceIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213e),
        leading: isWideScreen ? null : IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            setState(() {
              _showDeviceList = !_showDeviceList;
            });
          },
        ),
        title: Text(
          selectedDevice.name,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          // Previous device
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedDeviceIndex = (_selectedDeviceIndex - 1 + devices.length) % devices.length;
              });
            },
          ),
          // Next device
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedDeviceIndex = (_selectedDeviceIndex + 1) % devices.length;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showDeviceInfoDialog(selectedDevice),
          ),
        ],
      ),
      body: isWideScreen 
          ? _buildWideLayout(selectedDevice)
          : _buildMobileLayout(selectedDevice),
    );
  }

  // Layout cho điện thoại (portrait)
  Widget _buildMobileLayout(DeviceInfo selectedDevice) {
    return Stack(
      children: [
        // Preview Area
        Column(
          children: [
            // Device info bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: const Color(0xFF16213e),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${selectedDevice.width.toInt()}x${selectedDevice.height.toInt()} @${selectedDevice.pixelRatio}x',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_selectedDeviceIndex + 1}/${devices.length}',
                    style: const TextStyle(
                      color: Color(0xFF00B40F),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Device Frame
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! < 0) {
                    // Swipe left -> next
                    setState(() {
                      _selectedDeviceIndex = (_selectedDeviceIndex + 1) % devices.length;
                    });
                  } else if (details.primaryVelocity! > 0) {
                    // Swipe right -> previous
                    setState(() {
                      _selectedDeviceIndex = (_selectedDeviceIndex - 1 + devices.length) % devices.length;
                    });
                  }
                },
                child: Center(
                  child: _buildDeviceFrame(selectedDevice),
                ),
              ),
            ),
          ],
        ),
        
        // Device List Drawer
        if (_showDeviceList)
          GestureDetector(
            onTap: () {
              setState(() {
                _showDeviceList = false;
              });
            },
            child: Container(
              color: Colors.black54,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {}, // Prevent closing when tapping on list
                  child: Container(
                    width: 250,
                    color: const Color(0xFF16213e),
                    child: _buildDeviceListContent(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Layout cho màn hình rộng (desktop/tablet landscape)
  Widget _buildWideLayout(DeviceInfo selectedDevice) {
    return Row(
      children: [
        // Sidebar - Device List
        Container(
          width: 220,
          color: const Color(0xFF16213e),
          child: _buildDeviceListContent(),
        ),
        
        // Preview Area
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Device info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${selectedDevice.name} - ${selectedDevice.width.toInt()}x${selectedDevice.height.toInt()} @${selectedDevice.pixelRatio}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Device Frame
                Expanded(
                  child: Center(
                    child: _buildDeviceFrame(selectedDevice),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceListContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Devices',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              final isSelected = index == _selectedDeviceIndex;
              
              // Add section headers
              Widget? header;
              if (index == 0) {
                header = _buildSectionHeader('iPhone');
              } else if (index == 23) {
                header = _buildSectionHeader('Android');
              } else if (index == 30) {
                header = _buildSectionHeader('Tablet');
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (header != null) header,
                  ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF0f3460),
                    title: Text(
                      device.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      '${device.width.toInt()}x${device.height.toInt()}',
                      style: TextStyle(
                        color: isSelected ? Colors.grey[300] : Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedDeviceIndex = index;
                        _showDeviceList = false;
                      });
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF00B40F),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDeviceFrame(DeviceInfo device) {
    // Scale để vừa màn hình
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 600;
    
    // Điều chỉnh padding dựa theo loại màn hình
    final maxHeight = screenSize.height - (isWideScreen ? 150 : 120);
    final maxWidth = screenSize.width - (isWideScreen ? 260 : 32);
    
    double scale = 1.0;
    if (device.height > maxHeight) {
      scale = maxHeight / device.height;
    }
    if (device.width * scale > maxWidth) {
      scale = maxWidth / device.width;
    }
    scale = scale.clamp(0.2, 1.2);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(40 * scale),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 8 * scale,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32 * scale),
        child: SizedBox(
          width: device.width * scale,
          height: device.height * scale,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(device.width, device.height),
              devicePixelRatio: device.pixelRatio,
              padding: EdgeInsets.only(
                top: device.hasNotch ? 47 : 20,
                bottom: device.hasHomeIndicator ? 34 : 0,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: device.width,
                height: device.height,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeviceInfoDialog(DeviceInfo device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: Text(
          device.name,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Width', '${device.width.toInt()} pts'),
            _buildInfoRow('Height', '${device.height.toInt()} pts'),
            _buildInfoRow('Pixel Ratio', '${device.pixelRatio}x'),
            _buildInfoRow('Resolution', '${(device.width * device.pixelRatio).toInt()}x${(device.height * device.pixelRatio).toInt()} px'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400])),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class DeviceInfo {
  final String name;
  final double width;
  final double height;
  final double pixelRatio;

  const DeviceInfo({
    required this.name,
    required this.width,
    required this.height,
    required this.pixelRatio,
  });

  bool get hasNotch => height > 800 && width < 500;
  bool get hasHomeIndicator => hasNotch;
}
