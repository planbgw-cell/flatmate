import '../models/property_model.dart';

abstract class PropertyRemoteDataSource {
  Future<List<PropertyModel>> fetchProperties();
}

class PropertyRemoteDataSourceStub implements PropertyRemoteDataSource {
  @override
  Future<List<PropertyModel>> fetchProperties() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return [
      PropertyModel(
        id: 'p-101',
        title: '신촌 원룸 · 풀옵션',
        address: '서울 서대문구 신촌로 12',
        monthlyRent: 620000,
        type: 'room',
        thumbnailUrl: 'https://picsum.photos/seed/prop101/400/400',
        availableFrom: DateTime(2026, 10, 1),
      ),
      PropertyModel(
        id: 'p-102',
        title: '홍대 단기임대 투룸',
        address: '서울 마포구 어울마당로 45',
        monthlyRent: 950000,
        type: 'shortStay',
        thumbnailUrl: 'https://picsum.photos/seed/prop102/400/400',
        availableFrom: DateTime(2026, 9, 20),
      ),
      PropertyModel(
        id: 'p-103',
        title: '건대입구 오픈형 원룸',
        address: '서울 광진구 능동로 88',
        monthlyRent: 580000,
        type: 'listing',
        thumbnailUrl: 'https://picsum.photos/seed/prop103/400/400',
        availableFrom: DateTime(2026, 11, 5),
      ),
    ];
  }
}
