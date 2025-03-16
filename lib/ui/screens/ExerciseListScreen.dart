import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymf/data/models/exercise_model.dart';
import 'package:gymf/providers/exercise_provider.dart';
import 'package:gymf/ui/screens/ExerciseDetailScreen.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ExerciseListScreen extends StatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedTargetMuscle;
  List<ExerciseModel> _filteredExercises = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isDarkTheme = true; // برای سوئیچ تم

  @override
  void initState() {
    super.initState();
    _fetchExercises();
    _searchController.addListener(_filterExercises);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchExercises() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final provider = Provider.of<ExerciseProvider>(context, listen: false);
      await provider.fetchAllExercises();
      setState(() {
        _filteredExercises = provider.exercises;
      });
    } catch (e) {
      print('❌ خطا در بارگذاری تمرین‌ها: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در بارگذاری تمرین‌ها: $e')));
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterExercises() {
    final provider = Provider.of<ExerciseProvider>(context, listen: false);
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredExercises =
          provider.exercises.where((exercise) {
            final matchesSearch = exercise.name.toLowerCase().contains(query);
            final matchesCategory =
                _selectedCategory == null ||
                exercise.category == _selectedCategory;
            final matchesTargetMuscle =
                _selectedTargetMuscle == null ||
                exercise.targetMuscle == _selectedTargetMuscle;
            return matchesSearch && matchesCategory && matchesTargetMuscle;
          }).toList();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? tempCategory = _selectedCategory;
        String? tempTargetMuscle = _selectedTargetMuscle;
        return AlertDialog(
          backgroundColor: Colors.blueGrey.shade900.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'فیلتر تمرین‌ها',
            style: GoogleFonts.vazirmatn(color: Colors.yellow),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: tempCategory,
                  decoration: InputDecoration(
                    labelText: 'دسته‌بندی',
                    labelStyle: GoogleFonts.vazirmatn(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: Colors.blueGrey.shade800,
                  style: GoogleFonts.vazirmatn(color: Colors.white),
                  items:
                      ['قدرتی', 'هوازی', 'تعادلی', null]
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category ?? 'همه'),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    tempCategory = value;
                    if (tempCategory != 'قدرتی') tempTargetMuscle = null;
                  },
                ),
                const SizedBox(height: 10),
                if (tempCategory == 'قدرتی')
                  DropdownButtonFormField<String>(
                    value: tempTargetMuscle,
                    decoration: InputDecoration(
                      labelText: 'عضله هدف',
                      labelStyle: GoogleFonts.vazirmatn(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: Colors.blueGrey.shade800,
                    style: GoogleFonts.vazirmatn(color: Colors.white),
                    items:
                        ['پا', 'شکم', 'سینه', 'بازو', 'زیربغل', 'سرشانه', null]
                            .map(
                              (muscle) => DropdownMenuItem(
                                value: muscle,
                                child: Text(muscle ?? 'همه'),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      tempTargetMuscle = value;
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _selectedTargetMuscle = null;
                  _filterExercises();
                });
                Navigator.pop(context);
              },
              child: Text(
                'ریست',
                style: GoogleFonts.vazirmatn(color: Colors.redAccent),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = tempCategory;
                  _selectedTargetMuscle = tempTargetMuscle;
                  _filterExercises();
                });
                Navigator.pop(context);
              },
              child: Text(
                'اعمال',
                style: GoogleFonts.vazirmatn(color: Colors.yellow),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'لغو',
                style: GoogleFonts.vazirmatn(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _filterMyExercises() {
    final provider = Provider.of<ExerciseProvider>(context, listen: false);
    final userId = provider.authProvider.userId ?? '';
    setState(() {
      _filteredExercises =
          provider.exercises
              .where((exercise) => exercise.createdBy == userId)
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExerciseProvider>(context);
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
            'مدرسه بدنسازی',
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
              icon: const Icon(Icons.filter_list).animate().scale(),
              color: _isDarkTheme ? Colors.yellow : Colors.black87,
              onPressed: _showFilterDialog,
            ),
            IconButton(
              icon: const Icon(Icons.person).animate().scale(),
              color: _isDarkTheme ? Colors.yellow : Colors.black87,
              onPressed: _filterMyExercises,
              tooltip: 'تمرین‌های من',
            ),
            IconButton(
              icon: const Icon(Icons.add).animate().scale(),
              color: _isDarkTheme ? Colors.yellow : Colors.black87,
              onPressed: () {
                Navigator.pushNamed(context, '/submit-exercise');
              },
            ),
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
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'خطا در بارگذاری تمرین‌ها',
                        style: GoogleFonts.vazirmatn(
                          color: _isDarkTheme ? Colors.white70 : Colors.black54,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _fetchExercises,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'تلاش دوباره',
                          style: GoogleFonts.vazirmatn(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                )
                : Column(
                  children: [
                    // باکس جستجو با افکت شیشه‌ای
                    Container(
                      margin: const EdgeInsets.all(15),
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color:
                            _isDarkTheme
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color:
                              _isDarkTheme
                                  ? Colors.yellow.withOpacity(0.3)
                                  : Colors.black12,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.vazirmatn(
                          color: _isDarkTheme ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'جستجوی تمرین...',
                          hintStyle: GoogleFonts.vazirmatn(
                            color:
                                _isDarkTheme ? Colors.white70 : Colors.black54,
                          ),
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            Icons.search,
                            color:
                                _isDarkTheme ? Colors.yellow : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child:
                          _filteredExercises.isEmpty
                              ? Center(
                                child: Text(
                                  'تمرینی پیدا نشد',
                                  style: GoogleFonts.vazirmatn(
                                    color:
                                        _isDarkTheme
                                            ? Colors.white70
                                            : Colors.black54,
                                    fontSize: 18,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.all(15),
                                itemCount: _filteredExercises.length,
                                cacheExtent: 1000, // بهینه‌سازی اسکرول
                                itemBuilder: (context, index) {
                                  final exercise = _filteredExercises[index];
                                  return _buildExerciseCard(
                                    exercise,
                                    provider,
                                    index,
                                  );
                                },
                              ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildExerciseCard(
    ExerciseModel exercise,
    ExerciseProvider provider,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDetailScreen(exercise: exercise),
          ),
        );
      },
      child:
          Container(
            margin: const EdgeInsets.only(bottom: 15),
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
                          ? Colors.black26.withOpacity(0.3)
                          : Colors.grey.shade300,
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(3, 3),
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  _getCategoryColor(exercise.category).withOpacity(0.2),
                  _isDarkTheme ? Colors.black.withOpacity(0.5) : Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child:
                          exercise.imageUrl != null &&
                                  exercise.imageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                imageUrl: exercise.imageUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      width: 80,
                                      height: 80,
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
                                      width: 80,
                                      height: 80,
                                      color:
                                          _isDarkTheme
                                              ? Colors.blueGrey.shade800
                                              : Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.fitness_center,
                                        color: Colors.white,
                                      ),
                                    ),
                              )
                              : Container(
                                width: 80,
                                height: 80,
                                color:
                                    _isDarkTheme
                                        ? Colors.blueGrey.shade800
                                        : Colors.grey.shade200,
                                child: const Icon(
                                  Icons.fitness_center,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                    // آیکون ویدیو برای تمرین‌هایی که ویدیو دارن
                    if (exercise.videoUrl != null &&
                        exercise.videoUrl!.isNotEmpty)
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.play_circle_filled,
                            color: Colors.yellow,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: GoogleFonts.vazirmatn(
                          color: _isDarkTheme ? Colors.yellow : Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color:
                                  _isDarkTheme
                                      ? Colors.black54
                                      : Colors.grey.shade300,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'دسته‌بندی: ${exercise.category}',
                        style: GoogleFonts.vazirmatn(
                          color: _isDarkTheme ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                      if (exercise.targetMuscle != null)
                        Text(
                          'عضله هدف: ${exercise.targetMuscle}',
                          style: GoogleFonts.vazirmatn(
                            color:
                                _isDarkTheme ? Colors.white70 : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      Text(
                        'ایجادشده توسط: ${exercise.creatorUsername ?? 'ناشناس'}',
                        style: GoogleFonts.vazirmatn(
                          color: _isDarkTheme ? Colors.white54 : Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border).animate().scale(),
                  color: _isDarkTheme ? Colors.yellow : Colors.black54,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('به زودی اضافه می‌شه!')),
                    );
                  },
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).scale(),
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
