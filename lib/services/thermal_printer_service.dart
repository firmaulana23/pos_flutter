import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

class ThermalPrinterService {
  static BluetoothDevice? _connectedDevice;
  static BluetoothCharacteristic? _writeCharacteristic;
  static bool _isConnected = false;
  static String? _connectedDeviceAddress;

  // Common service UUIDs for thermal printers
  static const String _thermalPrinterServiceUuid = "000018f0-0000-1000-8000-00805f9b34fb";
  static const String _thermalPrinterCharacteristicUuid = "00002af1-0000-1000-8000-00805f9b34fb";

  static const _storage = FlutterSecureStorage();
  static const _printerKey = 'bluetooth_printer_id';

  // Get available Bluetooth devices
  static Future<List<ScanResult>> getAvailableDevices() async {
    try {
      // Request Bluetooth permissions
      bool permissionsGranted = await _requestBluetoothPermissions();
      if (!permissionsGranted) {
        debugPrint("Bluetooth permissions not granted");
        return [];
      }
      
      // Check if Bluetooth is supported
      if (await FlutterBluePlus.isSupported == false) {
        debugPrint("Bluetooth not supported by this device");
        return [];
      }
      
      // Check if Bluetooth is enabled
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        debugPrint("Bluetooth is not enabled");
        return [];
      }
      
      List<ScanResult> results = [];
      
      // Listen to scan results
      FlutterBluePlus.scanResults.listen((scanResults) {
        results = scanResults;
        debugPrint('Found ${scanResults.length} Bluetooth devices');
      });
      
      // Start scanning
      debugPrint('Starting Bluetooth scan...');
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      
      // Wait a bit for results to come in
      await Future.delayed(const Duration(seconds: 5));
      
      // Stop scanning
      await FlutterBluePlus.stopScan();
      
      return results;
    } catch (e) {
      debugPrint('Error getting Bluetooth devices: $e');
      return [];
    }
  }

  // Request necessary permissions for Bluetooth
  static Future<bool> _requestBluetoothPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      bool allGranted = true;
      statuses.forEach((permission, status) {
        debugPrint('Permission $permission: $status');
        if (status != PermissionStatus.granted) {
          allGranted = false;
        }
      });

      if (!allGranted) {
        debugPrint('Some Bluetooth permissions were denied');
      }

      return allGranted;
    } catch (e) {
      debugPrint('Error requesting Bluetooth permissions: $e');
      return false;
    }
  }

  // Connect to a Bluetooth printer
  static Future<bool> connectToPrinter(String deviceId) async {
    try {
      // Find the device by its ID
      List<ScanResult> scanResults = await getAvailableDevices();
      BluetoothDevice? targetDevice;
      
      for (ScanResult result in scanResults) {
        if (result.device.platformName == deviceId || result.device.remoteId.toString() == deviceId) {
          targetDevice = result.device;
          break;
        }
      }
      
      if (targetDevice == null) {
        debugPrint('Device not found: $deviceId');
        return false;
      }
      
      // Connect to the device
      await targetDevice.connect();
      
      // Discover services
      List<BluetoothService> services = await targetDevice.discoverServices();
      
      // Find the write characteristic
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            _writeCharacteristic = characteristic;
            break;
          }
        }
        if (_writeCharacteristic != null) break;
      }
      
      if (_writeCharacteristic != null) {
        _connectedDevice = targetDevice;
        _isConnected = true;
        _connectedDeviceAddress = deviceId;
        await _storage.write(key: _printerKey, value: deviceId); // Save printer config
        debugPrint('Connected to printer: $deviceId');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error connecting to printer: $e');
      return false;
    }
  }

  static Future<void> tryReconnectPrinter() async {
    final savedId = await _storage.read(key: _printerKey);
    if (savedId != null && savedId.isNotEmpty && !_isConnected) {
      await connectToPrinter(savedId);
    }
  }

  // Disconnect from printer
  static Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _writeCharacteristic = null;
      }
      _isConnected = false;
      _connectedDeviceAddress = null;
      debugPrint('Disconnected from printer');
    } catch (e) {
      debugPrint('Error disconnecting from printer: $e');
    }
  }

  // Check if printer is connected
  static bool get isConnected => _isConnected;
  static String? get connectedDeviceAddress => _connectedDeviceAddress;

  // Helper method to write data in chunks to avoid BLE data size limits
  static Future<bool> _writeDataInChunks(Uint8List data) async {
    try {
      const int maxChunkSize = 400; // Conservative chunk size for better compatibility
      
      debugPrint('Writing ${data.length} bytes in chunks of $maxChunkSize bytes');
      
      for (int i = 0; i < data.length; i += maxChunkSize) {
        int end = (i + maxChunkSize < data.length) ? i + maxChunkSize : data.length;
        Uint8List chunk = data.sublist(i, end);
        
        debugPrint('Writing chunk ${(i ~/ maxChunkSize) + 1}: ${chunk.length} bytes');
        await _writeCharacteristic!.write(chunk, withoutResponse: true);
        
        // Delay between chunks to ensure proper transmission
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      debugPrint('All chunks written successfully');
      return true;
    } catch (e) {
      debugPrint('Error writing data in chunks: $e');
      return false;
    }
  }

  // Open cash drawer
  static Future<bool> openCashDrawer() async {
    try {
      if (!_isConnected || _writeCharacteristic == null) {
        debugPrint('Printer not connected - cannot open cash drawer');
        return false;
      }

      // ESC/POS command to open cash drawer
      // ESC p m t1 t2 - Open cash drawer
      // m = pin number (usually 0 or 1)
      // t1 = pulse ON time (2-255, in units of 2ms)
      // t2 = pulse OFF time (1-255, in units of 2ms)
      List<int> openDrawerCommand = [
        0x1B, 0x70, 0x00, 0x19, 0x19, // ESC p 0 25 25 (standard command)
      ];

      // Alternative command for some cash drawers
      List<int> alternativeCommand = [
        0x1B, 0x70, 0x01, 0x19, 0x19, // ESC p 1 25 25
      ];

      debugPrint('Sending cash drawer open command...');
      
      // Try primary command first
      await _writeCharacteristic!.write(Uint8List.fromList(openDrawerCommand), withoutResponse: true);
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Try alternative command for better compatibility
      await _writeCharacteristic!.write(Uint8List.fromList(alternativeCommand), withoutResponse: true);
      await Future.delayed(const Duration(milliseconds: 200));
      
      debugPrint('Cash drawer open command sent successfully');
      return true;
    } catch (e) {
      debugPrint('Error opening cash drawer: $e');
      return false;
    }
  }

  // Print receipt for a transaction
  static Future<bool> printReceipt(Transaction transaction, {bool openDrawer = true}) async {
    try {
      if (!_isConnected || _writeCharacteristic == null) {
        debugPrint('Printer not connected');
        return false;
      }

      // Generate receipt content
      Uint8List receiptData = await _generateReceipt(transaction, openDrawer: openDrawer);
      
      debugPrint('Receipt data size: ${receiptData.length} bytes');
      
      // Print the receipt by writing data in chunks
      bool success = await _writeDataInChunks(receiptData);
      
      if (success) {
        debugPrint('Receipt printed successfully');
        
        // Open cash drawer after successful receipt printing if requested
        if (openDrawer) {
          debugPrint('Opening cash drawer after receipt printing...');
          await Future.delayed(const Duration(milliseconds: 500)); // Wait for receipt to finish
          await openCashDrawer();
        }
        
        return true;
      } else {
        debugPrint('Failed to print receipt');
        return false;
      }
    } catch (e) {
      debugPrint('Error printing receipt: $e');
      return false;
    }
  }

  // Generate receipt content using ESC/POS commands
  static Future<Uint8List> _generateReceipt(Transaction transaction, {bool openDrawer = true}) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text(
      'ZONA12 COFFEE',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
        bold: true,
      ),
    );
    
    bytes += generator.text(
      'Jl. Permana Utara No. 122',
      styles: const PosStyles(align: PosAlign.center),
    );
    
    bytes += generator.text(
      'Tel: 085258179632',
      styles: const PosStyles(align: PosAlign.center),
    );
    
    bytes += generator.hr();
    
    // Transaction info
    bytes += generator.row([
      PosColumn(
        text: 'No. Transaksi:',
        width: 6,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: transaction.transactionNo ?? AppFormatters.formatTransactionId(transaction.id!),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    
    bytes += generator.row([
      PosColumn(
        text: 'Pelanggan:',
        width: 6,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: transaction.customerName,
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    
    bytes += generator.row([
      PosColumn(
        text: 'Tanggal:',
        width: 6,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: AppFormatters.formatDateTime(transaction.createdAt),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    
    if (transaction.paymentMethod != null && transaction.paymentMethod!.isNotEmpty) {
      bytes += generator.row([
        PosColumn(
          text: 'Pembayaran:',
          width: 6,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: _getPaymentMethodName(transaction.paymentMethod!),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    
    bytes += generator.hr();
    
    // Items header
    bytes += generator.text(
      'ITEM PESANAN',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
      ),
    );
    
    bytes += generator.hr(ch: '=');
    
    // Items
    for (var item in transaction.items) {
      // Item name and quantity
      bytes += generator.row([
        PosColumn(
          text: item.menuItem?.name ?? 'Menu Item',
          width: 8,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: '${item.quantity}x',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      
      // Item price and subtotal
      bytes += generator.row([
        PosColumn(
          text: AppFormatters.formatCurrency(item.price),
          width: 8,
        ),
        PosColumn(
          text: AppFormatters.formatCurrency(item.subtotal),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      
      // Add-ons if any
      for (var addOn in item.addOns) {
        bytes += generator.row([
          PosColumn(
            text: '  + ${addOn.addOn?.name ?? 'Add-on'} (${addOn.quantity}x)',
            width: 8,
          ),
          PosColumn(
            text: AppFormatters.formatCurrency(addOn.totalPrice),
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
      
      bytes += generator.emptyLines(1);
    }
    
    bytes += generator.hr(ch: '=');
    
    // Totals
    bytes += generator.row([
      PosColumn(
        text: 'Sub Total:',
        width: 8,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: AppFormatters.formatCurrency(transaction.subTotal),
        width: 4,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    
    if (transaction.tax > 0) {
      bytes += generator.row([
        PosColumn(
          text: 'Pajak:',
          width: 8,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: AppFormatters.formatCurrency(transaction.tax),
          width: 4,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
    }
    
    if (transaction.discount > 0) {
      bytes += generator.row([
        PosColumn(
          text: 'Diskon:',
          width: 8,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: '- ${AppFormatters.formatCurrency(transaction.discount)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
    }
    
    // Uang Diterima & Kembalian
    if (transaction.extra != null && transaction.extra is Map) {
      final extra = transaction.extra as Map;
      if (extra['uangDiterima'] != null) {
        bytes += generator.row([
          PosColumn(
            text: 'Uang Diterima:',
            width: 8,
            styles: const PosStyles(bold: true),
          ),
          PosColumn(
            text: AppFormatters.formatCurrency(extra['uangDiterima'] as double),
            width: 4,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ]);
      }
      if (extra['kembalian'] != null) {
        bytes += generator.row([
          PosColumn(
            text: 'Kembalian:',
            width: 8,
            styles: const PosStyles(bold: true),
          ),
          PosColumn(
            text: AppFormatters.formatCurrency(extra['kembalian'] as double),
            width: 4,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ]);
      }
    }
    
    bytes += generator.hr();
    
    bytes += generator.row([
      PosColumn(
        text: 'TOTAL:',
        width: 8,
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size1,
        ),
      ),
      PosColumn(
        text: AppFormatters.formatCurrency(transaction.total),
        width: 4,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size1,
        ),
      ),
    ]);
    
    bytes += generator.hr();
    
    // Footer
    bytes += generator.text(
      'Terima kasih atas kunjungannya',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    
    bytes += generator.text(
      'Selamat menikmati',
      styles: const PosStyles(align: PosAlign.center),
    );
    
    bytes += generator.emptyLines(1);
    
    bytes += generator.text(
      'wifi: ZONA12_COFFEE',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'pass: zona12kopi',
      styles: const PosStyles(align: PosAlign.center),
    );
    
    // Cut paper
    bytes += generator.cut();
    
    // Add cash drawer open command at the end if requested
    if (openDrawer) {
      // ESC/POS command to open cash drawer embedded in receipt
      bytes += [0x1B, 0x70, 0x00, 0x19, 0x19]; // ESC p 0 25 25
      bytes += [0x1B, 0x70, 0x01, 0x19, 0x19]; // ESC p 1 25 25 (alternative)
    }
    
    return Uint8List.fromList(bytes);
  }

  // Helper method to get payment method display name
  static String _getPaymentMethodName(String code) {
    switch (code.toLowerCase()) {
      case 'cash':
        return 'Tunai';
      case 'card':
        return 'Kartu Kredit';
      case 'qris':
        return 'Qris';
      default:
        return code;
    }
  }

  // Test printer connection
  static Future<bool> testPrint({bool testDrawer = false}) async {
    try {
      if (!_isConnected || _writeCharacteristic == null) {
        debugPrint('Printer not connected');
        return false;
      }

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.text(
        'TEST PRINT',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ),
      );
      
      bytes += generator.text(
        'Printer berhasil terhubung!',
        styles: const PosStyles(align: PosAlign.center),
      );
      
      bytes += generator.text(
        DateTime.now().toString(),
        styles: const PosStyles(align: PosAlign.center),
      );
      
      if (testDrawer) {
        bytes += generator.text(
          'Testing cash drawer...',
          styles: const PosStyles(align: PosAlign.center),
        );
      }
      
      bytes += generator.emptyLines(2);
      bytes += generator.cut();
      
      // Add cash drawer command if testing drawer
      if (testDrawer) {
        bytes += [0x1B, 0x70, 0x00, 0x19, 0x19]; // ESC p 0 25 25
        bytes += [0x1B, 0x70, 0x01, 0x19, 0x19]; // ESC p 1 25 25
      }

      debugPrint('Test print data size: ${bytes.length} bytes');
      
      bool success = await _writeDataInChunks(Uint8List.fromList(bytes));
      
      if (success) {
        debugPrint('Test print successful');
        if (testDrawer) {
          debugPrint('Cash drawer test command sent');
        }
        return true;
      } else {
        debugPrint('Test print failed');
        return false;
      }
    } catch (e) {
      debugPrint('Error in test print: $e');
      return false;
    }
  }

  // Test cash drawer only
  static Future<bool> testCashDrawer() async {
    try {
      if (!_isConnected || _writeCharacteristic == null) {
        debugPrint('Printer not connected - cannot test cash drawer');
        return false;
      }

      debugPrint('Testing cash drawer...');
      return await openCashDrawer();
    } catch (e) {
      debugPrint('Error testing cash drawer: $e');
      return false;
    }
  }
}
