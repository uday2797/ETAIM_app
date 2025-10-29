# ETAIM - AI-Powered Daily Activities Dashboard

## Project Overview
ETAIM is a Flutter mobile application that has been configured to run as a web application on Replit. It provides AI-powered insights for daily activities including commute planning and food delivery recommendations.

## Project Structure
- **etaim/** - Main Flutter application directory
  - **lib/** - Flutter application source code
    - **models/** - Data models (User, Location, Dashboard, CommuteOption, FoodOption)
    - **screens/** - UI screens (Auth, Home, Commute, Food, Dashboard)
    - **services/** - Business logic services (Auth, Location, Weather, AI, Commute, Food)
    - **widgets/** - Reusable UI components
    - **utils/** - Constants and helper functions
  - **web/** - Web platform specific files
  - **assets/** - Images and animations
  - **pubspec.yaml** - Flutter dependencies configuration

## Key Features
1. **Authentication** - User login, signup, and password reset
2. **Home Dashboard** - Weather information, quick actions, and app overview
3. **AI Insights** - Personalized recommendations for commute and food based on:
   - Current weather conditions
   - Time of day
   - Distance and traffic patterns
4. **Commute Planning** - Compare options from Rapido, Ola, Uber, and own vehicle
5. **Food Delivery** - Recommendations from Swiggy and Zomato

## Technical Stack
- **Framework**: Flutter 3.32.0
- **Language**: Dart 3.8.0
- **State Management**: Provider pattern
- **Key Dependencies**:
  - google_fonts - Typography
  - geolocator/geocoding - Location services
  - http/dio - API calls
  - shared_preferences - Local storage
  - url_launcher - Deep linking

## Development Setup
The application runs on port 5000 in development mode with:
- Host: 0.0.0.0 (required for Replit proxy)
- Hot reload enabled
- Debug mode active

## Deployment Configuration
- **Target**: Autoscale (stateless web application)
- **Build**: `flutter build web --release`
- **Run**: Flutter web server on port 5000

## Recent Changes (October 29, 2025)
1. Added web platform support to Flutter project
2. Fixed misnamed class files (FoodService, HomeScreen)
3. Created proper HomeScreen with tab navigation
4. Fixed color indexing issues in dashboard view
5. Configured deployment settings for Replit
6. Set up workflow to run on port 5000

## Notes
- Uses mock data for weather and service providers (no real API keys required)
- Google Maps API key placeholder in constants.dart (not required for core functionality)
- All services use simulated data with realistic delays
