import 'package:flutter/material.dart';
import '../models/commute_option.dart';

class CommuteCard extends StatelessWidget {
  final CommuteOption option;
  final bool isCheapest;
  final bool isFastest;
  final VoidCallback? onTap;

  const CommuteCard({
    Key? key,
    required this.option,
    this.isCheapest = false,
    this.isFastest = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Provider Icon
                  _buildProviderIcon(context),
                  const SizedBox(width: 12),
                  // Provider Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              option.providerName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (option.isRecommended) ...[
                              const SizedBox(width: 8),
                              _buildRecommendedBadge(),
                            ],
                          ],
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
                  // Price
                  _buildPriceDisplay(),
                ],
              ),

              const SizedBox(height: 16),

              // Statistics Row
              _buildStatsRow(),

              // Badges Section
              if (option.isRecommended || isCheapest || isFastest) ...[
                const SizedBox(height: 12),
                _buildBadges(),
              ],

              // Recommendation Reason
              if (option.isRecommended && option.reason != null) ...[
                const SizedBox(height: 12),
                _buildReasonCard(context),
              ],

              // Action Button
              if (option.provider != CommuteProvider.ownVehicle) ...[
                const SizedBox(height: 16),
                _buildBookButton(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getProviderColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getProviderIcon(),
        color: _getProviderColor(),
        size: 28,
      ),
    );
  }

  Widget _buildRecommendedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.star, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'BEST',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDisplay() {
    if (option.provider == CommuteProvider.ownVehicle) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: const [
          Text(
            'FREE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          Text(
            'No Cost',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    return Column(
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
        Text(
          'Estimated',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        if (option.provider != CommuteProvider.ownVehicle) ...[
          _buildStatItem(
            icon: Icons.schedule,
            label: 'Arrival',
            value: '${option.arrivalMinutes} min',
            color: Colors.blue,
          ),
          const SizedBox(width: 16),
        ],
        _buildStatItem(
          icon: Icons.access_time,
          label: 'Journey',
          value: '${option.etaMinutes} min',
          color: Colors.orange,
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          icon: Icons.route,
          label: 'Distance',
          value: '${option.distance.toStringAsFixed(1)} km',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadges() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (option.isRecommended)
          _buildBadge('⭐ AI Recommended', Colors.blue),
        if (isCheapest)
          _buildBadge('💰 Cheapest', Colors.green),
        if (isFastest)
          _buildBadge('⚡ Fastest', Colors.orange),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
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

  Widget _buildReasonCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 18,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              option.reason!,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getProviderColor(),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.open_in_new, size: 18),
            const SizedBox(width: 8),
            Text(
              'Book with ${option.providerName}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProviderColor() {
    switch (option.provider) {
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

  IconData _getProviderIcon() {
    switch (option.type) {
      case CommuteType.bike:
        return Icons.two_wheeler;
      case CommuteType.auto:
        return Icons.local_taxi;
      case CommuteType.cab:
        return Icons.directions_car;
    }
  }
}