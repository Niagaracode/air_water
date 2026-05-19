import 'package:flutter/material.dart';

class TankEventsTab extends StatelessWidget {

  const TankEventsTab({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (context, index) {

        return ListTile(
          title: Text("event.title"),
          subtitle: Text("event.description"),
        );
      },
    );
  }
}