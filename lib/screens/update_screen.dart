import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ota_update/ota_update.dart';

class UpdatePage extends StatefulWidget {
  const UpdatePage({Key? key}) : super(key: key);

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  StreamSubscription<OtaEvent>? _subscription;
  String _status = 'Idle';
  double _progress = 0.0;
  bool _isUpdating = false;

  // Placeholder URL. Replace with your real update apk/download url later.
  final String _placeholderUrl = 'https://www.dropbox.com/scl/fi/xx6a2u97paozylz5gyiwn/remembrance.apk?rlkey=bvi54i8kjcg00iuh86t4xmpyf&st=imdgape8&dl=1';

  Future<void> _startOta() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
      _status = 'Starting update...';
      _progress = 0.0;
    });

    try {
      _subscription = OtaUpdate()
          .execute(
        _placeholderUrl, // <- placeholder; replace with actual APK URL later
        destinationFilename: 'app_update.apk',
      )
          .listen(
        (OtaEvent event) {
          // OTA sends events with status and value (value often contains percent)
          setState(() {
            _status = event.status.toString();
            if (event.value != null && event.value!.isNotEmpty) {
              // event.value sometimes contains "%" or numeric; try parse
              final parsed = double.tryParse(event.value!.replaceAll('%', '')) ?? 0.0;
              _progress = parsed.clamp(0.0, 100.0);
            }
          });

          // When installing or finished, offer restart
          if (event.status == OtaStatus.INSTALLING ||
              event.status == OtaStatus.ALREADY_RUNNING_ERROR ||
              event.status == OtaStatus.PERMISSION_NOT_GRANTED_ERROR ||
              event.status == OtaStatus.DOWNLOAD_ERROR ||
              event.status == OtaStatus.CHECKSUM_ERROR) {
            // For errors we just show message and allow user to close
            // if (event.status == OtaStatus.INSTALLING) {
            //   _showRestartDialog();
            // }
            if (event.status == OtaStatus.DOWNLOAD_ERROR ||
                event.status == OtaStatus.CHECKSUM_ERROR ||
                event.status == OtaStatus.PERMISSION_NOT_GRANTED_ERROR) {
              // stop updating flag so user can retry
              setState(() => _isUpdating = false);
            }
          }
        },
        onError: (e) {
          setState(() {
            _status = 'Error: $e';
            _isUpdating = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _status = 'Failed to start OTA: $e';
        _isUpdating = false;
      });
    }
  }

  // void _showRestartDialog() {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Update ready'),
  //       content: const Text('The app update has been installed. Restart now to apply changes.'),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.of(context).pop(); // close dialog
  //           },
  //           child: const Text('Later'),
  //         ),
  //         TextButton(
  //           onPressed: () {
  //             // Close the dialog first
  //             Navigator.of(context).pop();
  //             // Attempt to close the app (Android). Fully automatic restart is platform-dependent.
  //             SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
  //           },
  //           child: const Text('Restart now'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Update App',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),

                // Icon + Title
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.system_update_alt, size: 72, color: Colors.white.withOpacity(0.95)),
                      const SizedBox(height: 12),
                      const Text(
                        'Install App Update',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Download package from server and install.',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // status + progress
                Text('Status: $_status', style: TextStyle(color: Colors.white.withOpacity(0.9))),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progress > 0 ? (_progress / 100.0) : null,
                  minHeight: 8,
                  // Do not set color explicitly to follow your theme look; the default will be fine
                ),
                const SizedBox(height: 12),
                Text(
                  _progress > 0 ? '${_progress.toStringAsFixed(1)}%' : '',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),

                const Spacer(),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _startOta,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_isUpdating ? 'Updating...' : 'Start Update'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    // copy placeholder url to clipboard so developer can paste real url
                    Clipboard.setData(ClipboardData(text: _placeholderUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Update URL copied to clipboard')),
                    );
                  },
                  child: Text('Copy update URL', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
