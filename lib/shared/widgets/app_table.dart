import 'package:flutter/material.dart';

class AppTable extends StatelessWidget {
  final List<String> headers;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final VoidCallback? onLoadMore;
  final bool isLoading;
  final bool hasMore;

  const AppTable({
    super.key,
    required this.headers,
    required this.itemCount,
    required this.itemBuilder,
    this.onLoadMore,
    this.isLoading = false,
    this.hasMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          if (itemCount == 0 && !isLoading)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text(
                'No record found',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: itemBuilder,
            ),
            if (hasMore)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : TextButton(
                          onPressed: onLoadMore,
                          child: const Text('Load More'),
                        ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: headers
            .map(
              (header) => Expanded(
                child: Text(
                  header,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
