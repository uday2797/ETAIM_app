import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/location.dart';
import '../../models/commute_option.dart';
import '../../services/commute_service.dart';
import '../../services/weather_service.dart';

class CommuteScreen extends StatefulWidget {
  final LocationModel from;
  final LocationModel to;

  const CommuteScreen({
    Key? key,
    required this.from,
    required this.to,
  }) : super(key: key);

  @override
  State<CommuteScreen> createState() => _CommuteScreenState();
}

class _CommuteScreenState extends State<CommuteScreen> {
  CommuteType _selectedType = CommuteType.bike;

  @override
  void initState() {
    super.initState();
    _loadCommuteOptions();
  }

  Future<void> _loadCommuteOptions() async {
    final commuteService = Provider.of<CommuteService>(context, listen: false);
    final weatherService = Provider.of<WeatherService>(context, listen: false);

    await commuteService.fetchCommuteOptions(
      widget.from,
      widget.to,
      weatherService.currentWeather,
      DateTime.now().hour,
    );
  }

  List<CommuteOption> _getFilteredOptions(List<CommuteOption> options) {
    return options.where((o) => o.type == _selectedType).toList()
      ..sort((a, b) => a.price.compareTo(b.price));
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the app')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commuteService = Provider.of<CommuteService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commute Options'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header with route info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trip_origin, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.from.address,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.more_vert, color: Colors.white70, size: 20),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.to.address,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Type selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildTypeChip(CommuteType.bike, '🏍️ Bike'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeChip(CommuteType.auto, '🛺 Auto'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeChip(CommuteType.cab, '🚗 Cab'),
                ),
              ],
            ),
          ),

          // Options list
          Expanded(
            child: commuteService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildOptionsList(_getFilteredOptions(commuteService.options)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(CommuteType type, String label) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsList(List<CommuteOption> options) {
    if (options.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No options available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Find cheapest and fastest
    final cheapest = options.reduce((a, b) => a.price < b.price ? a : b);
    final fastest = options.reduce((a, b) =>
        (a.etaMinutes + a.arrivalMinutes) < (b.etaMinutes + b.arrivalMinutes)
            ? a
            : b);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isCheapest = option == cheapest;
        final isFastest = option == fastest;

        return _buildCommuteCard(
          option,
          isCheapest: isCheapest,
          isFastest: isFastest,
        );
      },
    );
  }

  Widget _buildCommuteCard(
    CommuteOption option, {
    bool isCheapest = false,
    bool isFastest = false,
  }) {
    final commuteService = Provider.of<CommuteService>(context, listen: false);

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
        onTap: option.provider != CommuteProvider.ownVehicle
            ? () => _launchURL(commuteService.getDeepLink(option))
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Provider logo/icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getProviderColor(option.provider).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getProviderIcon(option.provider),
                      color: _getProviderColor(option.provider),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.providerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          option.typeName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
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
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'FREE',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Stats
              Row(
                children: [
                  if (option.provider != CommuteProvider.ownVehicle) ...[
                    _buildStat(
                      icon: Icons.schedule,
                      label: 'Arrival',
                      value: '${option.arrivalMinutes} min',
                    ),
                    const SizedBox(width: 16),
                  ],
                  _buildStat(
                    icon: Icons.access_time,
                    label: 'ETA',
                    value: '${option.etaMinutes} min',
                  ),
                  const SizedBox(width: 16),
                  _buildStat(
                    icon: Icons.route,
                    label: 'Distance',
                    value: '${option.distance.toStringAsFixed(1)} km',
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
                        _buildBadge('💰 Cheapest', Colors.green),
                      if (isFastest)
                        _buildBadge('⚡ Fastest', Colors.orange),
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

              // Book button
              if (option.provider != CommuteProvider.ownVehicle)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: () => _launchURL(commuteService.getDeepLink(option)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Book Now'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
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

  Color _getProviderColor(CommuteProvider provider) {
    switch (provider) {
      case CommuteProvider.rapido:
        return const Color(0xFFFFB800);
      case CommuteProvider.ola:
        return const Color(0xFF00C853);
      case CommuteProvider.uber:
        return Colors.black;
      case CommuteProvider.ownVehicle:
        return Colors.blue;
    }
  }

  IconData _getProviderIcon(CommuteProvider provider) {
    switch (provider) {
      case CommuteProvider.rapido:
      case CommuteProvider.ola:
      case CommuteProvider.uber:
        return Icons.directions_bike;
      case CommuteProvider.ownVehicle:
        return Icons.directions_car;
    }
  }
}