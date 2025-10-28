import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LaunchPage extends StatelessWidget {
  const LaunchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.purple.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_tree,
                      size: 64,
                      color: Colors.deepPurple.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Vyuh Node Flow',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Interactive Examples',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // Examples Grid
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: GridView.count(
                      crossAxisCount: _getCrossAxisCount(context),
                      padding: const EdgeInsets.all(24),
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 24,
                      childAspectRatio: 1.2,
                      children: [
                        _ExampleCard(
                          title: 'Workbench',
                          description:
                              'Full-featured editor with theme customization, '
                              'multiple connection styles, and interactive controls',
                          icon: Icons.construction,
                          color: Colors.blue,
                          route: '/workbench',
                        ),
                        _ExampleCard(
                          title: 'Annotations',
                          description:
                              'Demonstrates sticky notes, labels, and custom '
                              'annotations that can follow nodes',
                          icon: Icons.note_add,
                          color: Colors.orange,
                          route: '/annotations',
                        ),
                        _ExampleCard(
                          title: 'Connection Validation',
                          description:
                              'Shows custom validation rules, port compatibility, '
                              'and connection restrictions',
                          icon: Icons.rule,
                          color: Colors.green,
                          route: '/validation',
                        ),
                        _ExampleCard(
                          title: 'Viewer',
                          description:
                              'Read-only mode for displaying workflows and '
                              'diagrams without editing capabilities',
                          icon: Icons.visibility,
                          color: Colors.purple,
                          route: '/viewer',
                        ),
                        _ExampleCard(
                          title: 'Port Combinations',
                          description:
                              'Explore different port positions, shapes, and '
                              'configurations on nodes',
                          icon: Icons.account_tree_outlined,
                          color: Colors.teal,
                          route: '/port-combinations',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Built with Flutter • Powered by Vyuh',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 3;
    if (width > 800) return 2;
    return 1;
  }
}

class _ExampleCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;

  const _ExampleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
  });

  @override
  State<_ExampleCard> createState() => _ExampleCardState();
}

class _ExampleCardState extends State<_ExampleCard> {
  bool _isHovered = false;

  /// Helper to darken a color by a given amount (0.0 to 1.0)
  Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return darkened.toColor();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(
            0.0,
            _isHovered ? -8.0 : 0.0,
            0.0,
          ),
          child: Card(
            elevation: _isHovered ? 12 : 4,
            shadowColor: widget.color.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: _isHovered
                    ? widget.color.withValues(alpha: 0.5)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, widget.color.withValues(alpha: 0.05)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 32,
                      color: _darkenColor(widget.color, 0.3),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _darkenColor(widget.color, 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Expanded(
                    child: Text(
                      widget.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Arrow indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Explore',
                        style: TextStyle(
                          color: _darkenColor(widget.color, 0.3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: _darkenColor(widget.color, 0.3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
