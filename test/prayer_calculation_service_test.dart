import 'package:adhan_dart/adhan_dart.dart';
import 'package:azkar_app/services/prayer_calculation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrayerCalculationService', () {
    test('uses the existing Egyptian configuration for Egypt', () {
      final parameters = PrayerCalculationService.parametersFor(
        latitude: 30.0444,
        longitude: 31.2357,
        country: 'Egypt',
      );

      expect(parameters.method, 'Egyptian');
      expect(parameters.madhab, Madhab.shafi);
    });

    test('uses Umm Al-Qura for Gulf countries', () {
      final parameters = PrayerCalculationService.parametersFor(
        latitude: 25.2854,
        longitude: 51.5310,
        country: 'Qatar',
      );

      expect(parameters.method, 'UmmAlQura');
    });

    test('uses North America based on coordinates', () {
      final parameters = PrayerCalculationService.parametersFor(
        latitude: 40.7128,
        longitude: -74.0060,
      );

      expect(parameters.method, 'NorthAmerica');
    });

    test('uses Karachi and Hanafi configuration for Pakistan', () {
      final parameters = PrayerCalculationService.parametersFor(
        latitude: 24.8607,
        longitude: 67.0011,
        country: 'Pakistan',
      );

      expect(parameters.method, 'Karachi');
      expect(parameters.madhab, Madhab.hanafi);
    });

    test('applies the high-latitude rule consistently', () {
      final parameters = PrayerCalculationService.parametersFor(
        latitude: 55.6761,
        longitude: 12.5683,
        country: 'Denmark',
      );

      expect(
        parameters.highLatitudeRule,
        HighLatitudeRule.middleOfTheNight,
      );
    });
  });
}
