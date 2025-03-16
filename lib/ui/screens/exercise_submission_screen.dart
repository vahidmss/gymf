import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:gymf/data/models/exercise_model.dart';
import 'package:provider/provider.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/providers/exercise_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';

class ExerciseSubmissionScreen extends StatefulWidget {
  const ExerciseSubmissionScreen({super.key});

  @override
  _ExerciseSubmissionScreenState createState() =>
      _ExerciseSubmissionScreenState();
}

class _ExerciseSubmissionScreenState extends State<ExerciseSubmissionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late Debouncer<String> _searchDebouncer;
  late StreamSubscription<String> _searchSubscription;
  String _currentSearchQuery = '';
  Future<List<ExerciseModel>>? _coachExercisesFuture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _searchDebouncer = Debouncer<String>(
      const Duration(milliseconds: 500),
      initialValue: '',
    );
    _searchSubscription = _searchDebouncer.values.listen((value) {
      setState(() {
        _currentSearchQuery = value;
      });
    });
    _nameController.addListener(() {
      _searchDebouncer.value = _nameController.text;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final exerciseProvider = Provider.of<ExerciseProvider>(
      context,
      listen: false,
    );
    _loadCoachExercises(authProvider.userId ?? '', exerciseProvider);
  }

  @override
  void dispose() {
    _searchSubscription.cancel();
    _controller.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadCoachExercises(String userId, ExerciseProvider provider) {
    _coachExercisesFuture = provider.fetchCoachExercises(userId);
  }

  void _submitExercise(ExerciseProvider provider) {
    if (provider.isLoading) return; // جلوگیری از ارسال چندباره
    provider.submitExercise(
      name: _nameController.text,
      category: provider.selectedCategory!,
      targetMuscle:
          provider.selectedCategory == 'قدرتی'
              ? provider.selectedTargetMuscle
              : null,
      description:
          _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمرین با موفقیت ثبت شد!')),
        );
        _nameController.clear();
        _descriptionController.clear();
        provider.resetForm();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ExerciseSubmissionScreen(),
          ),
        );
      },
      onFailure:
          (error) => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('خطا: $error'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black,
            Colors.blueGrey.shade900,
            Colors.blueAccent.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('images/Vteem1.png', height: 50).animate().scale(),
              const SizedBox(width: 10),
              Text(
                'ثبت تمرین جدید',
                style: GoogleFonts.vazirmatn(
                  textStyle: const TextStyle(
                    color: Colors.yellowAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 5)],
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Builder(
              builder:
                  (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.yellowAccent),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
            ),
          ],
        ),
        endDrawer: _buildExerciseDrawer(
          context,
          authProvider.userId ?? 'unknown',
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: AnimateList(
                  interval: 100.ms,
                  effects: [
                    FadeEffect(duration: 600.ms),
                    SlideEffect(begin: const Offset(0, 0.3), end: Offset.zero),
                  ],
                  children: [
                    Consumer<ExerciseProvider>(
                      builder:
                          (context, provider, _) => _buildGlassDropdown(
                            label: 'دسته‌بندی',
                            value: provider.selectedCategory,
                            items: const ['قدرتی', 'هوازی', 'تعادلی'],
                            onChanged: provider.setCategory,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Consumer<ExerciseProvider>(
                      builder:
                          (context, provider, _) =>
                              provider.selectedCategory == 'قدرتی'
                                  ? _buildGlassDropdown(
                                    label: 'عضله هدف',
                                    value: provider.selectedTargetMuscle,
                                    items: const [
                                      'پا',
                                      'شکم',
                                      'سینه',
                                      'بازو',
                                      'زیربغل',
                                      'سرشانه',
                                    ],
                                    onChanged: provider.setTargetMuscle,
                                  )
                                  : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),
                    _buildGlassTextField(
                      controller: _nameController,
                      label: 'اسم تمرین',
                      validator:
                          (value) =>
                              value!.isEmpty ? 'اسم نمی‌تونه خالی باشه!' : null,
                    ),
                    const SizedBox(height: 20),
                    Consumer<ExerciseProvider>(
                      builder:
                          (context, provider, _) => _buildSearchWidget(
                            provider,
                            authProvider.userId ?? '',
                          ),
                    ),
                    const SizedBox(height: 20),
                    _buildGlassTextField(
                      controller: _descriptionController,
                      label: 'توضیحات (اختیاری)',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    Consumer<ExerciseProvider>(
                      builder:
                          (context, provider, _) => _buildGlassDropdown(
                            label: 'نوع شمارش',
                            value: provider.selectedCountingType,
                            items: const ['وزن (kg)', 'تایم', 'تعداد'],
                            onChanged:
                                (value) => provider.setCountingType(value),
                          ),
                    ),
                    const SizedBox(height: 30),
                    Consumer<ExerciseProvider>(
                      builder:
                          (context, provider, _) => _buildMediaRow(provider),
                    ),
                    const SizedBox(height: 30),
                    Consumer<ExerciseProvider>(
                      builder:
                          (context, provider, _) => Column(
                            children: [
                              ValueListenableBuilder<double>(
                                valueListenable: provider.uploadProgress,
                                builder: (context, progress, child) {
                                  return progress > 0
                                      ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: LinearProgressIndicator(
                                          value: progress / 100,
                                          backgroundColor: Colors.grey
                                              .withOpacity(0.3),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Colors.yellowAccent),
                                          minHeight: 10,
                                        ),
                                      )
                                      : const SizedBox.shrink();
                                },
                              ),
                              _buildNeonButton(
                                text: 'ثبت تمرین',
                                onPressed: () => _submitExercise(provider),
                                isLoading: provider.isLoading,
                              ),
                            ],
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.vazirmatn(color: Colors.white70),
          border: InputBorder.none,
        ),
        dropdownColor: Colors.blueGrey.shade800,
        style: GoogleFonts.vazirmatn(color: Colors.white),
        iconEnabledColor: Colors.yellowAccent,
        items:
            items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
        onChanged: (newValue) => onChanged(newValue!),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.vazirmatn(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.vazirmatn(color: Colors.white70),
          border: InputBorder.none,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildMediaRow(ExerciseProvider provider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMediaButton(
              icon: Icons.image,
              label: 'عکس',
              file: provider.selectedImage,
              onPressed: () async {
                final pickedFile = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );
                if (pickedFile != null) {
                  provider.setImage(File(pickedFile.path));
                }
              },
            ),
            _buildMediaButton(
              icon: Icons.videocam,
              label: 'ویدیو',
              file: provider.selectedVideo,
              onPressed: () async {
                final pickedFile = await ImagePicker().pickVideo(
                  source: ImageSource.gallery,
                );
                if (pickedFile != null) {
                  provider.setVideo(File(pickedFile.path));
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (provider.selectedImage != null || provider.selectedVideo != null)
          _buildMediaPreview(provider),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildMediaPreview(ExerciseProvider provider) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.yellowAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          if (provider.selectedImage != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    provider.selectedImage!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => provider.clearImage(),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.yellowAccent,
                        ),
                        onPressed: () async {
                          final pickedFile = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                          );
                          if (pickedFile != null) {
                            provider.setImage(File(pickedFile.path));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
          if (provider.selectedImage != null && provider.selectedVideo != null)
            const SizedBox(height: 10),
          if (provider.selectedVideo != null)
            VideoPreviewWidget(videoFile: provider.selectedVideo!),
        ],
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    File? file,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 120,
        height: 100,
        decoration: BoxDecoration(
          color:
              file != null
                  ? Colors.green.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.yellowAccent.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.yellowAccent, size: 30),
            const SizedBox(height: 5),
            Text(
              file != null ? 'انتخاب شد' : label,
              style: GoogleFonts.vazirmatn(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeonButton({
    required String text,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.yellowAccent, Colors.orangeAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.yellowAccent.withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child:
            isLoading
                ? const CircularProgressIndicator(color: Colors.black)
                : Text(
                  text,
                  style: GoogleFonts.vazirmatn(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
  }

  Widget _buildSearchWidget(ExerciseProvider provider, String userId) {
    if (_currentSearchQuery.length < 3 || provider.selectedCategory == null) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<List<ExerciseModel>>(
      future: provider.searchExercises(
        category: provider.selectedCategory,
        targetMuscle:
            provider.selectedCategory == 'قدرتی'
                ? provider.selectedTargetMuscle
                : null,
        searchQuery: _currentSearchQuery,
        userId: userId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text(
            'خطا در جستجو',
            style: TextStyle(color: Colors.white),
          );
        }
        final results = snapshot.data!;
        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final exercise = results[index];
              return Card(
                color: Colors.white.withOpacity(0.1),
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  title: Text(
                    exercise.name,
                    style: GoogleFonts.vazirmatn(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${exercise.category} (${exercise.countingType ?? 'نامشخص'})',
                    style: GoogleFonts.vazirmatn(color: Colors.white70),
                  ),
                  onTap:
                      exercise.createdBy == userId
                          ? () => Navigator.pushNamed(
                            context,
                            '/edit-exercise',
                            arguments: exercise,
                          )
                          : null,
                ),
              ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms);
            },
          ),
        );
      },
    );
  }

  Widget _buildExerciseDrawer(BuildContext context, String userId) {
    return Consumer<ExerciseProvider>(
      builder:
          (context, provider, _) => Drawer(
            backgroundColor: Colors.blueGrey.shade900,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.yellowAccent,
                  child: Text(
                    'تمرینات من',
                    style: GoogleFonts.vazirmatn(
                      textStyle: const TextStyle(
                        fontSize: 24,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<ExerciseModel>>(
                    future: _coachExercisesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Center(
                          child: Text(
                            'خطا در بارگذاری',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      final exercises = snapshot.data!;
                      return ListView.builder(
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];
                          return ListTile(
                            title: Text(
                              exercise.name,
                              style: GoogleFonts.vazirmatn(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${exercise.category} - ${exercise.countingType ?? 'نامشخص'}',
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white70,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.yellowAccent,
                                  ),
                                  onPressed:
                                      () => Navigator.pushNamed(
                                        context,
                                        '/edit-exercise',
                                        arguments: exercise,
                                      ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    provider.deleteExercise(exercise.id);
                                    _loadCoachExercises(userId, provider);
                                  },
                                ),
                              ],
                            ),
                          ).animate().slideX(
                            begin: 0.3,
                            end: 0,
                            duration: 400.ms,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class VideoPreviewWidget extends StatefulWidget {
  final File videoFile;

  const VideoPreviewWidget({super.key, required this.videoFile});

  @override
  _VideoPreviewWidgetState createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.file(widget.videoFile)
      ..initialize()
          .then((_) {
            setState(() {
              _isInitialized = true;
            });
          })
          .catchError((e) {
            print('❌ خطا در مقداردهی ویدیو: $e');
            setState(() {
              _isInitialized = false;
            });
          });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExerciseProvider>(context, listen: false);
    return Stack(
      children: [
        _isInitialized
            ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: VideoPlayer(_videoController),
                  ),
                  IconButton(
                    icon: Icon(
                      _videoController.value.isPlaying
                          ? Icons.pause
                          : Icons.play_circle_fill,
                      size: 50,
                      color: Colors.yellowAccent,
                    ),
                    onPressed: () {
                      if (_videoController.value.isPlaying) {
                        _videoController.pause();
                      } else {
                        _videoController.play();
                      }
                      setState(() {});
                    },
                  ),
                ],
              ),
            ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack)
            : const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            ),
        Positioned(
          top: 5,
          right: 5,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  provider.clearVideo();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExerciseSubmissionScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.yellowAccent),
                onPressed: () async {
                  final pickedFile = await ImagePicker().pickVideo(
                    source: ImageSource.gallery,
                  );
                  if (pickedFile != null) {
                    provider.setVideo(File(pickedFile.path));
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExerciseSubmissionScreen(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
