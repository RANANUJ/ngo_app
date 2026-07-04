import 'package:flutter/material.dart';

/// A generic pulsing widget to represent loading elements.
class SkeletonContainer extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const SkeletonContainer({
    Key? key,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  }) : super(key: key);

  @override
  State<SkeletonContainer> createState() => _SkeletonContainerState();
}

class _SkeletonContainerState extends State<SkeletonContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: widget.borderRadius,
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton representing a standard vertical list of items.
class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final double height;

  const ListSkeleton({
    Key? key,
    this.itemCount = 5,
    this.height = 80,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SkeletonContainer(
                width: height,
                height: height,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonContainer(height: 16, width: 140),
                    const SizedBox(height: 8),
                    const SkeletonContainer(height: 12, width: double.infinity),
                    const SizedBox(height: 4),
                    const SkeletonContainer(height: 12, width: 180),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton representing a grid of cards (e.g. NGO Feed or Explore tab).
class GridSkeleton extends StatelessWidget {
  final int itemCount;

  const GridSkeleton({
    Key? key,
    this.itemCount = 6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(12),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SkeletonContainer(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              SizedBox(height: 12),
              SkeletonContainer(height: 14, width: 120),
              SizedBox(height: 6),
              SkeletonContainer(height: 10, width: 80),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton for Profile views (header card + settings list rows).
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header Card Skeleton
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Column(
              children: [
                SkeletonContainer(
                  width: 90,
                  height: 90,
                  borderRadius: BorderRadius.all(Radius.circular(45)),
                ),
                SizedBox(height: 16),
                SkeletonContainer(height: 18, width: 160),
                SizedBox(height: 8),
                SkeletonContainer(height: 12, width: 220),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Stats Row
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        SkeletonContainer(height: 16, width: 30),
                        SizedBox(height: 6),
                        SkeletonContainer(height: 10, width: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // List Settings Menu Items
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: const Row(
                    children: [
                      SkeletonContainer(
                        width: 24,
                        height: 24,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      SizedBox(width: 16),
                      SkeletonContainer(height: 14, width: 120),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Skeleton layout specific to the Admin Dashboard requests manager.
class AdminDashboardSkeleton extends StatelessWidget {
  const AdminDashboardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats boxes section mimicking original design
        Container(
          color: const Color(0xFF0099B8),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Container(
                  height: 80,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 6,
                    right: index == 3 ? 0 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SkeletonContainer(height: 14, width: 45),
                      SizedBox(height: 8),
                      SkeletonContainer(height: 10, width: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Filter tabs mock
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              4,
              (index) => const SkeletonContainer(
                height: 32,
                width: 80,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
        ),
        // List of Requests
        const Expanded(
          child: ListSkeleton(itemCount: 4, height: 70),
        ),
      ],
    );
  }
}
