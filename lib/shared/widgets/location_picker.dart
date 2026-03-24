import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'searchable_dropdown_field.dart';

/// Cached country data loaded from the CSCPickerPlus package JSON
List<_CountryData>? _cachedCountries;

class _CountryData {
  final String name;
  final List<_StateData> states;

  _CountryData({required this.name, required this.states});
}

class _StateData {
  final String name;
  final List<String> cities;

  _StateData({required this.name, required this.cities});
}

Future<List<_CountryData>> _loadCountries() async {
  if (_cachedCountries != null) return _cachedCountries!;

  final jsonString = await rootBundle.loadString(
    'packages/csc_picker_plus/lib/assets/countries.json',
  );
  final List<dynamic> jsonList = json.decode(jsonString);

  _cachedCountries = jsonList.map((countryJson) {
    final states = (countryJson['state'] as List<dynamic>?)
            ?.map((stateJson) {
              final cities = (stateJson['city'] as List<dynamic>?)
                      ?.map((cityJson) => cityJson['name'] as String)
                      .toList() ??
                  [];
              return _StateData(
                name: stateJson['name'] as String,
                cities: cities,
              );
            })
            .toList() ??
        [];

    return _CountryData(
      name: countryJson['name'] as String,
      states: states,
    );
  }).toList();

  return _cachedCountries!;
}

class LocationPicker extends StatefulWidget {
  final String? currentCountry;
  final String? currentState;
  final String? currentCity;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String?> onStateChanged;
  final ValueChanged<String?> onCityChanged;
  final bool isVertical;

  const LocationPicker({
    super.key,
    this.currentCountry,
    this.currentState,
    this.currentCity,
    required this.onCountryChanged,
    required this.onStateChanged,
    required this.onCityChanged,
    this.isVertical = false,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  List<_CountryData> _countries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final countries = await _loadCountries();
    if (mounted) {
      setState(() {
        _countries = countries;
        _isLoading = false;
      });
    }
  }

  List<String> get _countryNames =>
      _countries.map((c) => c.name).toList();

  List<String> get _stateNames {
    if (widget.currentCountry == null) return [];
    final country = _countries.firstWhere(
      (c) => c.name == widget.currentCountry,
      orElse: () => _CountryData(name: '', states: []),
    );
    return country.states.map((s) => s.name).toList();
  }

  List<String> get _cityNames {
    if (widget.currentCountry == null || widget.currentState == null) return [];
    final country = _countries.firstWhere(
      (c) => c.name == widget.currentCountry,
      orElse: () => _CountryData(name: '', states: []),
    );
    final state = country.states.firstWhere(
      (s) => s.name == widget.currentState,
      orElse: () => _StateData(name: '', cities: []),
    );
    return state.cities;
  }

  Widget _buildDropdown(String? value, List<String> items, String hint, String title, bool enabled, ValueChanged<String?> onChanged) {
    return SearchableDropdownField(
      value: value,
      items: items,
      hint: hint,
      title: title,
      enabled: enabled,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      final loadingWidget = Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade100,
        ),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );

      if (widget.isVertical) {
        return Column(
          children: [
            loadingWidget,
            const SizedBox(height: 12),
            loadingWidget,
            const SizedBox(height: 12),
            loadingWidget,
          ],
        );
      }

      return Row(
        children: [
          Expanded(child: loadingWidget),
          const SizedBox(width: 16),
          Expanded(child: loadingWidget),
          const SizedBox(width: 16),
          Expanded(child: loadingWidget),
        ],
      );
    }

    final countryField = _buildDropdown(
      widget.currentCountry,
      _countryNames,
      'Country',
      'Country',
      true,
      (value) {
        widget.onCountryChanged(value);
        widget.onStateChanged(null);
        widget.onCityChanged(null);
      },
    );

    final stateField = _buildDropdown(
      widget.currentState,
      _stateNames,
      'State',
      'State',
      widget.currentCountry != null,
      (value) {
        widget.onStateChanged(value);
        widget.onCityChanged(null);
      },
    );

    final cityField = _buildDropdown(
      widget.currentCity,
      _cityNames,
      'City',
      'City',
      widget.currentState != null,
      widget.onCityChanged,
    );

    if (widget.isVertical) {
      return Column(
        children: [
          countryField,
          const SizedBox(height: 12),
          stateField,
          const SizedBox(height: 12),
          cityField,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: countryField),
        const SizedBox(width: 16),
        Expanded(child: stateField),
        const SizedBox(width: 16),
        Expanded(child: cityField),
      ],
    );
  }
}
