import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../models/request_model.dart';
import '../../models/user_model.dart';
import '../../services/notification_service.dart';
import '../home/home_screen.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  // Instructons
  final _instructionsController = TextEditingController();
  final List<TextEditingController> _listControllers = [];
  bool _isListMode = false; // Toggle between Description and List

  // Specs
  DateTime? _deadline;
  int _pageCount = 1;
  bool _isLoading = false;

  // Media
  final List<PlatformFile> _selectedPdfs = [];
  final List<PlatformFile> _selectedImages = [];
  final List<PlatformFile> _selectedVideos = [];

  // Voice
  final List<String> _voiceNotePaths = [];
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isRecording = false;
  String? _playingPath;
  StreamSubscription? _recorderSubscription;
  double _decibels = 0.0; // For visualizer
  Timer? _recordTimer;
  int _recordDuration = 0; // Seconds

  // Pricing Logic
  String _pageType = 'A4'; // 'A4' or 'EdSheet'
  double _estimatedPrice = 0.0;

  // Instruction Video
  VideoPlayerController? _videoController;


  @override
  void initState() {
    super.initState();
    _initRecorder();
    // Default deadline 4 days from now
    _deadline = DateTime.now().add(const Duration(days: 4));
    _calculateEstimate();
    _listControllers.add(TextEditingController()); // Start with one point
    _initVideoPlayer();
  }

  void _initVideoPlayer() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse('https://res.cloudinary.com/doxmvuss9/video/upload/v1766751305/link-generator/hfepcnjloyjrjp2fe66r.mp4')
    );
    await _videoController!.initialize();
    _videoController!.setVolume(0); // Mute
    _videoController!.setLooping(true);
    _videoController!.play(); // Autoplay
    setState(() {});
    }

  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();

    await _recorder!.openRecorder();
    await _player!.openPlayer();

    await Permission.microphone.request();

    // Set metering logic
    await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 50));
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    for (var c in _listControllers) {
      c.dispose();
    }
    _recorderSubscription?.cancel();
    _recorder!.closeRecorder();
    _player!.closePlayer();
    _videoController?.dispose();
    super.dispose();
  }

  // --- Logic Methods ---

  void _toggleInstructionsMode() {
    setState(() {
       _isListMode = !_isListMode;
       if (_isListMode) {
          // Convert text to list
          final text = _instructionsController.text.trim();
          _listControllers.forEach((c) => c.dispose());
          _listControllers.clear();
          if (text.isNotEmpty) {
             final points = text.split('\n');
             for (var p in points) {
                _listControllers.add(TextEditingController(text: p.replaceAll('• ', '').trim()));
             }
          } else {
             _listControllers.add(TextEditingController());
          }
       } else {
          // Convert list to text
          final points = _listControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
          if (points.isNotEmpty) {
             _instructionsController.text = points.map((p) => '• $p').join('\n');
          }
       }
    });
  }

  Future<void> _recordAudio() async {
    if (_isRecording) {
      final path = await _recorder!.stopRecorder();
      _recorderSubscription?.cancel();
      if (path != null) {
        setState(() {
          _isRecording = false;
          _stopTimer();
          _voiceNotePaths.add(path);
          _decibels = 0.0;
        });
      }
    } else {
       if (await Permission.microphone.request().isGranted) {
           final path = 'voice_note_${DateTime.now().millisecondsSinceEpoch}.aac';
           await _recorder!.startRecorder(toFile: path);

           // Start metering
           _recorderSubscription = _recorder!.onProgress!.listen((e) {
              if (e.decibels != null) {
                 setState(() => _decibels = e.decibels!);
              }
           });

           setState(() {
               _isRecording = true;
               _recordDuration = 0;
           });
           _startTimer();
       }
    }
  }

  Future<void> _playVoiceNote(String path) async {
    if (_playingPath == path) {
      // Stop interaction
      await _player!.stopPlayer();
      setState(() => _playingPath = null);
    } else {
      // Stop any other
      if (_playingPath != null) await _player!.stopPlayer();

      setState(() => _playingPath = path);
      await _player!.startPlayer(
         fromURI: path,
         whenFinished: () => setState(() => _playingPath = null),
      );
    }
  }

  void _startTimer() {
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordDuration++);
    });
  }

  void _stopTimer() {
    _recordTimer?.cancel();
    _recordDuration = 0;
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Future<void> _pickFiles(FileType type, List<PlatformFile> targetList, {List<String>? allowedExtensions}) async {
    try {
        final result = await FilePicker.platform.pickFiles(
          type: type,
          allowMultiple: true,
          allowedExtensions: allowedExtensions,
        );
        if (result != null) {
          setState(() => targetList.addAll(result.files));
        }
    } catch (e) {
       debugPrint('Error picking files: $e');
    }
  }

  void _calculateEstimate() {
    if (_deadline == null) return;

    final days = _deadline!.difference(DateTime.now()).inDays + 1;

    if (_pageType == 'EdSheet') {
      _estimatedPrice = 230.0 * _pageCount; // Fixed per page
    } else {
      // Assignment
      double pricePerPage = 4.0;
      if (days < 4) {
        if (days == 3) pricePerPage += 1; // 5
        if (days == 2) pricePerPage += 2; // 6
        if (days <= 1) pricePerPage += 3; // 7
      }
      _estimatedPrice = pricePerPage * _pageCount;
    }
    setState(() {});
  }

  Future<void> _updateContactDetails(AppUser user) async {
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');
    final addressController = TextEditingController(text: user.location ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Contact'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                     setDialogState(() => _isLoading = true); // Local loading usually
                     try {
                        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                        if (!serviceEnabled) {
                           // Try to open settings
                           serviceEnabled = await Geolocator.openLocationSettings();
                           if (!serviceEnabled) throw Exception('Please enable Location Services (GPS) on your device.');
                        }

                        var permission = await Geolocator.checkPermission();
                        if (permission == LocationPermission.denied) {
                           permission = await Geolocator.requestPermission();
                           if (permission == LocationPermission.denied) throw Exception('Location permissions are denied.');
                        }
                        if (permission == LocationPermission.deniedForever) {
                           throw Exception('Location permissions are permanently denied. Please enable them in App Settings.');
                        }

                        final position = await Geolocator.getCurrentPosition();
                        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
                        if (placemarks.isNotEmpty) {
                           final place = placemarks.first;
                           final fetched = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}';
                           addressController.text = fetched;
                        }
                     } catch (e) {
                        debugPrint('GPS Error: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GPS Error: $e'), backgroundColor: Colors.red));
                        }
                     } finally {
                        setDialogState(() => _isLoading = false);
                     }
                  },
                  icon: const Icon(Icons.my_location),
                  label: const Text('Detect GPS Location'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Mobile', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
              ],
            );
          }
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
               if (phoneController.text.isEmpty) return;
               await ref.read(firestoreServiceProvider).updateUser(user.uid, {
                 'location': addressController.text,
                 'phoneNumber': phoneController.text,
               });


               if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFAF00), foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }


  Future<void> _submitRequest() async {
    if (_deadline == null) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    // Validate Contact
    final appUser = await ref.read(firestoreServiceProvider).getUser(user.uid);
    if (appUser?.phoneNumber == null || appUser?.location == null) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add Mobile Number and Location')));
       }
       return;
    }

    // Sync instructions if in List Mode
    if (_isListMode) {
      final points = _listControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
      _instructionsController.text = points.map((p) => '• $p').join('\n');
    }

    setState(() => _isLoading = true);

    try {
      final cloudinaryService = cloudinaryServiceProvider;
      final firestoreService = ref.read(firestoreServiceProvider);

      List<String> attachmentUrls = [];
      Map<String, String> mediaUrls = {}; // Supporting simplistic map for compatibility, but mainly relying on attachmentUrls

      // Upload PDFs
      for (var file in _selectedPdfs) {
        final url = await cloudinaryService.uploadFile(file: file, folder: 'requests/pdfs');
        if (url != null) attachmentUrls.add(url);
      }
      // Upload Images
      for (var file in _selectedImages) {
        final url = await cloudinaryService.uploadFile(file: file, folder: 'requests/images');
        if (url != null) attachmentUrls.add(url);
      }
       // Upload Videos
      for (var file in _selectedVideos) {
        final url = await cloudinaryService.uploadFile(file: file, folder: 'requests/videos');
        if (url != null) attachmentUrls.add(url);
      }

      // Upload Voice Notes
      // In a real app we'd upload all. Storing one for now in field or list in attachments
      String? mainVoiceUrl;
      for (var path in _voiceNotePaths) {
         final file = PlatformFile(path: path, name: 'voice_note.aac', size: 0);
         final url = await cloudinaryService.uploadFile(file: file, folder: 'requests/audio');
         if (url != null) {
           attachmentUrls.add(url);
           mainVoiceUrl ??= url; // First one as main
         }
      }

      final newRequest = RequestModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        studentId: user.uid,
        instructions: _instructionsController.text.trim(),
        deadline: _deadline!,
        budget: 0.0, // Set by admin usually, or we can set estimated? Let's leave 0 for admin to verify
        status: 'created',
        attachmentUrls: attachmentUrls,
        mediaUrls: mediaUrls,
        voiceNoteUrl: mainVoiceUrl,
        pageType: _pageType,
        pageCount: _pageCount, // New field needed in model? Using existing or map?
        // Check RequestModel: it has pageType, but pageCount needed.
        // We will store it in custom data or update model later.
        // For now let's assume valid fields or put in instructions.
        statusHistory: [{'status': 'created', 'timestamp': DateTime.now().millisecondsSinceEpoch}],
        createdAt: DateTime.now(),
      );

      await firestoreService.createRequest(newRequest);

      // --- Success Actions ---
      if (mounted) {
        // 1. Notify Admins
        final notificationService = ref.read(notificationServiceProvider);
        final studentName = appUser?.displayName ?? 'A student';
        final studentCity = appUser?.city ?? 'Unknown city';

        notificationService.notifyAdmins(
          title: 'New Order Received! 🚀',
          body: 'From $studentCity, $studentName created ${newRequest.pageCount} pages order',
        );

        // 2. Notify User (The requested message)
        notificationService.notifyUser(
          userId: user.uid,
          title: 'Order Received! ✅',
          body: 'Your order is on the way! You will get a call in 10 minutes.',
        );

        // 3. Switch to History Tab and close screen
        if (mounted) {
          ref.read(homeTabIndexProvider.notifier).state = 1; // Switch to History tab
          Navigator.pop(context); // Close CreateRequestScreen
        }
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI Components ---

  Widget _buildDarkComponent({required String title, required Widget child, Widget? tail}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black, // Dark Component
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
           BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
               if (tail != null) tail,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;

    // User validation for buttons
    bool hasMobile = user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty;
    bool hasLocation = user?.location != null && user!.location!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('New Request', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFAF00),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: user == null ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 1. Attachments
              _buildDarkComponent(
                title: 'Attachments',
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMediaButton(Icons.picture_as_pdf, 'PDF', () => _pickFiles(FileType.custom, _selectedPdfs, allowedExtensions: ['pdf'])),
                        _buildMediaButton(Icons.image, 'Image', () => _pickFiles(FileType.image, _selectedImages)),
                        _buildMediaButton(Icons.videocam, 'Video', () => _pickFiles(FileType.video, _selectedVideos)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_selectedPdfs.isNotEmpty || _selectedImages.isNotEmpty || _selectedVideos.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                           ..._selectedPdfs.map((f) => _buildChip('PDF', f.name, () => setState(() => _selectedPdfs.remove(f)))),
                           ..._selectedImages.map((f) => _buildChip('IMG', f.name, () => setState(() => _selectedImages.remove(f)))),
                           ..._selectedVideos.map((f) => _buildChip('VID', f.name, () => setState(() => _selectedVideos.remove(f)))),
                        ],
                      ),
                  ],
                ),
              ),

              // 2. Instructions
              _buildDarkComponent(
                title: 'Instructions',
                tail: IconButton(
                  icon: Icon(_isListMode ? Icons.list : Icons.notes, color: const Color(0xFFFFAF00)),
                  tooltip: _isListMode ? 'Switch to Text' : 'Switch to List',
                  onPressed: _toggleInstructionsMode,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isListMode
                  ? Column(
                      children: [
                        ..._listControllers.asMap().entries.map((entry) {
                           return Padding(
                             padding: const EdgeInsets.only(bottom: 8.0),
                             child: Row(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Padding(
                                   padding: const EdgeInsets.only(top: 12.0, right: 8),
                                   child: Text('•', style: TextStyle(color: const Color(0xFFFFAF00), fontSize: 24, fontWeight: FontWeight.bold)), // Bold Bullet
                                 ),
                                 Expanded(
                                   child: TextField(
                                     controller: entry.value,
                                     style: const TextStyle(color: Colors.white),
                                     maxLines: null,
                                     decoration: InputDecoration(
                                       border: InputBorder.none,
                                       hintText: 'Enter point...',
                                       hintStyle: TextStyle(color: Colors.grey[600]),
                                     ),
                                   ),
                                 ),
                                 if (_listControllers.length > 1)
                                   IconButton(icon: const Icon(Icons.close, color: Colors.grey, size: 16), onPressed: () => setState(() => _listControllers.removeAt(entry.key))),
                               ],
                             ),
                           );
                        }),
                        TextButton.icon(
                          onPressed: () => setState(() => _listControllers.add(TextEditingController())),
                          icon: const Icon(Icons.add, color: Color(0xFFFFAF00)),
                          label: const Text('Add Point', style: TextStyle(color: Color(0xFFFFAF00))),
                        ),
                      ],
                    )
                  : TextField(
                    controller: _instructionsController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 6,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Write detailed instructions here...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              ),

              // 3. Voice Note
              _buildDarkComponent(
                title: 'Voice Notes',
                child: Column(
                  children: [
                     Center(
                       child: GestureDetector(
                         onTap: _recordAudio,
                         child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                height: _isRecording ? (60 + (_decibels.clamp(0, 100) * 0.5)) : 80, // React to sound
                                width: _isRecording ? (60 + (_decibels.clamp(0, 100) * 0.5)) : 80,
                                decoration: BoxDecoration(
                                   color: _isRecording ? Colors.red.withValues(alpha: 0.2) : Colors.grey[900],
                                   shape: BoxShape.circle,
                                   border: Border.all(color: _isRecording ? Colors.red : const Color(0xFFFFAF00), width: 2),
                                ),
                                child: Icon(
                                   _isRecording ? Icons.stop : Icons.mic,
                                   size: 40,
                                   color: _isRecording ? Colors.red : const Color(0xFFFFAF00)
                                ),
                              ),
                              if (_isRecording)
                                 Padding(
                                   padding: const EdgeInsets.only(top: 8.0),
                                   child: Text('Recording... ${_formatDuration(_recordDuration)} | ${(_decibels).toStringAsFixed(1)} dB', style: const TextStyle(color: Colors.red, fontSize: 12)),
                                 ),
                            ],
                         ),
                       ),
                     ),
                     const SizedBox(height: 12),
                     if (_voiceNotePaths.isNotEmpty)
                        Column(
                          children: _voiceNotePaths.asMap().entries.map((entry) {
                             final index = entry.key;
                             final path = entry.value;
                             final isPlaying = _playingPath == path;

                             return Container(
                             margin: const EdgeInsets.only(top: 8),
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
                             child: Row(
                               children: [
                                 IconButton(
                                    icon: Icon(isPlaying ? Icons.stop_circle : Icons.play_circle_fill, color: const Color(0xFFFFAF00), size: 30),
                                    onPressed: () => _playVoiceNote(path),
                                 ),
                                 const SizedBox(width: 8),
                                 Expanded(child: Text('Voice Note ${index + 1}', style: const TextStyle(color: Colors.white))),
                                 IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => setState(() => _voiceNotePaths.remove(path))),
                               ],
                             ),
                          );
                          }).toList(),
                        ),
                  ],
                ),
              ),

              // 4. Specifications
              _buildDarkComponent(
                title: 'Specifications',
                child: Column(
                  children: [
                     DropdownButtonFormField<String>(
                        initialValue: _pageType,
                        dropdownColor: Colors.grey[900],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Page Type',
                          labelStyle: const TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!)),
                          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFAF00))),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'A4', child: Text('Assignment Paper (A4)')),
                          DropdownMenuItem(value: 'EdSheet', child: Text('Ed Sheet (Engineering)')),
                        ],
                        onChanged: (val) {
                          setState(() { _pageType = val!; _calculateEstimate(); });
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text('Deadline', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16)),
                           ElevatedButton(
                              onPressed: () async {
                                 // For EdSheet: Min 3 days
                                 final minDays = _pageType == 'EdSheet' ? 3 : 0;
                                 final initialDate = DateTime.now().add(Duration(days: minDays > 0 ? minDays : 4)); // Default somewhat ahead

                                 final picked = await showDatePicker(
                                   context: context,
                                   initialDate: _deadline != null && _deadline!.isAfter(DateTime.now().add(Duration(days: minDays))) ? _deadline! : initialDate,
                                   firstDate: DateTime.now().add(Duration(days: minDays)),
                                   lastDate: DateTime.now().add(const Duration(days: 60))
                                 );
                                 if (picked != null) setState(() { _deadline = picked; _calculateEstimate(); });
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFAF00), foregroundColor: Colors.black),
                              child: Text(_deadline == null ? 'Select' : DateFormat('MMM d').format(_deadline!)),
                           ),
                         ],
                      ),
                      const SizedBox(height: 16),
                      // Page Count (Visible for both now)
                       Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                              Text('Number of Pages', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16)),
                              SizedBox(
                                width: 100,
                                child: TextFormField(
                                  // Use Key to force rebuild if valid changes significantly, or controller.
                                  // Simple initialValue works if not constantly changing from outside.
                                  initialValue: _pageCount.toString(),
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                    filled: true,
                                    fillColor: Colors.grey[800],
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  ),
                                  onChanged: (val) {
                                     final count = int.tryParse(val);
                                     if (count != null && count > 0) {
                                       setState(() {
                                         _pageCount = count;
                                         _calculateEstimate();
                                       });
                                     }
                                  },
                                ),
                              ),
                          ],
                       ),
                       // Estimated Price (Moved here)
                       const SizedBox(height: 16),
                       Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                             color: Colors.black,
                             borderRadius: BorderRadius.circular(16),
                             border: Border.all(color: const Color(0xFFFFAF00)),
                             boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4)),
                             ],
                          ),
                          child: Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                                const Text('Estimated Price', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                Text('₹${_estimatedPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFFFAF00))),
                             ],
                          ),
                       ),
                      const SizedBox(height: 16),

                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 5. How to Count Pages (Video)
              _buildDarkComponent(
                title: 'How to Count the number of Page?',
                child: _videoController != null && _videoController!.value.isInitialized
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: IgnorePointer(
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                      )
                    : const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: Color(0xFFFFAF00)),
                        ),
                      ),
              ),

              const SizedBox(height: 10),

              // 5. Location & Mobile
              _buildDarkComponent(
                 title: 'Mobile Number',
                 child: hasMobile
                 ? ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(user.phoneNumber!, style: const TextStyle(color: Colors.white, fontSize: 18)),
                    trailing: TextButton(onPressed: () => _updateContactDetails(user), child: const Text('Edit', style: TextStyle(color: Color(0xFFFFAF00)))),
                   )
                 : ElevatedButton(
                    onPressed: () => _updateContactDetails(user),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFAF00), foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Add Mobile Number'),
                 ),
              ),

              _buildDarkComponent(
                 title: 'Location',
                 child: hasLocation
                 ? ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(user.location!, style: const TextStyle(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: TextButton(onPressed: () => _updateContactDetails(user), child: const Text('Edit', style: TextStyle(color: Color(0xFFFFAF00)))),
                   )
                 : ElevatedButton(
                    onPressed: () => _updateContactDetails(user),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFAF00), foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Add Location'),
                 ),
              ),

              const SizedBox(height: 20),

              // Estimate & Submit
              const SizedBox(height: 20),
              // Price removed from here, moved up.
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: const Color(0xFFFFAF00),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Color(0xFFFFAF00)) : const Text('CREATE REQUEST', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaButton(IconData icon, String label, VoidCallback onTap) {
     return InkWell(
        onTap: onTap,
        child: Column(
           children: [
              Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(color: Colors.grey[900], shape: BoxShape.circle, border: Border.all(color: Colors.grey[800]!)),
                 child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
           ],
        ),
     );
  }

  Widget _buildChip(String type, String label, VoidCallback onDelete) {
     return Chip(
        backgroundColor: Colors.grey[900],
        label: Text('$type: $label', style: const TextStyle(color: Colors.white, fontSize: 10), maxLines: 1),
        deleteIcon: const Icon(Icons.close, size: 14, color: Colors.red),
        onDeleted: onDelete,
     );
  }
}
