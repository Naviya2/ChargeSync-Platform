/// Station data model used across the Stations screen.
class StationData {
  final int id;
  final String title;
  final String address;
  final String speed;
  final String distance;
  final String time;
  final String price;
  final String stallsText;
  final String compatibility;
  final bool isCompatible;
  final List<String> connectors;
  final int totalStalls;
  final int freeStalls;
  final String badge;
  final bool requiresAdapter;

  const StationData({
    required this.id,
    required this.title,
    required this.address,
    required this.speed,
    required this.distance,
    required this.time,
    required this.price,
    required this.stallsText,
    required this.compatibility,
    required this.isCompatible,
    required this.connectors,
    required this.totalStalls,
    required this.freeStalls,
    this.badge = '',
    this.requiresAdapter = false,
  });
}

const List<StationData> kStations = [
  StationData(
    id: 1,
    title: 'Electrify Metro Hub',
    address: '742 Market St, Financial District',
    speed: '250 kW',
    distance: '1.2 mi',
    time: '4 min',
    price: '\$0.31',
    stallsText: '4 of 6 stalls ready',
    compatibility: '100% Compatible with your Tesla Model Y',
    isCompatible: true,
    connectors: ['NACS (Tesla)', 'CCS2'],
    totalStalls: 6,
    freeStalls: 4,
    badge: 'Verified',
  ),
  StationData(
    id: 2,
    title: 'VoltStream Supergrid',
    address: '580 Howard St, SOMA',
    speed: '150 kW',
    distance: '2.1 mi',
    time: '7 min',
    price: '\$0.34',
    stallsText: '6 of 8 stalls ready',
    compatibility: '100% Compatible with your Tesla Model Y',
    isCompatible: true,
    connectors: ['NACS (Tesla)', 'CCS2', 'CHAdeMO'],
    totalStalls: 8,
    freeStalls: 6,
    badge: 'Verified',
  ),
  StationData(
    id: 3,
    title: 'Mission Green Charging',
    address: '2100 Mission St, Mission District',
    speed: '50 kW',
    distance: '3.4 mi',
    time: '11 min',
    price: '\$0.28',
    stallsText: '2 of 4 stalls ready',
    compatibility: 'Compatible with Tesla Model Y (Standard Rate)',
    isCompatible: true,
    connectors: ['J1772', 'CCS1', 'NACS'],
    totalStalls: 4,
    freeStalls: 2,
    badge: 'Eco Solar',
  ),
  StationData(
    id: 4,
    title: 'Marina Bay Fast Hub',
    address: '330 Marina Blvd, Fort Mason',
    speed: '175 kW',
    distance: '4.2 mi',
    time: '14 min',
    price: '\$0.36',
    stallsText: '1 of 4 stalls ready',
    compatibility: 'Requires CCS-to-NACS Adapter for Model Y',
    isCompatible: false,
    connectors: ['CCS1 Only'],
    totalStalls: 4,
    freeStalls: 1,
    badge: 'Adapter Req',
    requiresAdapter: true,
  ),
];
