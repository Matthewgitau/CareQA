import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================
// 1. REUSABLE DROPDOWN - FROM SUPABASE TABLE
// ============================================
class SupabaseDropdown<T> extends StatefulWidget {
  final String table;
  final String displayField;
  final String? valueField;
  final String? filterColumn;
  final dynamic filterValue;
  final T? selectedValue;
  final Function(T?) onChanged;
  final String labelText;
  final String? hintText;
  final bool required;
  final String? orderBy;
  final IconData? prefixIcon;

  const SupabaseDropdown({
    Key? key,
    required this.table,
    required this.displayField,
    this.valueField,
    this.filterColumn,
    this.filterValue,
    this.selectedValue,
    required this.onChanged,
    required this.labelText,
    this.hintText,
    this.required = false,
    this.orderBy,
    this.prefixIcon,
  }) : super(key: key);

  @override
  State<SupabaseDropdown<T>> createState() => _SupabaseDropdownState<T>();
}

class _SupabaseDropdownState<T> extends State<SupabaseDropdown<T>> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  T? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedValue;
    _loadItems();
  }

  @override
  void didUpdateWidget(SupabaseDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue) {
      setState(() => _selectedId = widget.selectedValue);
    }
  }

  Future<void> _loadItems() async {
    setState(() { _loading = true; _error = null; });
    try {
      final supabase = Supabase.instance.client;
      dynamic query = supabase.from(widget.table).select('*');
      
      if (widget.filterColumn != null && widget.filterValue != null) {
        query = query.eq(widget.filterColumn!, widget.filterValue);
      }
      
      if (widget.orderBy != null) {
        query = query.order(widget.orderBy!);
      }
      
      final response = await query as List;
      setState(() {
        _items = response.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoading();
    }
    if (_error != null) {
      return _buildError();
    }

    final valueField = widget.valueField ?? 'id';
    final displayField = widget.displayField;

    return DropdownButtonFormField<T>(
      value: _selectedId,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        border: const OutlineInputBorder(),
        suffixText: widget.required ? '*' : null,
      ),
      items: [
        if (!widget.required)
          const DropdownMenuItem(value: null, child: Text('Select...')),
        ..._items.map((item) => DropdownMenuItem<T>(
          value: item[valueField] as T?,
          child: Text(item[displayField]?.toString() ?? 'Unknown'),
        )),
      ],
      onChanged: (value) {
        setState(() => _selectedId = value);
        widget.onChanged(value);
      },
      validator: widget.required ? (v) => v == null ? 'Required' : null : null,
    );
  }

  Widget _buildLoading() => Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(4),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    child: const Row(
      children: [
        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        SizedBox(width: 12),
        Text('Loading...'),
      ],
    ),
  );

  Widget _buildError() => Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.red.shade300),
      borderRadius: BorderRadius.circular(4),
    ),
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade700),
        const SizedBox(width: 8),
        Expanded(child: Text('Error loading: $_error', style: TextStyle(color: Colors.red.shade700, fontSize: 12))),
        TextButton(
          onPressed: _loadItems,
          child: const Text('Retry', style: TextStyle(fontSize: 12)),
        ),
      ],
    ),
  );
}

// ============================================
// 2. REUSABLE EMPLOYEE DROPDOWN (all staff + carers)
// ============================================
class EmployeeDropdown extends StatefulWidget {
  final String? selectedEmployeeId;
  final Function(String?) onChanged;
  final String labelText;
  final bool required;

  const EmployeeDropdown({
    Key? key,
    this.selectedEmployeeId,
    required this.onChanged,
    this.labelText = 'Employee',
    this.required = true,
  }) : super(key: key);

  @override
  State<EmployeeDropdown> createState() => _EmployeeDropdownState();
}

class _EmployeeDropdownState extends State<EmployeeDropdown> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() { _loading = true; _error = null; });
    try {
      final supabase = Supabase.instance.client;
      final allEmployees = <Map<String, dynamic>>[];

      // Get non-carer staff from profiles
      final staffResponse = await supabase
          .from('profiles')
          .select('id, full_name, email, role')
          .neq('role', 'carer')
          .order('full_name', ascending: true);
      
      for (final staff in staffResponse) {
        allEmployees.add({
          'id': staff['id'],
          'name': staff['full_name'],
          'type': 'staff',
        });
      }

      // Get carers from carers table
      final carersResponse = await supabase
          .from('carers')
          .select('id, name, employee_number')
          .eq('is_active', true)
          .order('name', ascending: true);
      
      for (final carer in carersResponse) {
        allEmployees.add({
          'id': carer['id'],
          'name': carer['name'],
          'type': 'carer',
        });
      }

      if (mounted) {
        setState(() {
          _items = allEmployees;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: const Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Loading employees...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(child: Text('Error: $_error', style: TextStyle(color: Colors.red.shade700, fontSize: 12))),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: widget.selectedEmployeeId,
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.people),
        suffixText: widget.required ? '*' : null,
      ),
      items: [
        if (!widget.required)
          const DropdownMenuItem<String>(value: null, child: Text('Select employee...')),
        ..._items.map((item) => DropdownMenuItem<String>(
          value: item['id'] as String,
          child: Text('${item['name']} (${item['type'] == 'carer' ? 'Carer' : 'Staff'})'),
        )),
      ],
      onChanged: widget.onChanged,
      validator: widget.required ? (v) => v == null ? 'Required' : null : null,
    );
  }
}

// ============================================
// 3. REUSABLE STAFF DROPDOWN (legacy - use EmployeeDropdown instead)
// ============================================
class StaffDropdown extends StatelessWidget {
  final String? selectedStaffId;
  final Function(String?) onChanged;
  final String labelText;
  final bool required;

  const StaffDropdown({
    Key? key,
    this.selectedStaffId,
    required this.onChanged,
    this.labelText = 'Staff Member',
    this.required = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmployeeDropdown(
      selectedEmployeeId: selectedStaffId,
      onChanged: onChanged,
      labelText: labelText,
      required: required,
    );
  }
}

// ============================================
// 4. REUSABLE SERVICE USER DROPDOWN
// ============================================
class ServiceUserDropdown extends StatelessWidget {
  final String? selectedUserId;
  final Function(String?) onChanged;
  final String labelText;
  final bool required;

  const ServiceUserDropdown({
    Key? key,
    this.selectedUserId,
    required this.onChanged,
    this.labelText = 'Service User',
    this.required = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SupabaseDropdown<String>(
      table: 'service_users',
      displayField: 'name',
      valueField: 'id',
      selectedValue: selectedUserId,
      onChanged: onChanged,
      labelText: labelText,
      required: required,
      orderBy: 'name',
      prefixIcon: Icons.person_outline,
    );
  }
}

// ============================================
// 4. REUSABLE CARER DROPDOWN
// ============================================
class CarerDropdown extends StatelessWidget {
  final String? selectedCarerId;
  final Function(String?) onChanged;
  final String labelText;
  final bool required;
  final bool showEmployeeNumber;

  const CarerDropdown({
    Key? key,
    this.selectedCarerId,
    required this.onChanged,
    this.labelText = 'Carer',
    this.required = true,
    this.showEmployeeNumber = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SupabaseDropdown<String>(
      table: 'carers',
      displayField: 'name',
      valueField: 'id',
      selectedValue: selectedCarerId,
      onChanged: onChanged,
      labelText: labelText,
      required: required,
      orderBy: 'name',
      prefixIcon: Icons.health_and_safety,
    );
  }
}

// ============================================
// 5. REUSABLE DROPDOWN - STATIC OPTIONS
// ============================================
class StaticDropdown extends StatelessWidget {
  final String? selectedValue;
  final Function(String?) onChanged;
  final String labelText;
  final List<String> options;
  final bool required;

  const StaticDropdown({
    Key? key,
    this.selectedValue,
    required this.onChanged,
    required this.labelText,
    required this.options,
    this.required = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        suffixText: required ? '*' : null,
      ),
      items: [
        if (!required)
          const DropdownMenuItem<String>(value: null, child: Text('Select...')),
        ...options.map((option) => DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        )),
      ],
      onChanged: onChanged,
      validator: required ? (v) => v == null ? 'Required' : null : null,
    );
  }
}

// ============================================
// 6. REUSABLE SEARCHABLE DROPDOWN (with filter)
// ============================================
class SearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) displayField;
  final String? Function(T)? valueField;
  final T? selectedValue;
  final Function(T?) onChanged;
  final String labelText;
  final bool required;

  const SearchableDropdown({
    Key? key,
    required this.items,
    required this.displayField,
    this.valueField,
    this.selectedValue,
    required this.onChanged,
    required this.labelText,
    this.required = false,
  }) : super(key: key);

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: '${widget.labelText} (Search)',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _filteredItems = widget.items);
              },
            ),
          ),
          onChanged: (value) {
            setState(() {
              _filteredItems = widget.items.where((item) =>
                widget.displayField(item).toLowerCase().contains(value.toLowerCase())
              ).toList();
            });
          },
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ListView.builder(
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              final item = _filteredItems[index];
              final isSelected = item == widget.selectedValue;
              return ListTile(
                title: Text(widget.displayField(item)),
                selected: isSelected,
                selectedTileColor: Colors.blue.shade50,
                onTap: () {
                  widget.onChanged(item);
                  Navigator.pop(context);
                },
                trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}