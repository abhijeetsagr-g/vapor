import 'package:flutter/material.dart';

import '../services/runner_discovery_service.dart';

class RunnerListScreen extends StatefulWidget {
  const RunnerListScreen({super.key});

  @override
  State<RunnerListScreen> createState() => _RunnerListScreenState();
}

class _RunnerListScreenState extends State<RunnerListScreen> {
  List<RunnerInfo> _runners = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() => _runners = RunnerDiscoveryService.discover());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Runners'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _runners.isEmpty
          ? const Center(child: Text('No runners found'))
          : ListView.builder(
              itemCount: _runners.length,
              itemBuilder: (context, index) {
                final runner = _runners[index];
                return ListTile(
                  leading: Icon(
                    runner.source == RunnerSource.system
                        ? Icons.computer
                        : Icons.folder,
                  ),
                  title: Text(runner.name),
                  subtitle: Text(runner.path),
                  trailing: Text(
                    runner.isProton ? 'Proton' : 'Wine',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
    );
  }
}
