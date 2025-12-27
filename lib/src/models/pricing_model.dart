import 'package:equatable/equatable.dart';

class PricingModel extends Equatable {
  final String id; // Usually the city name or 'default'
  final String city; 
  final double a4BasePrice;
  final double edSheetPrice;
  final double surcharge3Days;
  final double surcharge2Days;
  final double surcharge1Day;

  const PricingModel({
    required this.id,
    required this.city,
    required this.a4BasePrice,
    required this.edSheetPrice,
    required this.surcharge3Days,
    required this.surcharge2Days,
    required this.surcharge1Day,
  });

  // Default factory
  factory PricingModel.defaultPricing() {
    return const PricingModel(
      id: 'default',
      city: 'Default',
      a4BasePrice: 4.0,
      edSheetPrice: 230.0,
      surcharge3Days: 1.0,
      surcharge2Days: 2.0,
      surcharge1Day: 3.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'city': city,
      'a4BasePrice': a4BasePrice,
      'edSheetPrice': edSheetPrice,
      'surcharge3Days': surcharge3Days,
      'surcharge2Days': surcharge2Days,
      'surcharge1Day': surcharge1Day,
    };
  }

  factory PricingModel.fromMap(Map<String, dynamic> map) {
    return PricingModel(
      id: map['id'] ?? '',
      city: map['city'] ?? '',
      a4BasePrice: (map['a4BasePrice'] ?? 4.0).toDouble(),
      edSheetPrice: (map['edSheetPrice'] ?? 230.0).toDouble(),
      surcharge3Days: (map['surcharge3Days'] ?? 1.0).toDouble(),
      surcharge2Days: (map['surcharge2Days'] ?? 2.0).toDouble(),
      surcharge1Day: (map['surcharge1Day'] ?? 3.0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, city, a4BasePrice, edSheetPrice, surcharge3Days, surcharge2Days, surcharge1Day];
}
