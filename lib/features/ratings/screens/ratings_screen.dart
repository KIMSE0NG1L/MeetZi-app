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

  Future<void> _buyCredit(int coins) async {
    setState(() => _loading = true);
    try {
      await _repository.buyCredit(coins);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$coins 코인 구매 완료!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구매 실패: ${e.toString()}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상점'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '크레딧(코인) 구매',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
    );
  }
}
