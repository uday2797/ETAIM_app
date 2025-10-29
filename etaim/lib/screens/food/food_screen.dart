import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/location.dart';
import '../../models/food_option.dart';
import '../../services/food_service.dart';
import '../../services/weather_service.dart';

class FoodScreen extends StatefulWidget {
  final LocationModel currentLocation;
  final LocationModel destinationLocation;

  const FoodScreen({
    Key? key,
    required this.currentLocation,
    required this.destinationLocation,
  }) : super(key: key);

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFoodOptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFoodOptions() async {
    final foodService = Provider.of<FoodService>(context, listen: false);
    final weatherService = Provider.of<WeatherService>(context, listen: false);

    await foodService.fetchFoodOptions(
      weatherService.currentWeather,
      DateTime.now().hour,
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodService = Provider.of<FoodService>(context);

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: [
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.location_on),
                    SizedBox(height: 4),
                    Text('Current Location', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.place),
                    SizedBox(height: 4),
                    Text('Destination', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: foodService.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFoodList(
                      foodService.currentLocationOptions,
                      'Current Location',
                    ),
                    _buildFoodList(
                      foodService.destinationOptions,
                      'Destination',
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildFoodList(List<FoodOption> options, String locationType) {
    if (options.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No food options available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Find cheapest and fastest
    final cheapest = options.reduce((a, b) => a.totalPrice < b.totalPrice ? a : b);
    final fastest = options.reduce(
        (a, b) => a.deliveryTimeMinutes < b.deliveryTimeMinutes ? a : b);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isCheapest = option == cheapest;
        final isFastest = option == fastest;

        return _buildFoodCard(
          option,
          isCheapest: isCheapest,
          isFastest: isFastest,
        );
      },
    );
  }

  Widget _buildFoodCard(
    FoodOption option, {
    bool isCheapest = false,
    bool isFastest = false,
  }) {
    final foodService = Provider.of<FoodService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: option.isRecommended ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: option.isRecommended
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _launchURL(foodService.getDeepLink(option)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Restaurant image placeholder
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.restaurant, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.restaurant.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              option.restaurant.rating.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${option.restaurant.cuisine}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${option.restaurant.distance.toStringAsFixed(1)} km away',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Provider badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: option.provider == FoodProvider.swiggy
                          ? const Color(0xFFFC8019)
                          : const Color(0xFFE23744),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      option.providerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Dish info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.dishName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${option.deliveryTimeMinutes} mins',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '₹${option.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ' + ₹${option.deliveryFee.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹${option.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              // Badges
              if (option.isRecommended || isCheapest || isFastest)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (option.isRecommended)
                        _buildBadge(
                          '⭐ AI Recommended',
                          Theme.of(context).primaryColor,
                        ),
                      if (isCheapest)
                        _buildBadge('💰 Best Value', Colors.green),
                      if (isFastest)
                        _buildBadge('⚡ Fastest Delivery', Colors.orange),
                    ],
                  ),
                ),

              // Recommendation reason
              if (option.isRecommended && option.reason != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          option.reason!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Order button
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed: () => _launchURL(foodService.getDeepLink(option)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: option.provider == FoodProvider.swiggy
                        ? const Color(0xFFFC8019)
                        : const Color(0xFFE23744),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Order from ${option.providerName}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}