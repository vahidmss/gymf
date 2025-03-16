import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymf/data/models/Comment.dart';
import 'package:gymf/data/models/exercise_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart'; // برای فرمت تاریخ

class ExerciseDetailScreen extends StatefulWidget {
  final ExerciseModel exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _isDarkTheme = true;
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 0; // امتیاز انتخاب‌شده توسط کاربر
  List<Comment> _comments = []; // لیست نظرات
  bool _sortByNewest = true; // مرتب‌سازی بر اساس جدیدترین

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    // چند نظر نمونه برای تست
    _comments = [
      Comment(
        userName: "علی",
        text: "تمرین عالی بود، واقعاً حسابی عرق ریختم! 💪",
        rating: 5,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        likes: 10,
      ),
      Comment(
        userName: "سارا",
        text: "برای مبتدی‌ها یکم سخت بود، ولی خیلی خوب توضیح داده شده.",
        rating: 4,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        likes: 5,
      ),
    ];
  }

  @override
  void dispose() {
    _videoController?.pause();
    _videoController?.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    if (widget.exercise.videoUrl != null &&
        widget.exercise.videoUrl!.isNotEmpty) {
      try {
        final fileInfo = await DefaultCacheManager().getFileFromCache(
          widget.exercise.videoUrl!,
        );
        if (fileInfo != null && fileInfo.file.existsSync()) {
          _videoController = VideoPlayerController.file(fileInfo.file);
        } else {
          final file = await DefaultCacheManager().getSingleFile(
            widget.exercise.videoUrl!,
          );
          _videoController = VideoPlayerController.file(file);
        }

        await _videoController!.initialize();
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController!.setLooping(true);
        }
      } catch (e) {
        print('❌ خطا در مقداردهی ویدیوی تمرین: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در پخش ویدیو: $e')));
      }
    } else {
      _videoController = null;
    }
  }

  void _toggleVideoPlayback() {
    if (_isPlaying) {
      _videoController?.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      _videoController?.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _addComment() {
    if (_commentController.text.isEmpty || _selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً نظر و امتیاز را وارد کنید!')),
      );
      return;
    }

    setState(() {
      _comments.add(
        Comment(
          userName:
              "کاربر فعلی", // بعداً می‌تونی با Supabase نام کاربر رو بگیری
          text: _commentController.text,
          rating: _selectedRating,
          timestamp: DateTime.now(),
        ),
      );
      _commentController.clear();
      _selectedRating = 0;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('نظر شما با موفقیت ثبت شد!')));
  }

  void _sortComments() {
    setState(() {
      if (_sortByNewest) {
        _comments.sort(
          (a, b) => b.timestamp.compareTo(a.timestamp),
        ); // جدیدترین
      } else {
        _comments.sort((a, b) => b.likes.compareTo(a.likes)); // محبوب‌ترین
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              _isDarkTheme
                  ? [
                    Colors.black,
                    Colors.blueGrey.shade900,
                    Colors.yellow.shade800.withOpacity(0.3),
                  ]
                  : [
                    Colors.white,
                    Colors.blueGrey.shade100,
                    Colors.yellow.shade200,
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
            widget.exercise.name,
            style: GoogleFonts.vazirmatn(
              textStyle: TextStyle(
                color: _isDarkTheme ? Colors.yellow : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                shadows: [
                  Shadow(
                    color: _isDarkTheme ? Colors.black54 : Colors.grey.shade300,
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon:
                  Icon(
                    _isDarkTheme ? Icons.light_mode : Icons.dark_mode,
                  ).animate().rotate(),
              color: _isDarkTheme ? Colors.yellow : Colors.black87,
              onPressed: () {
                setState(() {
                  _isDarkTheme = !_isDarkTheme;
                });
              },
              tooltip: 'تغییر تم',
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // هدر با ویدیو یا تصویر
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              _isDarkTheme
                                  ? Colors.black54
                                  : Colors.grey.shade300,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      child:
                          widget.exercise.videoUrl != null &&
                                  widget.exercise.videoUrl!.isNotEmpty &&
                                  _isVideoInitialized &&
                                  _videoController != null
                              ? VideoPlayer(_videoController!)
                              : CachedNetworkImage(
                                imageUrl: widget.exercise.imageUrl ?? '',
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      color:
                                          _isDarkTheme
                                              ? Colors.blueGrey.shade800
                                              : Colors.grey.shade200,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      color:
                                          _isDarkTheme
                                              ? Colors.blueGrey.shade800
                                              : Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.fitness_center,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                    ),
                              ),
                    ),
                  ),
                  if (widget.exercise.videoUrl != null &&
                      widget.exercise.videoUrl!.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.yellow.withOpacity(0.9),
                        size: 60,
                      ),
                      onPressed:
                          _isVideoInitialized ? _toggleVideoPlayback : null,
                    ),
                ],
              ).animate().fadeIn(duration: 500.ms),
              const SizedBox(height: 20),
              // جزئیات تمرین
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دسته‌بندی: ${widget.exercise.category}',
                      style: GoogleFonts.vazirmatn(
                        color: _isDarkTheme ? Colors.white70 : Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                    if (widget.exercise.targetMuscle != null)
                      Text(
                        'عضله هدف: ${widget.exercise.targetMuscle}',
                        style: GoogleFonts.vazirmatn(
                          color: _isDarkTheme ? Colors.white70 : Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'توضیحات:',
                      style: GoogleFonts.vazirmatn(
                        color: _isDarkTheme ? Colors.yellow : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.exercise.description ?? 'توضیحاتی در دسترس نیست.',
                      style: GoogleFonts.vazirmatn(
                        color: _isDarkTheme ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ایجادشده توسط: ${widget.exercise.creatorUsername ?? 'ناشناس'}',
                      style: GoogleFonts.vazirmatn(
                        color: _isDarkTheme ? Colors.white54 : Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ).animate().slideY(begin: 0.5, duration: 500.ms),
              ),
              const SizedBox(height: 20),
              // دکمه‌های تعاملی
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.add_circle_outline,
                      label: 'اضافه به برنامه',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تمرین به برنامه اضافه شد!'),
                          ),
                        );
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.share,
                      label: 'اشتراک‌گذاری',
                      onTap: () {
                        Share.share(
                          'تمرین ${widget.exercise.name} رو توی اپ مدرسه بدنسازی ببین! 💪',
                        );
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.support_agent,
                      label: 'مخاطب مربی',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('به زودی اضافه می‌شود!'),
                          ),
                        );
                      },
                    ),
                  ],
                ).animate().scale(duration: 500.ms),
              ),
              const SizedBox(height: 20),
              // بخش نظرات
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'نظرات کاربران (${_comments.length})',
                          style: GoogleFonts.vazirmatn(
                            color:
                                _isDarkTheme ? Colors.yellow : Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _sortByNewest = !_sortByNewest;
                              _sortComments();
                            });
                          },
                          child: Text(
                            _sortByNewest ? 'محبوب‌ترین' : 'جدیدترین',
                            style: GoogleFonts.vazirmatn(
                              color:
                                  _isDarkTheme
                                      ? Colors.white70
                                      : Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // باکس ثبت نظر
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color:
                            _isDarkTheme
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color:
                              _isDarkTheme
                                  ? Colors.yellow.withOpacity(0.3)
                                  : Colors.black12,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                _isDarkTheme
                                    ? Colors.black26
                                    : Colors.grey.shade200,
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _commentController,
                            style: GoogleFonts.vazirmatn(
                              color:
                                  _isDarkTheme ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'نظر خود را بنویسید...',
                              hintStyle: GoogleFonts.vazirmatn(
                                color:
                                    _isDarkTheme
                                        ? Colors.white70
                                        : Colors.black54,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor:
                                  _isDarkTheme
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.shade100,
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: List.generate(5, (index) {
                                  return IconButton(
                                    icon: Icon(
                                      index < _selectedRating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.yellow,
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _selectedRating = index + 1;
                                      });
                                    },
                                  );
                                }),
                              ),
                              ElevatedButton(
                                onPressed: _addComment,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.yellow.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'ارسال',
                                  style: GoogleFonts.vazirmatn(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ).animate().scale(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    // لیست نظرات
                    _comments.isEmpty
                        ? Center(
                          child: Text(
                            'هنوز نظری ثبت نشده است.',
                            style: GoogleFonts.vazirmatn(
                              color:
                                  _isDarkTheme
                                      ? Colors.white70
                                      : Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return _buildCommentCard(comment, index);
                          },
                        ),
                  ],
                ).animate().fadeIn(duration: 500.ms),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentCard(Comment comment, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _isDarkTheme ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isDarkTheme ? Colors.yellow.withOpacity(0.2) : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDarkTheme ? Colors.black26 : Colors.grey.shade200,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                _isDarkTheme ? Colors.blueGrey.shade800 : Colors.grey.shade200,
            child: Text(
              comment.userName[0],
              style: GoogleFonts.vazirmatn(
                color: _isDarkTheme ? Colors.white : Colors.black87,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment.userName,
                      style: GoogleFonts.vazirmatn(
                        color: _isDarkTheme ? Colors.white : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < comment.rating ? Icons.star : Icons.star_border,
                          color: Colors.yellow,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  comment.text,
                  style: GoogleFonts.vazirmatn(
                    color: _isDarkTheme ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat(
                        'yyyy-MM-dd – HH:mm',
                      ).format(comment.timestamp),
                      style: GoogleFonts.vazirmatn(
                        color: _isDarkTheme ? Colors.white54 : Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.favorite,
                            color: comment.likes > 0 ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              comment.likes++;
                            });
                          },
                        ),
                        Text(
                          '${comment.likes}',
                          style: GoogleFonts.vazirmatn(
                            color:
                                _isDarkTheme ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.5);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: _isDarkTheme ? Colors.white.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                _isDarkTheme ? Colors.yellow.withOpacity(0.3) : Colors.black12,
          ),
          boxShadow: [
            BoxShadow(
              color: _isDarkTheme ? Colors.black26 : Colors.grey.shade200,
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _isDarkTheme ? Colors.yellow : Colors.black87,
              size: 20,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.vazirmatn(
                color: _isDarkTheme ? Colors.white70 : Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
