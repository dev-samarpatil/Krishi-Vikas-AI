import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/farm_model.dart';
import '../../../../shared/services/local_storage_service.dart';
import '../../providers/farm_provider.dart';

/// Farm setup screen — first-time onboarding flow or farm editing.
/// Step 0: Language Selection (skipped in Edit mode)
/// Step 1: Farm details (Name, Crop, Size, Farming Type, Location, Sowing Date)
/// Step 2: Done (skipped in Edit mode)
class FarmSetupScreen extends ConsumerStatefulWidget {
  final FarmModel? farmToEdit;

  const FarmSetupScreen({super.key, this.farmToEdit});

  @override
  ConsumerState<FarmSetupScreen> createState() => _FarmSetupScreenState();
}

class _FarmSetupScreenState extends ConsumerState<FarmSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0;
  String _selectedLanguage = 'en';

  // Form Fields
  final _nameController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();

  String _selectedCrop = AppConstants.cropOptions.first;
  String _selectedSize = AppConstants.farmSizeOptions[1]; // default 1-2
  String _selectedFarmingType = AppConstants.farmingTypeOptions.first; // default organic
  DateTime? _sowingDate;
  double? _lat;
  double? _lng;

  bool _isLocating = false;
  bool _isLoading = false;

  final _languageOptions = {
    'en': {'name': 'English', 'icon': Icons.public, 'sub': 'English language'},
    'hi': {'name': 'हिन्दी', 'icon': Icons.translate, 'sub': 'Hindi'},
    'mr': {'name': 'मराठी', 'icon': Icons.translate, 'sub': 'Marathi'},
    'ta': {'name': 'தமிழ்', 'icon': Icons.translate, 'sub': 'Tamil'},
  };

  bool get _isEditMode => widget.farmToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final farm = widget.farmToEdit!;
      _currentStep = 1; // Direct to details
      _nameController.text = farm.name;
      _selectedCrop = farm.crop;
      _selectedSize = farm.farmSize;
      _selectedFarmingType = farm.farmingType;
      _districtController.text = farm.district ?? '';
      _stateController.text = farm.state ?? '';
      _sowingDate = farm.sowingDate;
      _lat = farm.lat;
      _lng = farm.lng;
    } else {
      // Default step is 0 (language selection)
      // Read saved language to preset
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final localStorage = ref.read(localStorageProvider);
        setState(() {
          _selectedLanguage = localStorage.selectedLanguage;
        });
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled. Please enable them in your settings.')),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied.')),
            );
          }
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied. Please enable them in app settings.')),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 25),
        );
      } catch (e) {
        debugPrint('getCurrentPosition failed/timed out: $e. Trying last known position...');
        position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          rethrow;
        }
      }

      setState(() {
        _lat = position!.latitude;
        _lng = position.longitude;
      });

      if (kIsWeb) {
        try {
          final dio = Dio(BaseOptions(headers: {'Bypass-Tunnel-Reminder': 'true'}));
          final response = await dio.get(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=10&addressdetails=1',
          );
          if (response.statusCode == 200) {
            final data = response.data;
            final address = data['address'] ?? {};
            final dist = address['state_district'] ?? address['county'] ?? address['city'] ?? '';
            final st = address['state'] ?? '';
            setState(() {
              _districtController.text = dist;
              _stateController.text = st;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location captured and address resolved via OSM!')),
              );
            }
          } else {
            throw Exception('Nominatim returned ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('Web reverse geocoding error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('GPS coordinates captured, but failed to resolve address. Please input them manually.')),
            );
          }
        }
      } else {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            setState(() {
              final dist = place.subAdministrativeArea ?? place.locality ?? '';
              final st = place.administrativeArea ?? '';
              _districtController.text = dist;
              _stateController.text = st;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location captured and address resolved!')),
              );
            }
          }
        } catch (e) {
          debugPrint('Reverse geocoding error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('GPS coordinates captured, but failed to resolve address details. Please input them manually.')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting GPS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not fetch location: $e. Please enter location manually.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _selectSowingDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _sowingDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _sowingDate) {
      setState(() {
        _sowingDate = picked;
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Save language preference
      ref.read(localStorageProvider).setSelectedLanguage(_selectedLanguage);
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_formKey.currentState!.validate()) {
        _saveFarm();
      }
    } else {
      ref.read(localStorageProvider).setHasCompletedOnboarding(true);
      context.go(AppRoutes.home);
    }
  }

  Future<void> _saveFarm() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(farmRepositoryProvider);
      final name = _nameController.text.trim();
      final crop = _selectedCrop;
      final size = _selectedSize;
      final farmingType = _selectedFarmingType;
      final district = _districtController.text.trim().isEmpty ? null : _districtController.text.trim();
      final state = _stateController.text.trim().isEmpty ? null : _stateController.text.trim();

      if (_isEditMode) {
        final data = <String, dynamic>{
          'name': name,
          'crop': crop,
          'farm_size': size,
          'farming_type': farmingType,
          'district': district,
          'state': state,
          'lat': _lat,
          'lng': _lng,
          'sowing_date': _sowingDate?.toIso8601String().split('T').first,
        };
        await repo.updateFarm(widget.farmToEdit!.id, data);
        ref.invalidate(farmsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Farm details updated successfully!')),
          );
          context.pop(); // Go back to dashboard
        }
      } else {
        final newFarm = await repo.createFarm(
          name: name,
          crop: crop,
          farmSize: size,
          farmingType: farmingType,
          district: district,
          state: state,
          lat: _lat,
          lng: _lng,
          sowingDate: _sowingDate,
        );
        ref.invalidate(farmsProvider);
        // Persist the selected farm ID
        ref.read(selectedFarmIdProvider.notifier).select(newFarm.id);
        setState(() {
          _currentStep = 2; // Transition to done step
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error saving farm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save farm details: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLg = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Farm' : 'Farm Setup'),
        leading: _isEditMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : _currentStep > 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _currentStep--),
                  )
                : const BackButton(),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Saving farm details...', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              )
            : Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isLg ? 600 : double.infinity),
                  child: Column(
                    children: [
                      if (!_isEditMode) ...[
                        const SizedBox(height: AppTheme.spacingMd),
                        _buildStepIndicator(),
                      ],
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppTheme.spacingLg),
                          child: _currentStep == 0
                              ? _buildLanguageStep()
                              : _currentStep == 1
                                  ? _buildFarmDetailsStep()
                                  : _buildDoneStep(),
                        ),
                      ),
                      _buildBottomBar(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          final isLast = index == 2;
          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryGreen : AppTheme.dividerGray,
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 3,
                      color: isActive ? AppTheme.primaryGreen : AppTheme.dividerGray,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLanguageStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Select App Language\n',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
            children: [
              TextSpan(
                text: 'भाषा निवडा',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          'Choose your preferred language for calculations and diagnosis.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _languageOptions.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingMd),
          itemBuilder: (context, index) {
            final key = _languageOptions.keys.elementAt(index);
            final option = _languageOptions[key]!;
            final isSelected = _selectedLanguage == key;

            return InkWell(
              onTap: () => setState(() => _selectedLanguage = key),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryLight.withOpacity(0.1) : AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryGreen : AppTheme.dividerGray,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.dividerGray.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.dividerGray),
                      ),
                      child: Icon(
                        option['icon'] as IconData,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['name'] as String,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            option['sub'] as String,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryGreen,
                        size: 24,
                      )
                    else
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.dividerGray, width: 2),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFarmDetailsStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditMode ? 'Update Farm Settings' : 'Enter Farm Details',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            _isEditMode
                ? 'Modify your crop details, location, and metadata.'
                : 'Setup your primary crop and farm size to start managing.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Farm Name input
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Farm Name',
              hintText: 'e.g. My Tomato Farm',
              prefixIcon: Icon(Icons.home_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter a name for your farm';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Primary Crop dropdown
          DropdownButtonFormField<String>(
            value: _selectedCrop,
            decoration: const InputDecoration(
              labelText: 'Primary Crop',
              prefixIcon: Icon(Icons.grass_outlined),
            ),
            items: AppConstants.cropOptions.map((crop) {
              return DropdownMenuItem(
                value: crop,
                child: Text(crop[0].toUpperCase() + crop.substring(1)),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedCrop = v);
              }
            },
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Farm Size dropdown
          DropdownButtonFormField<String>(
            value: _selectedSize,
            decoration: const InputDecoration(
              labelText: 'Farm Size (Acres)',
              prefixIcon: Icon(Icons.photo_size_select_small),
            ),
            items: AppConstants.farmSizeOptions.map((size) {
              return DropdownMenuItem(
                value: size,
                child: Text(size == '<1' ? 'Less than 1 acre' : '$size acres'),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedSize = v);
              }
            },
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Farming type header
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingSm, left: AppTheme.spacingXs),
            child: Text(
              'Farming Practice',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          // Segmented buttons for farming type
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'organic',
                  label: Text('Organic'),
                ),
                ButtonSegment<String>(
                  value: 'conventional',
                  label: Text('Chemical'),
                ),
                ButtonSegment<String>(
                  value: 'mixed',
                  label: Text('Mixed'),
                ),
              ],
              selected: {_selectedFarmingType},
              onSelectionChanged: (set) {
                setState(() {
                  _selectedFarmingType = set.first;
                });
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.primaryGreen;
                  }
                  return AppTheme.dividerGray.withOpacity(0.3);
                }),
                foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return AppTheme.textSecondary;
                }),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Location details card
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              side: const BorderSide(color: AppTheme.dividerGray),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location Settings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLocating ? null : _getLocation,
                      icon: _isLocating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textPrimary),
                            )
                          : const Icon(Icons.my_location, size: 20, color: AppTheme.textPrimary),
                      label: Text(
                        _isLocating ? 'Locating...' : 'GPS Auto-fill',
                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warningYellow,
                        foregroundColor: AppTheme.textPrimary,
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  TextFormField(
                    controller: _districtController,
                    decoration: const InputDecoration(
                      labelText: 'District',
                      hintText: 'e.g. Pune',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'District is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      hintText: 'e.g. Maharashtra',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'State is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Sowing Date picker (Optional)
          InkWell(
            onTap: _selectSowingDate,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingMd,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.dividerGray),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: AppTheme.textSecondary),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sowing Date (Optional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _sowingDate == null
                              ? 'Not set'
                              : DateFormat('dd MMMM yyyy').format(_sowingDate!),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _sowingDate == null ? AppTheme.textHint : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_sowingDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _sowingDate = null),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
        ],
      ),
    );
  }

  Widget _buildDoneStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppTheme.spacingXl),
        Container(
          width: 130,
          height: 130,
          decoration: const BoxDecoration(
            color: AppTheme.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.check_circle,
              size: 80,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingXl),
        Text(
          'Your farm is ready!',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          'Setup successfully completed. You can now start managing crop health, requesting advice, and monitoring soil conditions.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXxl),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.dividerGray),
        ),
      ),
      child: ElevatedButton(
        onPressed: _nextStep,
        child: Text(
          _isEditMode
              ? 'Save Changes'
              : _currentStep == 2
                  ? 'Go to Home'
                  : 'Next',
        ),
      ),
    );
  }
}
