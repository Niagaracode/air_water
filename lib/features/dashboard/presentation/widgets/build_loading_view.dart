import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

Widget buildLoadingView() {
  return Skeletonizer(
    enabled: true,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5,
                  (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index != 4 ? 16 : 0,
                  ),
                  child: _skeletonBox(height: 60),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          /// Header
          _skeletonBox(width: 250, height: 28, radius: 8),
          const SizedBox(height: 20),
          /// Search Filters
          Row(
            children: [
              Expanded(flex: 3, child: _skeletonBox(height: 42)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _skeletonBox(height: 42)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _skeletonBox(height: 42)),
              const SizedBox(width: 16),
              _skeletonBox(width: 40, height: 42),
            ],
          ),
          const SizedBox(height: 20),
          /// Toggle
          Row(
            children: [
              _skeletonBox(width: 120, height: 34),
              const SizedBox(width: 12),
              _skeletonBox(width: 120, height: 34),
            ],
          ),
          const SizedBox(height: 24),
          /// Device Cards
          ...List.generate(6,
                (index) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _skeletonBox(width: 40, height: 20),
                  const SizedBox(width: 8),
                  Expanded(child: _skeletonBox(height: 20)),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _skeletonBox({
  double? width,
  double height = 16,
  double radius = 12,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}