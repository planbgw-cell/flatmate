// 시·도 short names and 권역 (`public_scope=zone`) as grouped by the server.

const _sidoShort = <String, String>{
  '서울특별시': '서울',
  '서울': '서울',
  '인천광역시': '인천',
  '인천': '인천',
  '경기도': '경기',
  '경기': '경기',
  '강원특별자치도': '강원',
  '강원도': '강원',
  '강원': '강원',
  '대전광역시': '대전',
  '대전': '대전',
  '세종특별자치시': '세종',
  '세종': '세종',
  '충청북도': '충북',
  '충북': '충북',
  '충청남도': '충남',
  '충남': '충남',
  '전북특별자치도': '전북',
  '전라북도': '전북',
  '전북': '전북',
  '전남광주통합특별시': '전남광주',
  '광주광역시': '광주',
  '광주': '광주',
  '전라남도': '전남',
  '전남': '전남',
  '대구광역시': '대구',
  '대구': '대구',
  '경상북도': '경북',
  '경북': '경북',
  '부산광역시': '부산',
  '부산': '부산',
  '울산광역시': '울산',
  '울산': '울산',
  '경상남도': '경남',
  '경남': '경남',
  '제주특별자치도': '제주',
  '제주도': '제주',
  '제주': '제주',
};

/// Zone → its 시·도 (short names), matching the server's `zone` grouping.
const kZoneSidos = <String, List<String>>{
  '수도권': ['서울', '인천', '경기'],
  '강원권': ['강원'],
  '충청권': ['대전', '세종', '충북', '충남'],
  '호남권': ['전북', '전남광주', '광주', '전남'],
  '대경권': ['대구', '경북'],
  '동남권': ['부산', '울산', '경남'],
  '제주권': ['제주'],
};

/// "경기도" → "경기", "서울특별시" → "서울"; null if not a 시·도.
String? sidoShortName(String? sido) {
  final value = sido?.trim() ?? '';
  return value.isEmpty ? null : _sidoShort[value];
}

/// 권역 name for a 시·도 (full or short), e.g. "경기도" → "수도권".
String? zoneOf(String? sido) {
  final short = sidoShortName(sido) ?? sido?.trim();
  if (short == null || short.isEmpty) return null;
  for (final entry in kZoneSidos.entries) {
    if (entry.value.contains(short)) return entry.key;
  }
  return null;
}

/// "수도권(서울·인천·경기)".
String zoneDescription(String zone) {
  final sidos = kZoneSidos[zone];
  return sidos == null ? zone : '$zone(${sidos.where((s) => s != '광주' && s != '전남').join('·')})';
}

final _districtToken = RegExp(r'^[가-힣]+(시|군|구)$');

/// "경기도 가평군 …" → "경기 가평군", "서울특별시 종로구 …" → "서울 종로구",
/// "세종특별자치시 …" → "세종"; empty when the address has no 시·도.
String regionLabel(String? address) {
  final tokens = (address ?? '').trim().split(RegExp(r'\s+'));
  if (tokens.isEmpty) return '';
  final sido = sidoShortName(tokens.first);
  if (sido == null) return '';
  final district = tokens.skip(1).firstWhere(
        _districtToken.hasMatch,
        orElse: () => '',
      );
  return district.isEmpty ? sido : '$sido $district';
}

/// Public notice region: "경기 양평군" with a 시·군·구, else the 시·도 as
/// written for 광역 notices ("서울특별시"); empty without a 시·도.
String noticeRegionLabel(String? address) {
  final label = regionLabel(address);
  if (label.isEmpty || label.contains(' ')) return label;
  return (address ?? '').trim().split(RegExp(r'\s+')).first;
}

/// 권역 of an address's 시·도, e.g. "경기도 가평군 …" → "수도권".
String? zoneOfAddress(String? address) {
  final first = (address ?? '').trim().split(RegExp(r'\s+')).first;
  return zoneOf(first);
}
