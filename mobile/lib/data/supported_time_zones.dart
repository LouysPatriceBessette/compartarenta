import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Default explicit zone when none stored (Canada/US eastern hub).
const String kDefaultExplicitTimeZoneId = 'America/Toronto';

bool _ianaDatabaseInitialized = false;
List<String>? _cachedIanaIds;
Set<String>? _cachedIanaIdSet;

/// Loads the full IANA tz database (idempotent).
void ensureIanaTimeZonesLoaded() {
  if (_ianaDatabaseInitialized) return;
  tz_data.initializeTimeZones();
  _ianaDatabaseInitialized = true;
}

/// Every canonical IANA location id from the bundled database (sorted).
List<String> get allIanaTimeZoneIds {
  ensureIanaTimeZonesLoaded();
  _cachedIanaIds ??= tz.timeZoneDatabase.locations.keys.toList()..sort();
  return _cachedIanaIds!;
}

Set<String> get _ianaIdSet {
  ensureIanaTimeZonesLoaded();
  _cachedIanaIdSet ??= allIanaTimeZoneIds.toSet();
  return _cachedIanaIdSet!;
}

bool isKnownIanaTimeZoneId(String id) => _ianaIdSet.contains(id.trim());

/// User-facing label, e.g. `Amériques/Montevideo` for `America/Montevideo`.
String ianaTimeZoneDisplayName(String ianaId, Locale locale) {
  final parts = ianaId.split('/');
  if (parts.isEmpty || parts.first.isEmpty) return ianaId;
  if (parts.length == 1) {
    return _localizedTopLevelRegion(parts.first, locale.languageCode);
  }
  final region = _localizedTopLevelRegion(parts.first, locale.languageCode);
  final rest = parts
      .sublist(1)
      .map(_humanizeLocationSegment)
      .join('/');
  return '$region/$rest';
}

bool ianaTimeZoneMatchesQuery(String ianaId, String query, Locale locale) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (ianaId.toLowerCase().contains(q)) return true;
  if (ianaTimeZoneDisplayName(ianaId, locale).toLowerCase().contains(q)) {
    return true;
  }
  for (final segment in ianaId.split('/')) {
    if (_humanizeLocationSegment(segment).toLowerCase().contains(q)) {
      return true;
    }
  }
  return false;
}

String _humanizeLocationSegment(String segment) {
  return segment.replaceAll('_', ' ');
}

/// CLDR-style region labels for the first path segment of an IANA id.
String _localizedTopLevelRegion(String region, String languageCode) {
  final labels = _regionLabelTable[region];
  if (labels == null) {
    return _humanizeLocationSegment(region);
  }
  return switch (languageCode) {
    'fr' => labels.$2,
    'es' => labels.$3,
    _ => labels.$1,
  };
}

/// (en, fr, es) display names for IANA area prefixes.
const Map<String, (String, String, String)> _regionLabelTable = {
  'Africa': ('Africa', 'Afrique', 'África'),
  'America': ('Americas', 'Amériques', 'América'),
  'Antarctica': ('Antarctica', 'Antarctique', 'Antártida'),
  'Arctic': ('Arctic', 'Arctique', 'Ártico'),
  'Asia': ('Asia', 'Asie', 'Asia'),
  'Atlantic': ('Atlantic', 'Atlantique', 'Atlántico'),
  'Australia': ('Australia', 'Australie', 'Australia'),
  'Europe': ('Europe', 'Europe', 'Europa'),
  'Indian': ('Indian Ocean', 'Océan Indien', 'Océano Índico'),
  'Pacific': ('Pacific', 'Pacifique', 'Pacífico'),
  'Etc': ('Other', 'Autre', 'Otro'),
};

