import 'package:dashboard_clone/constants/constants.dart';
import 'package:dashboard_clone/widgets/elevated_button.dart';
import 'package:flutter/material.dart';

class MultiSelectDropdown extends StatefulWidget {
  final String hint;
  final List<MultiSelectItem> items;
  final List<String> selectedValues;
  final Function(List<String>) onChanged;
  final InputDecoration? decoration;

  const MultiSelectDropdown({
    super.key,
    required this.hint,
    required this.items,
    required this.selectedValues,
    required this.onChanged,
    this.decoration,
  });

  @override
  State<MultiSelectDropdown> createState() => _MultiSelectDropdownState();
}

class _MultiSelectDropdownState extends State<MultiSelectDropdown> {
  void _showMultiSelectDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MultiSelectDialog(
          items: widget.items,
          selectedValues: widget.selectedValues,
          onConfirm: (values) {
            widget.onChanged(values);
          },
        );
      },
    );
  }

  String _getDisplayText() {
    if (widget.selectedValues.isEmpty) {
      return widget.hint;
    }
    final selectedItems = widget.items
        .where((item) => widget.selectedValues.contains(item.value))
        .map((item) => item.label)
        .toList();
    return selectedItems.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showMultiSelectDialog,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        child: InputDecorator(
          decoration:
              widget.decoration ??
              InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
          child: Text(
            _getDisplayText(),
            style: TextStyle(
              color: widget.selectedValues.isEmpty
                  ? Colors.grey[400]
                  : Colors.black87,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

class MultiSelectDialog extends StatefulWidget {
  final List<MultiSelectItem> items;
  final List<String> selectedValues;
  final Function(List<String>) onConfirm;

  const MultiSelectDialog({
    super.key,
    required this.items,
    required this.selectedValues,
    required this.onConfirm,
  });

  @override
  State<MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  late List<String> _tempSelectedValues;

  @override
  void initState() {
    super.initState();
    _tempSelectedValues = List.from(widget.selectedValues);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Select Options'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.items.map((item) {
            final isSelected = _tempSelectedValues.contains(item.value);
            return CheckboxListTile(
              title: Text(item.label),
              value: isSelected,
              onChanged: (bool? checked) {
                setState(() {
                  if (checked == true) {
                    _tempSelectedValues.add(item.value);
                  } else {
                    _tempSelectedValues.remove(item.value);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _tempSelectedValues.clear();
            });
          },
          child: const Text('Clear All'),
        ),
        ReusableButton(
          text: 'OK',
          backgroundColor: primaryColor,
          onPressed: () {
            widget.onConfirm(_tempSelectedValues);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class MultiSelectItem {
  final String value;
  final String label;

  MultiSelectItem({required this.value, required this.label});
}
