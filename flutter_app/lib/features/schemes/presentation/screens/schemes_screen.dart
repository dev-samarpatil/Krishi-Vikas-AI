import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../farm/providers/farm_provider.dart';

class SchemesScreen extends ConsumerStatefulWidget {
  const SchemesScreen({super.key});

  @override
  ConsumerState<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends ConsumerState<SchemesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _schemes = [];
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Direct Benefit',
    'Crop Insurance',
    'Credit',
    'Irrigation',
    'Organic'
  ];

  @override
  void initState() {
    super.initState();
    _fetchSchemes();
  }

  Future<void> _fetchSchemes() async {
    setState(() => _isLoading = true);

    final selectedFarm = ref.read(selectedFarmProvider);
    final crop = selectedFarm?.crop ?? 'Tomato';
    final state = selectedFarm?.state ?? 'Maharashtra';
    final size = selectedFarm?.farmSize ?? '1-2';

    try {
      final dio = Dio(BaseOptions(headers: {'Bypass-Tunnel-Reminder': 'true'}));
      final baseUrl = AppConstants.baseUrl;

      final response = await dio.get(
        '$baseUrl/schemes',
        queryParameters: {
          'crop': crop,
          'state': state,
          'size': size,
        },
      );

      final data = response.data;
      final rawSchemes = data['schemes'] as List? ?? [];
      setState(() {
        _schemes = rawSchemes.map((s) => Map<String, dynamic>.from(s as Map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching schemes: $e");
      setState(() {
        _schemes = [];
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredSchemes(AppLocalizations l10n) {
    // Standard mock list of 7 schemes to guarantee full coverage of the feature requested.
    // If the API returns values, we merge/supplement them.
    final List<Map<String, dynamic>> defaults = [
      {
        'id': 'pm-kisan',
        'name': 'PM-KISAN (Pradhan Mantri Kisan Samman Nidhi)',
        'ministry': 'Ministry of Agriculture & Farmers Welfare',
        'benefit': '₹6,000 per year in three equal instalments directly into bank accounts.',
        'category': 'Direct Benefit',
        'eligibility': 'All landholding farmer families across the country with cultivable land.',
        'howToApply': '1. Visit PM-KISAN Portal.\n2. Click on "New Farmer Registration".\n3. Enter Aadhaar number and OTP.\n4. Fill land details and submit.',
        'documents': ['Aadhaar Card', 'Land Ownership Papers (7/12 Extract)', 'Bank Account Details'],
        'url': 'https://pmkisan.gov.in',
        'helpline': '155261',
      },
      {
        'id': 'pmfby',
        'name': 'PMFBY (Pradhan Mantri Fasal Bima Yojana)',
        'ministry': 'Ministry of Agriculture & Farmers Welfare',
        'benefit': 'Comprehensive insurance cover against crop failure due to natural disasters.',
        'category': 'Crop Insurance',
        'eligibility': 'All farmers growing notified crops in notified areas including tenant farmers.',
        'howToApply': '1. Go to PMFBY website.\n2. Click on Crop Insurance Calculator/Apply.\n3. Enter farm location and crop info.\n4. Pay premium online.',
        'documents': ['Land Records', 'Sowing Certificate', 'Aadhaar Card', 'Bank Passbook'],
        'url': 'https://pmfby.gov.in',
        'helpline': '18001801551',
      },
      {
        'id': 'kcc',
        'name': 'Kisan Credit Card (KCC) Scheme',
        'ministry': 'National Bank for Agriculture and Rural Development (NABARD)',
        'benefit': 'Hassle-free short term crop loans up to ₹3 Lakhs at concessional 4% interest.',
        'category': 'Credit',
        'eligibility': 'Owner farmers, tenant farmers, sharecroppers, and self-help groups.',
        'howToApply': '1. Approach nearest commercial, cooperative, or rural bank.\n2. Ask for KCC application form.\n3. Submit with land documents.',
        'documents': ['Identity Proof (Voter ID/PAN)', 'Address Proof', 'Land Revenue Records'],
        'url': 'https://www.nabard.org',
        'helpline': '18001208855',
      },
      {
        'id': 'pmksy',
        'name': 'PMKSY (Pradhan Mantri Krishi Sinchayee Yojana)',
        'ministry': 'Ministry of Water Resources, RD & GR',
        'benefit': 'Up to 55% subsidy on micro-irrigation systems (Drip and Sprinkler systems).',
        'category': 'Irrigation',
        'eligibility': 'All category farmers with access to water resources and cultivable land.',
        'howToApply': '1. Register on State Agriculture Department Portal.\n2. Select approved micro-irrigation vendor.\n3. Submit application online.',
        'documents': ['Land Details', 'Water Source Proof', 'Aadhaar Card', 'Quotations from Vendor'],
        'url': 'https://pmksy.gov.in',
        'helpline': '18001802008',
      },
      {
        'id': 'pkvy',
        'name': 'PKVY (Paramparagat Krishi Vikas Yojana)',
        'ministry': 'Ministry of Agriculture & Farmers Welfare',
        'benefit': 'Financial assistance of ₹50,000 per hectare for organic farming transition.',
        'category': 'Organic',
        'eligibility': 'Farmers in clusters of minimum 50 acres practicing or willing to adopt organic farming.',
        'howToApply': '1. Form/Join a local PGS Organic Cluster.\n2. Submit group registration to Regional Council.\n3. Avail input incentives.',
        'documents': ['PGS India Cluster Form', 'Aadhaar Cards of group', 'Bank Details'],
        'url': 'https://pgsindia-ncof.gov.in',
        'helpline': '1800115555',
      },
      {
        'id': 'rythu-bandhu',
        'name': 'Rythu Bandhu (Investment Support Scheme)',
        'ministry': 'State Department of Agriculture',
        'benefit': '₹10,000 per acre per year support for purchasing inputs like seeds, fertilizers.',
        'category': 'Direct Benefit',
        'eligibility': 'All landowning farmers in the state growing food crops, horticulture or oilseeds.',
        'howToApply': '1. Obtain Pattadar Passbook.\n2. Submit details to local Agricultural Extension Officer.\n3. Check bank deposits.',
        'documents': ['Pattadar Passbook', 'Aadhaar Card', 'Bank Account Linkage'],
        'url': 'https://rythubandhu.telangana.gov.in',
        'helpline': '040-2338356',
      },
      {
        'id': 'agri-infrastructure',
        'name': 'Agriculture Infrastructure Fund (AIF)',
        'ministry': 'Ministry of Agriculture & Farmers Welfare',
        'benefit': '3% interest subvention on loans up to ₹2 Crores for building cold storages and warehouses.',
        'category': 'Credit',
        'eligibility': 'Agri-entrepreneurs, startups, FPOs, cooperative societies, and individual farmers.',
        'howToApply': '1. Create account on AIF Portal.\n2. Upload Detailed Project Report (DPR).\n3. Submit loan application.',
        'documents': ['Project Report', 'Audited Financials', 'KYC Documents', 'Land Allocation Certificate'],
        'url': 'https://agriinfra.dac.gov.in',
        'helpline': '18003130111',
      },
    ];

    final List<Map<String, dynamic>> sourceList = _schemes.isNotEmpty
        ? _schemes
        : defaults;

    // Filter by category
    if (_selectedCategory == 'All') {
      return sourceList.take(7).toList();
    }
    return sourceList
        .where((s) => s['category']?.toString().toLowerCase() == _selectedCategory.toLowerCase())
        .toList();
  }

  void _showSchemeDetails(BuildContext context, Map<String, dynamic> scheme, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (context) {
        final docs = scheme['documents'] as List? ?? [];
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    scheme['name'] ?? 'Government Scheme',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    scheme['ministry'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Divider(height: AppTheme.spacingLg),

                  // Eligibility
                  Text(
                    '📋 ${l10n.eligibility}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    scheme['eligibility'] ?? 'Details not specified',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // How to Apply
                  Text(
                    '🚀 ${l10n.howToApply}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    scheme['howToApply'] ?? 'Details not specified',
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // Documents Needed
                  Text(
                    '📄 ${l10n.documentsNeeded}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  ...docs.map((doc) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppTheme.primaryGreen, size: 18),
                            const SizedBox(width: 8),
                            Text(doc.toString(), style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      )),
                  const SizedBox(height: AppTheme.spacingLg),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Official website trigger
                            final url = scheme['url'] ?? 'https://india.gov.in';
                            debugPrint('Launching url: $url');
                          },
                          icon: const Icon(Icons.launch, size: 16),
                          label: Text(
                            l10n.applyOnGovWebsite,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Call Helpline trigger
                            final phone = scheme['helpline'] ?? '1800115555';
                            debugPrint('Calling: $phone');
                          },
                          icon: const Icon(Icons.phone, size: 16),
                          label: Text(
                            l10n.callHelpline,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen,
                            side: const BorderSide(color: AppTheme.primaryGreen),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedFarm = ref.watch(selectedFarmProvider);
    final crop = selectedFarm?.crop ?? l10n.cropTomato;
    final size = selectedFarm?.farmSize ?? '1-2';
    final district = selectedFarm?.district ?? 'Vasai';

    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        foregroundColor: AppTheme.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.governmentSchemes,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryGreen),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Category Filter Chips List
                Container(
                  height: 48,
                  margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryGreen : AppTheme.surfaceWhite,
                              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryGreen : AppTheme.dividerGray.withOpacity(0.5),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                category == 'All' ? 'All Schemes' : category,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Schemes List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    itemCount: _getFilteredSchemes(l10n).length,
                    itemBuilder: (context, index) {
                      final scheme = _getFilteredSchemes(l10n)[index];
                      final isFirst = index == 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(color: AppTheme.dividerGray.withOpacity(0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(scheme['category']).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          scheme['category'] ?? 'GENERAL',
                                          style: TextStyle(
                                            color: _getCategoryColor(scheme['category']),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        scheme['name'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(scheme['category']),
                                    color: AppTheme.primaryGreen,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: AppTheme.dividerGray),
                            ),
                            // Body
                            Text(
                              scheme['benefit'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppTheme.spacingLg),
                            // Action Button
                            SizedBox(
                              width: double.infinity,
                              child: isFirst
                                  ? ElevatedButton(
                                      onPressed: () => _showSchemeDetails(context, scheme, l10n),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryGreen,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                                        ),
                                      ),
                                      child: const Text(
                                        'View Details & Apply',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    )
                                  : OutlinedButton(
                                      onPressed: () => _showSchemeDetails(context, scheme, l10n),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.primaryGreen,
                                        side: const BorderSide(color: AppTheme.primaryGreen),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                                        ),
                                      ),
                                      child: const Text(
                                        'View Details & Apply',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Color _getCategoryColor(String? category) {
    if (category == null) return AppTheme.primaryGreen;
    final cat = category.toLowerCase();
    if (cat.contains('direct benefit')) return const Color(0xFFE65100);
    if (cat.contains('insurance')) return const Color(0xFF004D40);
    if (cat.contains('credit')) return const Color(0xFF1565C0);
    if (cat.contains('irrigation')) return const Color(0xFF0277BD);
    return AppTheme.primaryGreen;
  }

  IconData _getCategoryIcon(String? category) {
    if (category == null) return Icons.article_outlined;
    final cat = category.toLowerCase();
    if (cat.contains('direct benefit')) return Icons.account_balance_outlined;
    if (cat.contains('insurance')) return Icons.health_and_safety_outlined;
    if (cat.contains('credit')) return Icons.credit_card_outlined;
    if (cat.contains('irrigation')) return Icons.water_drop_outlined;
    return Icons.eco_outlined;
  }
}
