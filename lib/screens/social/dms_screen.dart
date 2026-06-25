import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';

class DmsScreen extends StatefulWidget {
  const DmsScreen({super.key});

  @override
  State<DmsScreen> createState() => _DmsScreenState();
}

class _DmsScreenState extends State<DmsScreen> {
  final List<Map<String, String>> _messages = [
    {
      'sender': 'Aria Sterling',
      'message': 'Did you solve problem set 3 of Quantum tunneling?',
      'time': '12:30 PM',
    },
    {
      'sender': 'Devon Drake',
      'message': 'Let\'s set up a study session tonight in the guild voice channel.',
      'time': '10:45 AM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Direct Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final dm = _messages[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF8B5CF6),
                child: Text(
                  dm['sender']!.isNotEmpty ? dm['sender']![0].toUpperCase() : 'L',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              title: Text(dm['sender']!, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(dm['message']!, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(dm['time']!, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Starting DM with ${dm['sender']}')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
