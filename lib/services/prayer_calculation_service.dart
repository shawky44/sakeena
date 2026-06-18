import 'package:adhan_dart/adhan_dart.dart';

class PrayerCalculationService {
  const PrayerCalculationService._();

  static CalculationParameters parametersFor({
    required double latitude,
    required double longitude,
    String? country,
  }) {
    final countryLower = country?.toLowerCase() ?? '';
    final CalculationParameters parameters;

    if (_containsAny(countryLower, const [
      'egypt',
      'مصر',
      'sudan',
      'السودان',
      'libya',
      'ليبيا',
    ])) {
      parameters = CalculationMethod.egyptian();
    } else if (_containsAny(countryLower, const [
          'united states',
          'canada',
          'أمريكا',
          'كندا',
        ]) ||
        (latitude > 25 &&
            latitude < 50 &&
            longitude > -130 &&
            longitude < -60)) {
      parameters = CalculationMethod.northAmerica();
    } else if (_containsAny(countryLower, const [
      'saudi',
      'السعودية',
      'kuwait',
      'الكويت',
      'qatar',
      'قطر',
      'bahrain',
      'البحرين',
      'emirates',
      'الإمارات',
      'oman',
      'عمان',
    ])) {
      parameters = CalculationMethod.ummAlQura();
    } else if (_containsAny(countryLower, const [
      'turkey',
      'تركيا',
      'türkiye',
    ])) {
      parameters = CalculationMethod.turkiye();
    } else if (_containsAny(countryLower, const [
      'iran',
      'إيران',
      'iraq',
      'العراق',
    ])) {
      parameters = CalculationMethod.tehran();
    } else if (_containsAny(countryLower, const [
      'pakistan',
      'باكستان',
      'india',
      'الهند',
      'bangladesh',
      'بنغلاديش',
    ])) {
      parameters = CalculationMethod.karachi();
    } else if (_containsAny(countryLower, const [
      'malaysia',
      'ماليزيا',
      'singapore',
      'سنغافورة',
      'indonesia',
      'إندونيسيا',
      'brunei',
      'بروناي',
    ])) {
      parameters = CalculationMethod.singapore();
    } else if (_containsAny(countryLower, const [
      'morocco',
      'المغرب',
      'tunisia',
      'تونس',
      'algeria',
      'الجزائر',
      'mauritania',
      'موريتانيا',
    ])) {
      parameters = CalculationMethod.moonsightingCommittee();
    } else {
      parameters = CalculationMethod.muslimWorldLeague();
    }

    parameters.madhab =
        _usesStandardAsr(countryLower) ? Madhab.shafi : Madhab.hanafi;
    if (latitude.abs() > 48) {
      parameters.highLatitudeRule = HighLatitudeRule.middleOfTheNight;
    }
    return parameters;
  }

  static bool _usesStandardAsr(String countryLower) {
    return _containsAny(countryLower, const [
      'egypt',
      'saudi',
      'kuwait',
      'emirates',
      'malaysia',
      'indonesia',
      'مصر',
      'السعودية',
      'الكويت',
      'الإمارات',
      'ماليزيا',
      'إندونيسيا',
    ]);
  }

  static bool _containsAny(String value, List<String> candidates) {
    return candidates.any(value.contains);
  }
}
