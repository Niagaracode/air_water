class TimeZoneUtils {
  static const List<String> ianaTimeZones = [
    'Africa/Cairo',
    'Africa/Johannesburg',
    'Africa/Lagos',
    'Africa/Nairobi',
    'America/Anchorage',
    'America/Argentina/Buenos_Aires',
    'America/Chicago',
    'America/Denver',
    'America/Halifax',
    'America/Los_Angeles',
    'America/Mexico_City',
    'America/New_York',
    'America/Phoenix',
    'America/Sao_Paulo',
    'Asia/Bangkok',
    'Asia/Dubai',
    'Asia/Hong_Kong',
    'Asia/Jakarta',
    'Asia/Jerusalem',
    'Asia/Kolkata',
    'Asia/Manila',
    'Asia/Riyadh',
    'Asia/Seoul',
    'Asia/Shanghai',
    'Asia/Singapore',
    'Asia/Taipei',
    'Asia/Tokyo',
    'Atlantic/Azores',
    'Atlantic/Cape_Verde',
    'Australia/Adelaide',
    'Australia/Brisbane',
    'Australia/Darwin',
    'Australia/Melbourne',
    'Australia/Perth',
    'Australia/Sydney',
    'Europe/Amsterdam',
    'Europe/Berlin',
    'Europe/Brussels',
    'Europe/Budapest',
    'Europe/Copenhagen',
    'Europe/Dublin',
    'Europe/Helsinki',
    'Europe/Istanbul',
    'Europe/Lisbon',
    'Europe/London',
    'Europe/Madrid',
    'Europe/Moscow',
    'Europe/Oslo',
    'Europe/Paris',
    'Europe/Prague',
    'Europe/Rome',
    'Europe/Stockholm',
    'Europe/Vienna',
    'Europe/Warsaw',
    'Europe/Zurich',
    'Pacific/Auckland',
    'Pacific/Fiji',
    'Pacific/Honolulu',
    'UTC',
  ];

  static String? getDefaultTimeZoneForCountry(String? countryName) {
    if (countryName == null) return null;
    final normalized = countryName.trim().toLowerCase();
    switch (normalized) {
      case 'india':
        return 'Asia/Kolkata';
      case 'united states':
      case 'us':
      case 'usa':
        return 'America/New_York';
      case 'united kingdom':
      case 'uk':
      case 'great britain':
        return 'Europe/London';
      case 'united arab emirates':
      case 'uae':
        return 'Asia/Dubai';
      case 'saudi arabia':
        return 'Asia/Riyadh';
      case 'singapore':
        return 'Asia/Singapore';
      case 'japan':
        return 'Asia/Tokyo';
      case 'china':
        return 'Asia/Shanghai';
      case 'thailand':
        return 'Asia/Bangkok';
      case 'hong kong':
        return 'Asia/Hong_Kong';
      case 'indonesia':
        return 'Asia/Jakarta';
      case 'israel':
        return 'Asia/Jerusalem';
      case 'philippines':
        return 'Asia/Manila';
      case 'south korea':
      case 'korea, republic of':
      case 'korea':
        return 'Asia/Seoul';
      case 'taiwan':
        return 'Asia/Taipei';
      case 'egypt':
        return 'Africa/Cairo';
      case 'south africa':
        return 'Africa/Johannesburg';
      case 'nigeria':
        return 'Africa/Lagos';
      case 'kenya':
        return 'Africa/Nairobi';
      case 'argentina':
        return 'America/Argentina/Buenos_Aires';
      case 'mexico':
        return 'America/Mexico_City';
      case 'brazil':
        return 'America/Sao_Paulo';
      case 'cape verde':
        return 'Atlantic/Cape_Verde';
      case 'australia':
        return 'Australia/Sydney';
      case 'netherlands':
        return 'Europe/Amsterdam';
      case 'germany':
        return 'Europe/Berlin';
      case 'belgium':
        return 'Europe/Brussels';
      case 'hungary':
        return 'Europe/Budapest';
      case 'denmark':
        return 'Europe/Copenhagen';
      case 'ireland':
        return 'Europe/Dublin';
      case 'finland':
        return 'Europe/Helsinki';
      case 'turkey':
        return 'Europe/Istanbul';
      case 'portugal':
        return 'Europe/Lisbon';
      case 'spain':
        return 'Europe/Madrid';
      case 'russia':
      case 'russian federation':
        return 'Europe/Moscow';
      case 'norway':
        return 'Europe/Oslo';
      case 'france':
        return 'Europe/Paris';
      case 'czech republic':
        return 'Europe/Prague';
      case 'italy':
        return 'Europe/Rome';
      case 'sweden':
        return 'Europe/Stockholm';
      case 'austria':
        return 'Europe/Vienna';
      case 'poland':
        return 'Europe/Warsaw';
      case 'switzerland':
        return 'Europe/Zurich';
      case 'new zealand':
        return 'Pacific/Auckland';
      case 'fiji':
        return 'Pacific/Fiji';
      case 'canada':
        return 'America/Halifax';
      default:
        return null;
    }
  }
}

