import 'package:flutter/material.dart';
import '../services/thermal_printer_service.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  List<ScanResult> _availableDevices = [];
  bool _isLoading = false;
  bool _isConnected = false;
  String? _connectedDeviceAddress;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
    _scanForDevices();
  }

  void _checkConnectionStatus() {
    setState(() {
      _isConnected = ThermalPrinterService.isConnected;
      _connectedDeviceAddress = ThermalPrinterService.connectedDeviceAddress;
    });
  }

  Future<void> _scanForDevices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final devices = await ThermalPrinterService.getAvailableDevices();
      setState(() {
        _availableDevices = devices;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning devices: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _connectToDevice(ScanResult deviceResult) async {
    setState(() {
      _isLoading = true;
    });

    try {
      BluetoothDevice device = deviceResult.device;
      String deviceId = device.platformName.isNotEmpty
          ? device.platformName
          : device.remoteId.toString();
      bool success = await ThermalPrinterService.connectToPrinter(deviceId);

      if (success) {
        setState(() {
          _isConnected = true;
          _connectedDeviceAddress = deviceId;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Connected to ${device.platformName.isNotEmpty ? device.platformName : 'Unknown Device'}',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to connect to ${device.platformName.isNotEmpty ? device.platformName : 'Unknown Device'}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _disconnectDevice() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ThermalPrinterService.disconnect();
      setState(() {
        _isConnected = false;
        _connectedDeviceAddress = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disconnected from printer'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error disconnecting: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testPrint() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await ThermalPrinterService.testPrint();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Test print successful!' : 'Test print failed',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error in test print: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCashDrawer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await ThermalPrinterService.testCashDrawer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Cash drawer opened successfully!'
                  : 'Failed to open cash drawer',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening cash drawer: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testPrintWithDrawer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await ThermalPrinterService.testPrint(testDrawer: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Test print with cash drawer successful!'
                  : 'Test print with cash drawer failed',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error in test print with drawer: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithActions(
        title: 'Printer Settings',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _scanForDevices,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading...')
          : SingleChildScrollView(
              padding: AppStyles.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connection Status
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connection Status',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _isConnected
                                    ? AppColors.success
                                    : AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isConnected ? 'Connected' : 'Disconnected',
                              style: TextStyle(
                                color: _isConnected
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (_isConnected &&
                            _connectedDeviceAddress != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Device: $_connectedDeviceAddress',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (_isConnected) ...[
                          // First row of buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _testPrint,
                                  icon: const Icon(Icons.print),
                                  label: const Text('Test Print'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _testCashDrawer,
                                  icon: const Icon(Icons.point_of_sale),
                                  label: const Text('Test Drawer'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Second row of buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _testPrintWithDrawer,
                                  icon: const Icon(Icons.receipt_long),
                                  label: const Text('Print + Drawer'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _disconnectDevice,
                                  icon: const Icon(Icons.bluetooth_disabled),
                                  label: const Text('Disconnect'),
                                ),
                              ),
                            ],
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _scanForDevices,
                                  icon: const Icon(Icons.bluetooth_searching),
                                  label: const Text('Scan Devices'),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Available Devices
                  Text(
                    'Available Bluetooth Devices',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_availableDevices.isEmpty)
                    const CustomCard(
                      child: EmptyStateWidget(
                        title: 'No devices found',
                        subtitle:
                            'Make sure your Bluetooth printer is turned on and discoverable',
                        icon: Icons.bluetooth_disabled,
                      ),
                    )
                  else
                    ..._availableDevices.map((deviceResult) {
                      BluetoothDevice device = deviceResult.device;
                      String deviceId = device.platformName.isNotEmpty
                          ? device.platformName
                          : device.remoteId.toString();
                      return CustomCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.print,
                            color: _connectedDeviceAddress == deviceId
                                ? AppColors.success
                                : AppColors.disabled,
                          ),
                          title: Text(
                            device.platformName.isNotEmpty
                                ? device.platformName
                                : 'Unknown Device',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(device.remoteId.toString()),
                          trailing: _connectedDeviceAddress == deviceId
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                )
                              : ElevatedButton(
                                  onPressed: () =>
                                      _connectToDevice(deviceResult),
                                  child: const Text('Connect'),
                                ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
