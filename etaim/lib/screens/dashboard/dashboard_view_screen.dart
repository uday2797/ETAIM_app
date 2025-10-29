import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/dashboard.dart';
import '../../services/ai_service.dart';
import '../../services/commute_service.dart';
import '../../services/weather_service.dart';
import '../../services/food_service.dart';
import '../../models/commute_option.dart';
import '../../models/food_option.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardViewScreen extends StatefulWidget {
  final Dashboard dashboard;

  const DashboardViewScreen({
    Key? key,
    required this.dashboard,
  }) : super(key: key);

  @override
  State<DashboardViewScreen> createState() => _DashboardViewScreenState();
}

class _DashboardViewScreenState extends State<DashboardViewScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final weatherService = Provider.of<WeatherService>(context, listen: false);
    final commuteService = Provider.of<CommuteService>(context, listen: false);
    final foodService = Provider.of<FoodService>(context, listen: false);
    final aiService = Provider.of<AIService>(context, listen: false);

    // Fetch weather
    await weatherService.fetchWeather();

    // Fetch commute options
    await commuteService.fetchCommuteOptions(
      widget.dashboard.from,
      widget.dashboard.to,
      weatherService.currentWeather,
      DateTime.now().hour,
    );

    // Fetch food options
    await foodService.fetchFoodOptions(
      weatherService.currentWeather,
      DateTime.now().hour,
    );

    // Generate AI insights
    final recommendedCommute = commuteService.options.firstWhere(
      (o) => o.isRecommended,
      orElse: () => commuteService.options.first,
    );

    await aiService.generateInsights(
      widget.dashboard,
      weatherService.currentWeather,
      recommendedCommute.etaMinutes + recommendedCommute.arrivalMinutes,
      commuteService.options,
    );

    setState(() => _isLoading = false);
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');
    final weatherService = Provider.of<WeatherService>(context);
    final commuteService = Provider.of<CommuteService>(context);
    final aiService = Provider.of<AIService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dashboard.name),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with time and weather
                    _buildHeaderSection(weatherService, timeFormat),

                    // AI Insights Section
                    _buildAIInsightsSection(aiService),

                    // Commute Options
                    _buildCommuteSection(commuteService),

                    // Food Recommendations
                    _buildFoodSection(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderSection(WeatherService weatherService, DateFormat timeFormat) {
    final now = DateTime.now();
    final officeTime = widget.dashboard.officeLoginTime;
    final minutesToOffice = officeTime.difference(now).inMinutes;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Time',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    timeFormat.format(now),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    weatherService.getWeatherIcon(),
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weatherService.currentWeather,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${weatherService.temperature.toStringAsFixed(0)}°C',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Office Login Time',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeFormat.format(officeTime),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: minutesToOffice > 30
                        ? Colors.green
                        : minutesToOffice > 0
                            ? Colors.orange
                            : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    minutesToOffice > 0
                        ? '$minutesToOffice mins left'
                        : '${-minutesToOffice} mins late',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightsSection(AIService aiService) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Insights',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (aiService.insights.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Generating insights...'),
              ),
            )
          else
            ...aiService.insights.map((insight) => _buildInsightCard(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(AIInsight insight) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    switch (insight.priority) {
      case 'high':
        backgroundColor = Colors.red[50]!;
        borderColor = Colors.red;
        textColor = Colors.red[900]!;
        break;
      case 'medium':
        backgroundColor = Colors.orange[50]!;
        borderColor = Colors.orange;
        textColor = Colors.orange[900]!;
        break;
      default:
        backgroundColor = Colors.blue[50]!;
        borderColor = Colors.blue;
        textColor = Colors.blue[900]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                insight.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight.description,
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommuteSection(CommuteService commuteService) {
    // Get top 3 commute options (one of each type if available)
    final bikeOptions = commuteService.options.where((o) => o.type == CommuteType.bike).toList();
    final autoOptions = commuteService.options.where((o) => o.type == CommuteType.auto).toList();
    final cabOptions = commuteService.options.where((o) => o.type == CommuteType.cab).toList();

    bikeOptions.sort((a, b) => a.price.compareTo(b.price));
    autoOptions.sort((a, b) => a.price.compareTo(b.price));
    cabOptions.sort((a, b) => a.price.compareTo(b.price));

    final topOptions = <CommuteOption>[];
    if (bikeOptions.isNotEmpty) topOptions.add(bikeOptions.first);
    if (autoOptions.isNotEmpty) topOptions.add(autoOptions.first);
    if (cabOptions.isNotEmpty) topOptions.add(cabOptions.first);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Commute Options',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full commute screen
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...topOptions.map((option) => _buildCommuteOptionCard(option)),
        ],
      ),
    );
  }

  Widget _buildCommuteOptionCard(CommuteOption option) {
    final commuteService = Provider.of<CommuteService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: option.isRecommended ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: option.isRecommended
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getCommuteTypeColor(option.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCommuteTypeIcon(option.type),
                color: _getCommuteTypeColor(option.type),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${option.providerName} ${option.typeName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (option.isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${option.etaMinutes} min',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${option.distance.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (option.provider != CommuteProvider.ownVehicle)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${option.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _launchURL(commuteService.getDeepLink(option)),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Book', style: TextStyle(fontSize: 12)),
                  ),
                ],
              )
            else
              const Text(
                'FREE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodSection() {
    final foodService = Provider.of<FoodService>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Food Recommendations',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Current Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          if (foodService.currentLocationOptions.isNotEmpty)
            _buildFoodOptionCard(foodService.currentLocationOptions.first)
          else
            const Text('No options available'),
          const SizedBox(height: 16),
          const Text(
            'Destination',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          if (foodService.destinationOptions.isNotEmpty)
            _buildFoodOptionCard(foodService.destinationOptions.first)
          else
            const Text('No options available'),
        ],
      ),
    );
  }

  Widget _buildFoodOptionCard(option) {
    final foodService = Provider.of<FoodService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: option.isRecommended ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: option.isRecommended
            ? BorderSide(color: Colors.orange, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.restaurant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.dishName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${option.deliveryTimeMinutes} mins',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: option.provider == FoodProvider.swiggy
                              ? const Color(0xFFFC8019)
                              : const Color(0xFFE23744),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          option.providerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${option.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                TextButton(
                  onPressed: () => _launchURL(foodService.getDeepLink(option)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Order', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCommuteTypeColor(CommuteType type) {
    switch (type) {
      case CommuteType.bike:
        return Colors.blue;
      case CommuteType.auto:
        return Colors.orange;
      case CommuteType.cab:
        return Colors.green;
    }
  }

  IconData _getCommuteTypeIcon(CommuteType type) {
    switch (type) {
      case CommuteType.bike:
        return Icons.two_wheeler;
      case CommuteType.auto:
        return Icons.local_taxi;
      case CommuteType.cab:
        return Icons.directions_car;
    }
  }
}