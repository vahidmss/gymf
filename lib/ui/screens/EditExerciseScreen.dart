import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymf/data/models/exercise_model.dart';
import 'package:gymf/providers/exercise_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class EditExerciseScreen extends StatefulWidget {
  final ExerciseModel exercise;

  const EditExerciseScreen({super.key, required this.exercise});

  @override
  _EditExerciseScreenState createState() => _EditExerciseScreenState();
}

class _EditExerciseScreenState extends State<EditExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  late String? _selectedTargetMuscle;
  late String? _selectedCountingType;
  File? _selectedImage;
  File? _selectedVideo;
  String? _existingImageUrl;
  String? _existingVideoUrl;
  bool _isLoading = false;
  VideoPlayerController? _videoController;
  bool _videoLoadError = false; // متغیر جدید برای مدیریت خطای ویدیویی
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise.name);
    _descriptionController = TextEditingController(
      text: widget.exercise.description,
    );
    _selectedCategory = widget.exercise.category;
    _selectedTargetMuscle = widget.exercise.targetMuscle;
    _selectedCountingType = widget.exercise.countingType;
    _existingImageUrl = widget.exercise.imageUrl;
    _existingVideoUrl = widget.exercise.videoUrl;

    if (_existingVideoUrl != null && _existingVideoUrl!.isNotEmpty) {
      final uri = Uri.tryParse(_existingVideoUrl!);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        _videoController = VideoPlayerController.network(_existingVideoUrl!)
          ..initialize()
              .then((_) {
                setState(() {});
              })
              .catchError((e) {
                print('❌ خطا در مقداردهی ویدیوی شبکه‌ای: $e');
                setState(() {
                  _videoLoadError = true; // تنظیم حالت خطا
                });
              });
      } else if (uri != null && uri.scheme == 'file') {
        _videoController = VideoPlayerController.file(File(uri.path))
          ..initialize()
              .then((_) {
                setState(() {});
              })
              .catchError((e) {
                print('❌ خطا در مقداردهی ویدیوی محلی: $e');
                setState(() {
                  _videoLoadError = true;
                });
              });
      } else {
        setState(() {
          _videoLoadError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _existingImageUrl = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedVideo = File(pickedFile.path);
        _existingVideoUrl = null;
        _videoController?.dispose();
        _videoLoadError = false; // ریست کردن حالت خطا
        _videoController = VideoPlayerController.file(_selectedVideo!)
          ..initialize()
              .then((_) {
                setState(() {});
              })
              .catchError((e) {
                print('❌ خطا در مقداردهی ویدیوی جدید: $e');
                setState(() {
                  _videoLoadError = true;
                });
              });
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _existingImageUrl = null;
    });
  }

  void _removeVideo() {
    setState(() {
      _selectedVideo = null;
      _existingVideoUrl = null;
      _videoController?.dispose();
      _videoController = null;
    });
  }

  Future<void> _updateExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<ExerciseProvider>(context, listen: false);
    final updates = {
      'name': _nameController.text,
      'category': _selectedCategory,
      'target_muscle':
          _selectedCategory == 'قدرتی' ? _selectedTargetMuscle : null,
      'description': _descriptionController.text,
      'counting_type': _selectedCountingType,
    };

    if (_selectedImage != null) {
      final imageUrl = await provider.uploadFile(
        _selectedImage!,
        '${provider.authProvider.currentUser!.username}/${widget.exercise.id}/image.jpg',
      );
      updates['image_url'] = imageUrl ?? '';
    } else {
      updates['image_url'] = _existingImageUrl ?? '';
    }

    if (_selectedVideo != null) {
      final videoUrl = await provider.uploadFile(
        _selectedVideo!,
        '${provider.authProvider.currentUser!.username}/${widget.exercise.id}/video.mp4',
      );
      updates['video_url'] = videoUrl ?? '';
    } else {
      updates['video_url'] = _existingVideoUrl ?? '';
    }

    try {
      await provider.updateExercise(widget.exercise.id, updates);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمرین با موفقیت به‌روزرسانی شد')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در به‌روزرسانی تمرین: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          title: Text(
            'ویرایش تمرین',
            style: GoogleFonts.vazirmatn(
              textStyle: const TextStyle(
                color: Colors.yellowAccent,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                shadows: [Shadow(color: Colors.black54, blurRadius: 5)],
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: AnimateList(
                        interval: 100.ms,
                        effects: [
                          FadeEffect(duration: 600.ms),
                          SlideEffect(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ),
                        ],
                        children: [
                          // نام تمرین
                          _buildGlassTextField(
                            controller: _nameController,
                            label: 'نام تمرین',
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'نام نمی‌تونه خالی باشه!'
                                        : null,
                          ),
                          const SizedBox(height: 20),

                          // دسته‌بندی
                          _buildGlassDropdown(
                            label: 'دسته‌بندی',
                            value: _selectedCategory,
                            items: const ['قدرتی', 'هوازی', 'تعادلی'],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                                _selectedTargetMuscle = null;
                              });
                            },
                            validator:
                                (value) =>
                                    value == null
                                        ? 'لطفاً یک دسته‌بندی انتخاب کنید'
                                        : null,
                          ),
                          const SizedBox(height: 20),

                          // عضله هدف
                          if (_selectedCategory == 'قدرتی')
                            _buildGlassDropdown(
                              label: 'عضله هدف',
                              value: _selectedTargetMuscle,
                              items: const [
                                'پا',
                                'شکم',
                                'سینه',
                                'بازو',
                                'زیربغل',
                                'سرشانه',
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedTargetMuscle = value;
                                });
                              },
                            ),
                          const SizedBox(height: 20),

                          // نوع شمارش
                          _buildGlassDropdown(
                            label: 'نوع شمارش',
                            value: _selectedCountingType,
                            items: const ['وزن (kg)', 'تعداد', 'تایم'],
                            onChanged: (value) {
                              setState(() {
                                _selectedCountingType = value;
                              });
                            },
                            validator:
                                (value) =>
                                    value == null
                                        ? 'لطفاً نوع شمارش را انتخاب کنید'
                                        : null,
                          ),
                          const SizedBox(height: 20),

                          // توضیحات
                          _buildGlassTextField(
                            controller: _descriptionController,
                            label: 'توضیحات (اختیاری)',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),

                          // نمایش و مدیریت تصویر
                          _buildMediaRow(),
                          const SizedBox(height: 30),

                          // دکمه ذخیره
                          _buildNeonButton(
                            text: 'ذخیره تغییرات',
                            onPressed: _updateExercise,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildGlassDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    String? Function(String?)? validator,
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
        validator: validator,
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

  Widget _buildMediaRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMediaButton(
              icon: Icons.image,
              label: 'عکس',
              file: _selectedImage,
              onPressed: _pickImage,
            ),
            _buildMediaButton(
              icon: Icons.videocam,
              label: 'ویدیو',
              file: _selectedVideo,
              onPressed: _pickVideo,
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_existingImageUrl != null &&
                _existingImageUrl!.isNotEmpty &&
                _selectedImage == null ||
            _selectedImage != null ||
            _existingVideoUrl != null &&
                _existingVideoUrl!.isNotEmpty &&
                _selectedVideo == null ||
            _selectedVideo != null)
          _buildMediaPreview(),
      ],
    ).animate().fadeIn(duration: 400.ms);
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

  Widget _buildMediaPreview() {
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
          if (_existingImageUrl != null &&
                  _existingImageUrl!.isNotEmpty &&
                  _selectedImage == null ||
              _selectedImage != null)
            Stack(
              children: [
                Builder(
                  builder: (context) {
                    if (_selectedImage != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _selectedImage!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    final uri = Uri.tryParse(_existingImageUrl!);
                    if (uri != null &&
                        (uri.scheme == 'http' || uri.scheme == 'https')) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _existingImageUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text(
                                'خطا در بارگذاری تصویر',
                                style: TextStyle(color: Colors.red),
                              ),
                            );
                          },
                        ),
                      );
                    } else if (uri != null && uri.scheme == 'file') {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(uri.path),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return const Center(
                      child: Text(
                        'تصویر نامعتبر',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: _removeImage,
                  ),
                ),
              ],
            ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
          if ((_existingImageUrl != null &&
                      _existingImageUrl!.isNotEmpty &&
                      _selectedImage == null ||
                  _selectedImage != null) &&
              (_existingVideoUrl != null &&
                      _existingVideoUrl!.isNotEmpty &&
                      _selectedVideo == null ||
                  _selectedVideo != null))
            const SizedBox(height: 10),
          if (_existingVideoUrl != null &&
                  _existingVideoUrl!.isNotEmpty &&
                  _selectedVideo == null ||
              _selectedVideo != null)
            Stack(
              children: [
                _videoLoadError
                    ? const SizedBox(
                      height: 150,
                      child: Center(
                        child: Text(
                          'خطا در بارگذاری ویدیو',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    )
                    : _videoController != null &&
                        _videoController!.value.isInitialized
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: VideoPlayer(_videoController!),
                          ),
                          IconButton(
                            icon: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_circle_fill,
                              size: 50,
                              color: Colors.yellowAccent,
                            ),
                            onPressed: () {
                              if (_videoController!.value.isPlaying) {
                                _videoController!.pause();
                              } else {
                                _videoController!.play();
                              }
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ).animate().scale(
                      duration: 300.ms,
                      curve: Curves.easeOutBack,
                    )
                    : const SizedBox(
                      height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: _removeVideo,
                  ),
                ),
              ],
            ),
        ],
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
}
