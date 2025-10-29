import 'package:flutter/material.dart';
import '../models/location.dart';
import '../services/location_service.dart';
import 'package:provider/provider.dart';

class LocationSearch extends StatefulWidget {
  final String hintText;
  final String label;
  final IconData icon;
  final Color iconColor;
  final LocationModel? initialLocation;
  final Function(LocationModel) onLocationSelected;
  final bool enabled;

  const LocationSearch({
    Key? key,
    required this.hintText,
    required this.label,
    this.icon = Icons.location_on,
    this.iconColor = Colors.blue,
    this.initialLocation,
    required this.onLocationSelected,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<LocationSearch> createState() => _LocationSearchState();
}

class _LocationSearchState extends State<LocationSearch> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;
  LocationModel? _selectedLocation;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      _controller.text = widget.initialLocation!.address;
    }

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Delay hiding suggestions to allow tap on suggestion
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() => _showSuggestions = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String value, LocationService locationService) {
    setState(() => _showSuggestions = true);
    locationService.searchLocations(value);
  }

  void _selectLocation(LocationModel location, LocationService locationService) {
    setState(() {
      _selectedLocation = location;
      _controller.text = location.address;
      _showSuggestions = false;
    });
    locationService.clearSuggestions();
    _focusNode.unfocus();
    widget.onLocationSelected(location);
  }

  void _clearSearch(LocationService locationService) {
    setState(() {
      _controller.clear();
      _selectedLocation = null;
      _showSuggestions = false;
    });
    locationService.clearSuggestions();
  }

  Future<void> _useCurrentLocation(LocationService locationService) async {
    await locationService.getCurrentLocation();
    if (locationService.currentLocation != null) {
      _selectLocation(locationService.currentLocation!, locationService);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with icon
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: widget.iconColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Search Input
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: Icon(widget.icon, size: 20, color: widget.iconColor),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => _clearSearch(locationService),
                  ),
                IconButton(
                  icon: const Icon(Icons.my_location, size: 20),
                  onPressed: () => _useCurrentLocation(locationService),
                  tooltip: 'Use current location',
                ),
              ],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.iconColor,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: widget.enabled ? Colors.grey[50] : Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (value) => _onTextChanged(value, locationService),
          onTap: () => setState(() => _showSuggestions = true),
        ),

        // Suggestions List
        if (_showSuggestions && locationService.searchSuggestions.isNotEmpty)
          _buildSuggestionsList(locationService),

        // Loading Indicator
        if (locationService.isLoading && _showSuggestions)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),

        // Selected Location Display
        if (_selectedLocation != null && !_showSuggestions)
          _buildSelectedLocationCard(),
      ],
    );
  }

  Widget _buildSuggestionsList(LocationService locationService) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: locationService.searchSuggestions.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey[200],
        ),
        itemBuilder: (context, index) {
          final suggestion = locationService.searchSuggestions[index];
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.location_on,
                color: widget.iconColor,
                size: 20,
              ),
            ),
            title: Text(
              suggestion.address,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              '${suggestion.latitude.toStringAsFixed(4)}, ${suggestion.longitude.toStringAsFixed(4)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey[400],
            ),
            onTap: () => _selectLocation(suggestion, locationService),
          );
        },
      ),
    );
  }

  Widget _buildSelectedLocationCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.iconColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: widget.iconColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Location',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedLocation!.address,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.iconColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}