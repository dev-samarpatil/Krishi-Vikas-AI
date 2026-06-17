import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../farm/providers/farm_provider.dart';

class MandiPricesScreen extends ConsumerStatefulWidget {
  const MandiPricesScreen({super.key});

  @override
  ConsumerState<MandiPricesScreen> createState() => _MandiPricesScreenState();
}

class _MandiPricesScreenState extends ConsumerState<MandiPricesScreen> {
  bool _isLoading = true;
  String _source = 'fallback'; // live, cache, fallback
  List<Map<String, dynamic>> _prices = [];
  String _searchQuery = '';
  String _selectedFilter = 'Nearby Mandis';

  @override
  void initState() {
    super.initState();
    _fetchMandiPrices();
  }

  Future<void> _fetchMandiPrices() async {
    setState(() => _isLoading = true);

    final selectedFarm = ref.read(selectedFarmProvider);
    final district = selectedFarm?.district ?? 'Palghar';
    final state = selectedFarm?.state ?? 'Maharashtra';
    final crop = selectedFarm?.crop ?? 'Tomato';

    try {
      final dio = Dio(BaseOptions(headers: {'Bypass-Tunnel-Reminder': 'true'}));
      final baseUrl = AppConstants.baseUrl;

      final response = await dio.get(
        '$baseUrl/mandi/prices',
        queryParameters: {
          'district': district,
          'state': state,
          'crop': crop,
        },
      );

      final data = response.data;
      final rawPrices = data['prices'] as List? ?? [];

      setState(() {
        _source = data['source'] as String? ?? 'cache';
        _prices = rawPrices.map((p) => Map<String, dynamic>.from(p as Map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching mandi prices: $e");
      setState(() {
        _source = 'fallback';
        _prices = [];
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getSixCommodities(AppLocalizations l10n) {
    final List<Map<String, dynamic>> defaults = [
      {
        'crop': l10n.cropTomato,
        'emoji': '🍅',
        'market': 'Palghar APMC',
        'modal_price': 1650,
        'trend': 'up',
        'trend_percent': '8%',
        'tags': ['High Demand', '+8%'],
        'distance': '12.4 km',
      },
      {
        'crop': l10n.cropOnion,
        'emoji': '🧅',
        'market': 'Vasai Mandi',
        'modal_price': 2100,
        'trend': 'flat',
        'trend_percent': '0%',
        'tags': ['Stable'],
        'distance': '18.1 km',
      },
      {
        'crop': l10n.cropPotato,
        'emoji': '🥔',
        'market': 'Virar APMC',
        'modal_price': 1200,
        'trend': 'down',
        'trend_percent': '4%',
        'tags': ['-4%'],
        'distance': '22.0 km',
      },
      {
        'crop': l10n.cropWheat,
        'emoji': '🌾',
        'market': 'Nashik Mandi',
        'modal_price': 2400,
        'trend': 'flat',
        'trend_percent': '0%',
        'tags': ['Premium Grade', 'Stable'],
        'distance': '5.2 km',
      },
      {
        'crop': l10n.cropRice,
        'emoji': '🍚',
        'market': 'Mumbai APMC',
        'modal_price': 2850,
        'trend': 'up',
        'trend_percent': '5%',
        'tags': ['High Demand', '+5%'],
        'distance': '45.0 km',
      },
      {
        'crop': l10n.cropCotton,
        'emoji': '☁️',
        'market': 'Pune APMC',
        'modal_price': 6500,
        'trend': 'up',
        'trend_percent': '11%',
        'tags': ['+11%'],
        'distance': '80.0 km',
      },
    ];

    if (_prices.isEmpty) return defaults;

    // Merge API prices over default items
    final List<Map<String, dynamic>> merged = [];
    for (var def in defaults) {
      final matchingApi = _prices.firstWhere(
        (api) =>
            api['crop']?.toString().toLowerCase() == def['crop']?.toString().toLowerCase() ||
            api['commodity']?.toString().toLowerCase() == def['crop']?.toString().toLowerCase(),
        orElse: () => {},
      );

      if (matchingApi.isNotEmpty) {
        merged.add({
          'crop': def['crop'],
          'emoji': def['emoji'],
          'market': matchingApi['market'] ?? matchingApi['apmc'] ?? def['market'],
          'modal_price': matchingApi['modal_price'] ?? matchingApi['price'] ?? def['modal_price'],
          'trend': matchingApi['trend'] ?? def['trend'],
          'trend_percent': matchingApi['trend_percent'] ?? def['trend_percent'],
          'tags': def['tags'],
          'distance': def['distance'],
        });
      } else {
        merged.add(def);
      }
    }
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final commodities = _getSixCommodities(l10n);

    final filtered = commodities.where((c) {
      final crop = c['crop'].toString().toLowerCase();
      
      if (_selectedFilter == 'Vegetables') {
        if (!['tomato', 'onion', 'potato'].contains(crop)) return false;
      } else if (_selectedFilter == 'Grains') {
        if (!['wheat', 'rice'].contains(crop)) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final market = c['market'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!crop.contains(query) && !market.contains(query)) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF191C1D)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mandi Prices',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF191C1D),
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF191C1D)),
            onPressed: () {},
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchMandiPrices,
              color: AppTheme.primaryGreen,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE1E3E4)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B4332).withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search crops...',
                        hintStyle: TextStyle(color: Color(0xFF717973)),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF717973)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Nearby Mandis', Icons.location_on_outlined),
                        const SizedBox(width: 8),
                        _buildFilterChip('Vegetables', null),
                        const SizedBox(width: 8),
                        _buildFilterChip('Grains', null),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Where to Sell Card
                  const Text(
                    'Where to Sell (Best Deals)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191C1D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: _buildWhereToSellList(commodities),
                  ),
                  const SizedBox(height: 24),

                  // Crop Prices List
                  ...filtered.map((item) => _buildCropCard(item)).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, IconData? icon) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B4332) : Colors.white, // primary-container vs surface
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: const Color(0xFFE1E3E4)),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF414844),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF414844),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhereToSellList(List<Map<String, dynamic>> commodities) {
    final sorted = List<Map<String, dynamic>>.from(commodities)
      ..sort((a, b) => (b['modal_price'] as int).compareTo(a['modal_price'] as int));
    final topDeals = sorted.take(3).toList();

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: topDeals.length,
      separatorBuilder: (context, index) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        final top = topDeals[index];
        return SizedBox(
          width: 300,
          child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF012D1D), Color(0xFF00452D)], // primary to tertiary-container
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF012D1D).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      top['market'] ?? 'APMC',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCA98), // secondary-container
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Best Rate',
                        style: TextStyle(
                          color: Color(0xFF7A532A),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Offering premium rates for A-Grade ${top['crop']}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF86D7AD), size: 16), // tertiary-fixed-dim
                        const SizedBox(width: 4),
                        Text(
                          top['distance'] ?? '12 km',
                          style: const TextStyle(
                            color: Color(0xFF86D7AD),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Expected Price',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '₹${top['modal_price']}/q',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final marketName = top['market'] ?? 'APMC Market';
                      // Try to open Google Maps app first, fallback to browser
                      final mapsAppUrl = Uri.parse('geo:0,0?q=${Uri.encodeComponent(marketName)}');
                      final mapsWebUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(marketName)}');
                      if (await canLaunchUrl(mapsAppUrl)) {
                        await launchUrl(mapsAppUrl, mode: LaunchMode.externalApplication);
                      } else if (await canLaunchUrl(mapsWebUrl)) {
                        await launchUrl(mapsWebUrl, mode: LaunchMode.externalApplication);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC1ECD4), // primary-fixed
                      foregroundColor: const Color(0xFF002114), // on-primary-fixed
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Get Directions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
      },
    );
  }

  Widget _buildCropCard(Map<String, dynamic> item) {
    final trend = item['trend'] as String? ?? 'flat';
    final isUp = trend == 'up';
    final isDown = trend == 'down';
    final trendColor = isUp
        ? const Color(0xFF1B4332) // Greenish
        : isDown
            ? const Color(0xFFBA1A1A) // Reddish
            : const Color(0xFF717973);
    final trendBgColor = isUp
        ? const Color(0xFFC1ECD4)
        : isDown
            ? const Color(0xFFFFDAD6)
            : const Color(0xFFE1E3E4);
    final trendIcon = isUp
        ? Icons.arrow_upward
        : isDown
            ? Icons.arrow_downward
            : Icons.horizontal_rule;
    
    final tags = (item['tags'] as List<dynamic>?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E3E4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Emoji circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  item['emoji'] ?? '🌾',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['crop'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF191C1D),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: trendBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(trendIcon, color: trendColor, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              '₹${item['modal_price']}',
                              style: TextStyle(
                                color: trendColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item['market']} • ${item['distance'] ?? '12 km'}',
                    style: const TextStyle(
                      color: Color(0xFF717973),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: tags.map((t) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t.toString(),
                          style: const TextStyle(
                            color: Color(0xFF414844),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
