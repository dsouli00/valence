import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/enums.dart';
import '../../models/meal_model.dart';
import '../../services/firestore_service.dart';
import '../../services/food_ai_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

/// Three ways the client can log a meal.
enum _LogMode { photo, describe, manual }

/// Bottom sheet that lets the client log a meal via:
/// - **Photo**: pick from camera/gallery → AI analyses the image
/// - **Describe**: free-text description → AI estimates macros
/// - **Manual**: enter macros directly, no AI
class LogMealBottomSheet extends StatefulWidget {
  final String clientId;
  final String coachId;

  const LogMealBottomSheet({
    super.key,
    required this.clientId,
    required this.coachId,
  });

  @override
  State<LogMealBottomSheet> createState() => _LogMealBottomSheetState();
}

class _LogMealBottomSheetState extends State<LogMealBottomSheet> {
  _LogMode _mode = _LogMode.describe;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  bool _showResult = false;

  // Raw image bytes kept in memory until the meal is saved, then uploaded to Storage.
  Uint8List? _imageBytes;
  MealConfidence _aiConfidence = MealConfidence.manual;

  final _descriptionController = TextEditingController();
  final _nameController = TextEditingController();
  final _calsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  final _firestoreService = FirestoreService();
  final _foodAiService = FoodAiService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _descriptionController.dispose();
    _nameController.dispose();
    _calsController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _showResult = false;
      });
    } catch (e) {
      _showError('Could not access camera/gallery.');
    }
  }

  Future<void> _analyzeFood() async {
    final description = _descriptionController.text.trim();
    if (_mode == _LogMode.photo && _imageBytes == null) {
      _showError('Please select an image first.');
      return;
    }
    if (_mode == _LogMode.describe && description.isEmpty) {
      _showError('Please describe your meal.');
      return;
    }

    setState(() => _isAnalyzing = true);
    try {
      final result = await _foodAiService.analyzeFood(
        description: description.isEmpty ? null : description,
        imageBytes: _mode == _LogMode.photo ? _imageBytes : null,
      );
      if (result != null) {
        _nameController.text = result['name'] ?? '';
        _calsController.text = '${result['calories'] ?? ''}';
        _proteinController.text = '${result['protein'] ?? ''}';
        _carbsController.text = '${result['carbs'] ?? ''}';
        _fatController.text = '${result['fat'] ?? ''}';
        final confidenceStr = result['confidence'] as String?;
        _aiConfidence = confidenceStr == 'high'
            ? MealConfidence.high
            : confidenceStr == 'medium'
                ? MealConfidence.medium
                : MealConfidence.low;
        setState(() => _showResult = true);
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _saveMeal() async {
    final name = _nameController.text.trim();
    final cals = int.tryParse(_calsController.text);
    final protein = double.tryParse(_proteinController.text);
    final carbs = double.tryParse(_carbsController.text);
    final fat = double.tryParse(_fatController.text);

    if (name.isEmpty || cals == null || protein == null || carbs == null || fat == null) {
      _showError('Please fill in all fields.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Upload the photo to Firebase Storage (photo mode only) and get the URL.
      // Wrapped in try/catch so a failed upload (e.g. Spark free plan) never
      // blocks the meal from being saved — it just stores without an image URL.
      String? imageUrl;
      if (_mode == _LogMode.photo && _imageBytes != null) {
        try {
          imageUrl = await _storageService.uploadMealPhoto(
            widget.clientId,
            _imageBytes!,
          );
        } catch (e) {
          // Storage unavailable — proceed without image URL.
          debugPrint('Meal photo upload failed: $e');
        }
      }

      final meal = Meal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        calories: cals,
        protein: protein,
        carbs: carbs,
        fat: fat,
        imageUrl: imageUrl,
        aiConfidence: _mode == _LogMode.manual ? MealConfidence.manual : _aiConfidence,
        loggedAt: DateTime.now(),
      );
      await _firestoreService.addMealToLog(widget.clientId, meal);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Failed to save meal.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _switchMode(_LogMode mode) {
    setState(() {
      _mode = mode;
      _showResult = mode == _LogMode.manual;
      _imageBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.p16,
        top: AppSpacing.p16,
        left: AppSpacing.p16,
        right: AppSpacing.p16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withAlpha(50),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.p16),
            Text('Log a Meal',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: AppSpacing.p16),

            // Mode selector
            Row(
              children: [
                _ModeChip(
                  label: '📷 Photo',
                  selected: _mode == _LogMode.photo,
                  onTap: () => _switchMode(_LogMode.photo),
                ),
                SizedBox(width: AppSpacing.p8),
                _ModeChip(
                  label: '✍️ Describe',
                  selected: _mode == _LogMode.describe,
                  onTap: () => _switchMode(_LogMode.describe),
                ),
                SizedBox(width: AppSpacing.p8),
                _ModeChip(
                  label: '✏️ Manual',
                  selected: _mode == _LogMode.manual,
                  onTap: () => _switchMode(_LogMode.manual),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.p24),

            if (_mode == _LogMode.photo) _buildPhotoMode(theme, colorScheme),
            if (_mode == _LogMode.describe) _buildDescribeMode(colorScheme),
            if (_mode == _LogMode.manual) _buildResultFields(),

            if (_showResult && _mode != _LogMode.manual) ...[
              SizedBox(height: AppSpacing.p16),
              Text(
                'Edit & Confirm',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSpacing.p12),
              _buildResultFields(),
            ],

            SizedBox(height: AppSpacing.p24),

            if (_showResult || _mode == _LogMode.manual)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveMeal,
                  child: _isSaving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Text(
                          "Add to Today's Log",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoMode(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        if (_imageBytes != null) ...[
          ClipRRect(
            borderRadius: AppTheme.defaultBorderRadius,
            child: Image.memory(
              _imageBytes!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: AppSpacing.p12),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                label: const Text('Camera'),
              ),
            ),
            SizedBox(width: AppSpacing.p12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 20),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
        if (_imageBytes != null) ...[
          SizedBox(height: AppSpacing.p12),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Optional: describe portions or ingredients',
              labelText: 'Description (optional)',
            ),
          ),
          SizedBox(height: AppSpacing.p12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _analyzeFood,
              child: _isAnalyzing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Analyze Photo'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDescribeMode(ColorScheme colorScheme) {
    return Column(
      children: [
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g. "2 eggs, toast with butter, orange juice"',
            labelText: 'Meal Description',
          ),
        ),
        SizedBox(height: AppSpacing.p12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isAnalyzing ? null : _analyzeFood,
            child: _isAnalyzing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Analyze with AI'),
          ),
        ),
      ],
    );
  }

  Widget _buildResultFields() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Meal Name',
            prefixIcon: Icon(Icons.restaurant_outlined),
          ),
        ),
        SizedBox(height: AppSpacing.p12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _calsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Calories',
                  suffixText: 'kcal',
                ),
              ),
            ),
            SizedBox(width: AppSpacing.p12),
            Expanded(
              child: TextField(
                controller: _proteinController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Protein',
                  suffixText: 'g',
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.p12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _carbsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Carbs',
                  suffixText: 'g',
                ),
              ),
            ),
            SizedBox(width: AppSpacing.p12),
            Expanded(
              child: TextField(
                controller: _fatController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Fat',
                  suffixText: 'g',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondaryColor.withAlpha(30)
              : colorScheme.surfaceContainerHighest.withAlpha(50),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.secondaryColor
                : colorScheme.onSurfaceVariant.withAlpha(50),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.secondaryColor
                : colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
