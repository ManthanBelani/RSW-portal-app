import 'package:flutter/material.dart';
import '../constants/constants.dart';

class SearchableDropdown extends StatefulWidget {
  final String? value;
  final String hint;
  final List<Map<String, dynamic>> items;
  final Future<List<Map<String, dynamic>>> Function()?
  onDropdownOpen; // Optional function to load data when dropdown is opened
  final Function(String?) onChanged;
  final String idKey;
  final String nameKey;
  final String?
  displayText; // Optional display text to show when items list is empty

  const SearchableDropdown({
    Key? key,
    required this.value,
    required this.hint,
    required this.items,
    this.onDropdownOpen, // Optional function to load data when dropdown is opened
    required this.onChanged,
    this.idKey = 'id',
    this.nameKey = 'name',
    this.displayText, // Optional display text
  }) : super(key: key);

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isDropdownOpen = false;
  bool _isLoadingData = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    print(
      'SearchableDropdown init: ${widget.hint}, items count: ${widget.items.length}',
    );
  }

  @override
  void didUpdateWidget(SearchableDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update filtered items when items list changes
    if (oldWidget.items != widget.items) {
      _filteredItems = widget.items;
      print(
        'SearchableDropdown updated: ${widget.hint}, items count: ${widget.items.length}',
      );
      if (_isDropdownOpen) {
        // Schedule overlay update after build completes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_isDropdownOpen) {
            _updateOverlay();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          final name = item[widget.nameKey].toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
    _updateOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isDropdownOpen = false;
    _isLoadingData = false;
  }

  void _createOverlay() async {
    // Reset to show all items when opening dropdown
    _searchController.clear();

    // Check if we need to load data dynamically when the dropdown is opened
    if (widget.onDropdownOpen != null) {
      try {
        _isLoadingData = true;
        _filteredItems = []; // Clear current items while loading
        _updateOverlay();

        // Load the new data
        final newItems = await widget.onDropdownOpen!();
        _filteredItems = newItems;
        _isLoadingData = false;
        _updateOverlay();
      } catch (e) {
        print('Error loading dropdown data: $e');
        _isLoadingData = false;
        _filteredItems = widget.items; // Fallback to existing items
        _updateOverlay();
      }
    } else {
      _filteredItems = widget.items;
    }

    print(
      'Opening dropdown: ${widget.hint}, showing ${_filteredItems.length} items',
    );

    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _isDropdownOpen = true;
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _buildOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent background to catch taps outside
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                // Close dropdown when tapping outside
                _removeOverlay();
                _focusNode.unfocus();
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // Dropdown content
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0.0, size.height + 5.0),
              child: Material(
                elevation: 8.0,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _isLoadingData
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF4A90E2),
                          ),
                        ),
                      ),
                    )
                  : _filteredItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No results found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final itemId = item[widget.idKey]?.toString();
                        final widgetValue = widget.value?.toString();
                        final isSelected = itemId == widgetValue;
                        return InkWell(
                          onTap: () {
                            final selectedId = item[widget.idKey]?.toString();
                            final selectedName = item[widget.nameKey]
                                ?.toString();
                            print(
                              'SearchableDropdown - Item tapped: id=$selectedId, name=$selectedName',
                            );
                            print(
                              'SearchableDropdown - idKey=${widget.idKey}, nameKey=${widget.nameKey}',
                            );
                            print('SearchableDropdown - Full item: $item');
                            widget.onChanged(selectedId);
                            _searchController.clear();
                            _filteredItems = widget.items;
                            _removeOverlay();
                            _focusNode.unfocus();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor.withOpacity(0.1)
                                  : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Text(
                              item[widget.nameKey]?.toString() ?? '',
                              style: TextStyle(
                                color: isSelected
                                    ? primaryColor
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSelectedName() {
    if (widget.value == null) return '';
    try {
      final selected = widget.items.firstWhere(
        (item) => item[widget.idKey]?.toString() == widget.value,
        orElse: () => <String, dynamic>{},
      );
      return selected[widget.nameKey]?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          if (_isDropdownOpen) {
            _removeOverlay();
            _focusNode.unfocus();
          } else {
            _focusNode.requestFocus();
            _createOverlay();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isDropdownOpen ? primaryColor : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _isDropdownOpen
                    ? TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: _filterItems,
                      )
                    : GestureDetector(
                        onTap: () {
                          _focusNode.requestFocus();
                          _createOverlay();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          alignment: Alignment.centerLeft,
                          child: Builder(
                            builder: (context) {
                              final selectedName = _getSelectedName();
                              final displayValue = widget.value == null
                                  ? widget.hint
                                  : (widget.displayText ?? selectedName);
                              print(
                                'SearchableDropdown - value: ${widget.value}, displayText: ${widget.displayText}, selectedName: $selectedName, displayValue: $displayValue',
                              );
                              return Text(
                                displayValue.isEmpty ? widget.hint : displayValue,
                                style: TextStyle(
                                  color: widget.value == null || displayValue.isEmpty
                                      ? Colors.grey[400]
                                      : Colors.black,
                                  fontSize: 14,
                                  fontWeight: widget.value != null && displayValue.isNotEmpty 
                                      ? FontWeight.w500 
                                      : FontWeight.normal,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ),
              if (widget.value != null)
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
                  onPressed: () {
                    widget.onChanged(null);
                    _searchController.clear();
                    _filteredItems = widget.items;
                    _removeOverlay();
                    _focusNode.unfocus();
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Icon(
                    _isDropdownOpen
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
