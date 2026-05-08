/// Supported ISO 4217 currency codes with display labels (French, per product spec).
class SupportedCurrency {
  const SupportedCurrency(this.code, this.labelFr);

  final String code;
  final String labelFr;

  String get displayLine => '$code — $labelFr';

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return code.toLowerCase().contains(q) || labelFr.toLowerCase().contains(q);
  }
}

/// Fixed list for onboarding / settings currency selection (searchable combobox).
const List<SupportedCurrency> kSupportedCurrencies = [
  SupportedCurrency('ARS', 'peso argentin'),
  SupportedCurrency('AWG', 'florin arubais'),
  SupportedCurrency('BBD', 'dollar barbadien'),
  SupportedCurrency('BMD', 'dollar bermudien'),
  SupportedCurrency('BSD', 'dollar bahaméen'),
  SupportedCurrency('BZD', 'dollar bélizéen'),
  SupportedCurrency('CAD', 'dollar canadien'),
  SupportedCurrency('CLP', 'peso chilien'),
  SupportedCurrency('COP', 'peso colombien'),
  SupportedCurrency('CRC', 'colón costaricien'),
  SupportedCurrency('CUP', 'peso cubain'),
  SupportedCurrency('DOP', 'peso dominicain'),
  SupportedCurrency('EUR', 'euro'),
  SupportedCurrency('FKP', 'pound des îles Falkland'),
  SupportedCurrency('GBP', 'livre sterling'),
  SupportedCurrency('GYD', 'dollar guyanien'),
  SupportedCurrency('GTQ', 'quetzal guatémaltèque'),
  SupportedCurrency('HNL', 'lempira hondurien'),
  SupportedCurrency('HTG', 'gourde haïtienne'),
  SupportedCurrency('JMD', 'dollar jamaïcain'),
  SupportedCurrency('KYD', 'dollar des îles Caïmans'),
  SupportedCurrency('MXN', 'peso mexicain'),
  SupportedCurrency('NIO', 'córdoba nicaraguayen'),
  SupportedCurrency('PAB', 'balboa panaméen'),
  SupportedCurrency('PEN', 'sol péruvien'),
  SupportedCurrency('PYG', 'guarani paraguayen'),
  SupportedCurrency('SRD', 'dollar surinamais'),
  SupportedCurrency('SVC', 'colón salvadorien'),
  SupportedCurrency('TTD', 'dollar trinidadien et tobagonien'),
  SupportedCurrency('USD', 'dollar des États‑Unis'),
  SupportedCurrency('UYU', 'peso uruguayen'),
  SupportedCurrency('VES', 'bolívar vénézuélien'),
  SupportedCurrency('XCD', 'dollar des Caraïbes orientales'),
];

SupportedCurrency? supportedCurrencyByCode(String code) {
  final upper = code.trim().toUpperCase();
  for (final c in kSupportedCurrencies) {
    if (c.code == upper) return c;
  }
  return null;
}
