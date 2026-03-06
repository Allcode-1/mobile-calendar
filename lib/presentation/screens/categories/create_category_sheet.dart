import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/icon_mapper.dart';
import '../../../../logic/category_provider.dart';
import '../../../../data/models/category_model.dart';

class CreateCategorySheet extends ConsumerStatefulWidget {
  final CategoryModel? category;
  const CreateCategorySheet({super.key, this.category});

  @override
  ConsumerState<CreateCategorySheet> createState() =>
      _CreateCategorySheetState();
}

class _CreateCategorySheetState extends ConsumerState<CreateCategorySheet> {
  late TextEditingController _nameController;
  late String _selectedIcon;
  late Color _selectedColor;

  final List<Color> _colors = [
    AppColors.primary,
    const Color(0xFF636AFF),
    const Color(0xFFFF5733),
    const Color(0xFF2ECC71),
    const Color(0xFFF1C40F),
    const Color(0xFF9B59B6),
    const Color(0xFFE74C3C),
    const Color(0xFF1ABC9C),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? "");
    _selectedIcon = widget.category?.icon ?? IconMapper.allNames.first;
    _selectedColor = widget.category?.flutterColor ?? AppColors.primary;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.category != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? "Edit Category" : "New Category",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Category Name",
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Select Icon",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: IconMapper.allNames.length,
              itemBuilder: (context, index) {
                final iconName = IconMapper.allNames[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = iconName),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedIcon == iconName
                          ? _selectedColor
                          : AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconMapper.getIcon(iconName),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Select Color",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final color = _colors[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _selectedColor.toARGB32() == color.toARGB32()
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                if (_nameController.text.isEmpty) return;
                final colorArgb = _selectedColor.toARGB32();
                final String colorHex =
                    '#${(colorArgb & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

                bool success;
                if (isEdit) {
                  success = await ref
                      .read(categoryProvider.notifier)
                      .updateCategory(
                        id: widget.category!.id,
                        name: _nameController.text,
                        colorHex: colorHex,
                        icon: _selectedIcon,
                      );
                } else {
                  success = await ref
                      .read(categoryProvider.notifier)
                      .createCategory(
                        _nameController.text,
                        colorHex,
                        _selectedIcon,
                      );
                }

                if (!context.mounted) return;
                if (success) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                isEdit ? "Update" : "Create",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
