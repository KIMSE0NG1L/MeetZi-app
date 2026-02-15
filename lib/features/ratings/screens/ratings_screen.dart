import 'package:flutter/material.dart';
import 'package:nearo_app/features/matching_board/data/matching_board_repository.dart';

class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  static const List<Map<String, dynamic>> creditOptions = [
    {"coins": 1, "price": 1000},
    {"coins": 5, "price": 5000},
    {"coins": 10, "price": 9000},
    {"coins": 20, "price": 17000},
  ];

  final MatchingBoardRepository _repository = MatchingBoardRepository();
  bool _loading = false;
  int? _myCredit;

  @override
  void initState() {
    super.initState();
    _fetchCredit();
  }

  Future<void> _fetchCredit() async {
    try {
      final credit = await _repository.fetchMyCredit();
      if (mounted) setState(() => _myCredit = credit);
    } catch (_) {
      if (mounted) setState(() => _myCredit = null);
    }
  }

  Future<void> _buyCredit(int coins) async {
    setState(() => _loading = true);
    try {
      await _repository.buyCredit(coins);
      await _fetchCredit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$coins 코인 구매 완료!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구매 실패: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '크레딧(코인) 구매',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Icon(Icons.monetization_on, color: Colors.amber.shade700, size: 22),
                      const SizedBox(width: 4),
                      Text(
                        _myCredit != null ? '$_myCredit' : '-',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount: creditOptions.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final option = creditOptions[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text('${option["coins"]}'),
                            ),
                            title: Text('${option["coins"]} 코인'),
                            subtitle: Text('${option["price"]}원'),
                            trailing: ElevatedButton(
                              onPressed: () => _buyCredit(option["coins"] as int),
                              child: const Text('구매'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
