import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymf/data/models/exercise_model.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final ExerciseModel exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  VideoPlayerController? _videoController;
  bool _isLoadingVideo = true;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeImage();
  }

  void _initializeVideo() {
    if (widget.exercise.videoUrl != null &&
        widget.exercise.videoUrl!.isNotEmpty) {
      final uri = Uri.tryParse(widget.exercise.videoUrl!);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        _videoController = VideoPlayerController.network(
            widget.exercise.videoUrl!,
          )
          ..initialize()
              .then((_) {
                if (mounted) {
                  setState(() {
                    _isLoadingVideo = false;
                  });
                }
              })
              .catchError((e) {
                print('❌ خطا در مقداردهی ویدیوی شبکه‌ای: $e');
                setState(() {
                  _isLoadingVideo = false;
                });
              });
      } else if (uri != null && uri.scheme == 'file') {
        _videoController = VideoPlayerController.file(File(uri.path))
          ..initialize()
              .then((_) {
                if (mounted) {
                  setState(() {
                    _isLoadingVideo = false;
                  });
                }
              })
              .catchError((e) {
                print('❌ خطا در مقداردهی ویدیوی محلی: $e');
                setState(() {
                  _isLoadingVideo = false;
                });
              });
      } else {
        setState(() {
          _isLoadingVideo = false;
        });
      }
    } else {
      setState(() {
        _isLoadingVideo = false;
      });
    }
  }

  void _initializeImage() {
    if (widget.exercise.imageUrl != null &&
        widget.exercise.imageUrl!.isNotEmpty) {
      Image.network(widget.exercise.imageUrl!).image
          .resolve(const ImageConfiguration())
          .addListener(
            ImageStreamListener(
              (info, synchronousCall) {
                if (mounted) {
                  setState(() {
                    _isLoadingImage = false;
                  });
                }
              },
              onError: (exception, stackTrace) {
                print('❌ خطا در بارگذاری تصویر: $exception');
                setState(() {
                  _isLoadingImage = false;
                });
              },
            ),
          );
    } else {
      setState(() {
        _isLoadingImage = false;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black,
            Colors.blueGrey.shade900,
            Colors.yellow.shade800,
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
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 5),
                  Shadow(
                    color: _getCategoryColor(widget.exercise.category),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.yellow),
              onPressed: () {
                Share.share(
                  'این تمرین رو توی مدرسه بدنسازی ببین: ${widget.exercise.name}\nدسته‌بندی: ${widget.exercise.category}',
                  subject: 'تمرین بدنسازی: ${widget.exercise.name}',
                );
              },
              tooltip: 'اشتراک‌گذاری',
            ),
          ],
        ),
        body:
            _isLoadingVideo || _isLoadingImage
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
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
                        // تصویر
                        if (widget.exercise.imageUrl != null &&
                            widget.exercise.imageUrl!.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => Scaffold(
                                        backgroundColor: Colors.black,
                                        body: PhotoView(
                                          imageProvider: NetworkImage(
                                            widget.exercise.imageUrl!,
                                          ),
                                          backgroundDecoration:
                                              const BoxDecoration(
                                                color: Colors.black,
                                              ),
                                          minScale:
                                              PhotoViewComputedScale.contained,
                                          maxScale:
                                              PhotoViewComputedScale.covered *
                                              2,
                                        ),
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.yellow.withOpacity(0.3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(
                                  widget.exercise.imageUrl!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Colors.blueGrey.shade800,
                                      child: const Center(
                                        child: Text(
                                          'خطا در بارگذاری تصویر',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                        // ویدیو
                        if (widget.exercise.videoUrl != null &&
                            widget.exercise.videoUrl!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.yellow.withOpacity(0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26.withOpacity(0.2),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child:
                                  _videoController != null &&
                                          _videoController!.value.isInitialized
                                      ? Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          AspectRatio(
                                            aspectRatio:
                                                _videoController!
                                                    .value
                                                    .aspectRatio,
                                            child: VideoPlayer(
                                              _videoController!,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              _videoController!.value.isPlaying
                                                  ? Icons.pause
                                                  : Icons.play_circle_fill,
                                              size: 50,
                                              color: Colors.yellow,
                                            ),
                                            onPressed: () {
                                              if (_videoController!
                                                  .value
                                                  .isPlaying) {
                                                _videoController!.pause();
                                              } else {
                                                _videoController!.play();
                                              }
                                              setState(() {});
                                            },
                                          ),
                                        ],
                                      )
                                      : Container(
                                        height: 200,
                                        color: Colors.blueGrey.shade800,
                                        child: const Center(
                                          child: Text(
                                            'خطا در بارگذاری ویدیو',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ),
                            ),
                          ),

                        // اطلاعات تمرین
                        _buildInfoCard('نام تمرین', widget.exercise.name),
                        _buildInfoCard('دسته‌بندی', widget.exercise.category),
                        if (widget.exercise.targetMuscle != null)
                          _buildInfoCard(
                            'عضله هدف',
                            widget.exercise.targetMuscle!,
                          ),
                        _buildInfoCard(
                          'نوع شمارش',
                          widget.exercise.countingType ?? 'نامشخص',
                        ),
                        if (widget.exercise.description != null &&
                            widget.exercise.description!.isNotEmpty)
                          _buildInfoCard(
                            'توضیحات',
                            widget.exercise.description!,
                          ),
                        _buildInfoCard(
                          'ایجادشده توسط',
                          widget.exercise.creatorUsername ?? 'ناشناس',
                        ),
                        _buildInfoCard(
                          'تاریخ ایجاد',
                          widget.exercise.createdAt.toIso8601String().split(
                            'T',
                          )[0],
                        ),
                        if (widget.exercise.updatedAt != null)
                          _buildInfoCard(
                            'آخرین ویرایش',
                            widget.exercise.updatedAt!.toIso8601String().split(
                              'T',
                            )[0],
                          ),
                        const SizedBox(height: 20),
                        // دکمه تمرین‌های مشابه
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('به زودی اضافه می‌شه!'),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getCategoryColor(
                                widget.exercise.category,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            child: Text(
                              'تمرین‌های مشابه',
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.yellow.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        gradient: LinearGradient(
          colors: [
            _getCategoryColor(widget.exercise.category).withOpacity(0.2),
            Colors.black.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.vazirmatn(
              color: Colors.yellow,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 5),
                Shadow(
                  color: _getCategoryColor(widget.exercise.category),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.vazirmatn(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'قدرتی':
        return Colors.redAccent;
      case 'هوازی':
        return Colors.greenAccent;
      case 'تعادلی':
        return Colors.blueAccent;
      default:
        return Colors.yellow;
    }
  }
}
