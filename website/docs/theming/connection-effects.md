---
title: Connection Effects
description: Bring your diagrams to life with flowing animations
---

# Connection Animation Effects

Add visual effects to connections to show flow direction, data movement, or
simply to enhance the visual appeal of your diagrams. Effects can be applied at
the theme level (affecting all connections) or per-connection for fine-grained
control.

::: tip
**Why Use Effects?** Animation effects help users understand data flow
  direction, emphasize active connections, and create more engaging,
  professional-looking diagrams.

:::

::: details 🖼️ Connection Effects Showcase
Animated GIF showing all four effects simultaneously on different connections: FlowingDash (marching ants pattern), ParticleEffect (dots traveling along path), GradientFlow (smooth color wave), PulseEffect (breathing opacity/width). Each connection labeled.
:::

## Available Effects

Vyuh Node Flow provides four built-in animation effects:

### FlowingDashEffect

Creates a flowing dash pattern along the connection, similar to the classic
"marching ants" effect.

```dart
FlowingDashEffect(
  speed: 2,          // Complete cycles per animation period
  dashLength: 10,    // Length of each dash (pixels)
  gapLength: 5,      // Length of gap between dashes (pixels)
)
```

**Best for**: Showing active or selected connections, indicating data transfer

::: code-group

```dart [Basic Usage]
connectionTheme: ConnectionTheme(
  animationEffect: FlowingDashEffect(
    speed: 2,
    dashLength: 10,
    gapLength: 5,
  ),
)
```

```dart [Fast Flow]
// Faster animation for urgent/priority connections
connectionTheme: ConnectionTheme(
  animationEffect: FlowingDashEffect(
    speed: 4,          // 4x faster
    dashLength: 8,
    gapLength: 4,
  ),
)
```

```dart [Slow Flow]
// Slower, calmer animation
connectionTheme: ConnectionTheme(
  animationEffect: FlowingDashEffect(
    speed: 0.5,        // Half speed
    dashLength: 15,
    gapLength: 8,
  ),

)
```

```dart [Long Dashes]
// Longer dashes for dramatic effect
connectionTheme: ConnectionTheme(
  animationEffect: FlowingDashEffect(
    speed: 1,
    dashLength: 20,    // Longer dashes
    gapLength: 10,
  ),
)
```

:::

Shows particles traveling along the connection path, perfect for visualizing
data flow or direction.

```dart
ParticleEffect(
  particleCount: 5,         // Number of particles
  speed: 1,                 // Complete cycles per animation period
  connectionOpacity: 0.3,   // Opacity of base connection (0.0-1.0)
  particlePainter: CircleParticle(radius: 4.0), // Particle appearance
)
```

::: details 🖼️ Particle Effect Variations
Animation showing different particle types: (1) circles flowing along path, (2) arrows indicating direction, (3) custom characters/emojis. Each with different particle counts and speeds.
:::

**Best for**: Data flow visualization, showing direction, active pipelines

::: code-group

```dart [Circles]
connectionTheme: ConnectionTheme(
  animationEffect: ParticleEffect(
    particleCount: 3,
    speed: 1,
    connectionOpacity: 0.3,
    particlePainter: CircleParticle(radius: 4.0),
  ),
)
```

```dart [Arrows]
// Arrow-shaped particles
connectionTheme: ConnectionTheme(
  animationEffect: ParticleEffect(
    particleCount: 5,
    speed: 1.5,
    connectionOpacity: 0.2,
    particlePainter: ArrowParticle(
      length: 12.0,
      width: 8.0,
    ),
  ),
)
```

```dart [Characters]
// Text/emoji particles
connectionTheme: ConnectionTheme(
  animationEffect: ParticleEffect(
    particleCount: 4,
    speed: 1,
    connectionOpacity: 0.3,
    particlePainter: CharacterParticle(
      character: '→',
      fontSize: 16.0,
    ),
  ),
)
```

```dart [Many Particles]
// Dense particle stream
connectionTheme: ConnectionTheme(
  animationEffect: ParticleEffect(
    particleCount: 10,  // Many particles
    speed: 2,           // Fast movement
    connectionOpacity: 0.1, // Very faint base line
    particlePainter: CircleParticle(radius: 3.0),
  ),
)
```

:::

## Custom Particle Painters

Create your own particle appearance:

```dart
class StarParticle implements ParticlePainter {
  final double size;
  final Color color;

  StarParticle({this.size = 8.0, this.color = Colors.yellow});

  @override
  void paint(Canvas canvas, Size size, Color color, double progress) {
    final paint = Paint()
      ..color = this.color
      ..style = PaintingStyle.fill;

    final path = Path();
    // Draw a 5-pointed star
    for (var i = 0; i < 5; i++) {
      final angle = (i * 2 * pi / 5) - pi / 2;
      final outerX = cos(angle) * this.size;
      final outerY = sin(angle) * this.size;

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }

      final innerAngle = angle + pi / 5;
      final innerX = cos(innerAngle) * (this.size / 2);
      final innerY = sin(innerAngle) * (this.size / 2);
      path.lineTo(innerX, innerY);
    }
    path.close();

    canvas.drawPath(path, paint);
  }
}

// Usage
ParticleEffect(
  particleCount: 3,
  speed: 1,
  particlePainter: StarParticle(size: 10, color: Colors.yellow),
)
```

### GradientFlowEffect

Creates a smoothly flowing gradient along the connection path.

```dart
GradientFlowEffect(
  colors: [
    Colors.blue.withOpacity(0.0),
    Colors.blue,
    Colors.blue.withOpacity(0.0),
  ],
  speed: 1,                  // Complete cycles per animation period
  gradientLength: 0.25,      // Length as fraction of path (< 1) or pixels (>= 1)
  connectionOpacity: 1.0,    // Opacity of base connection (0.0-1.0)
)
```

**Best for**: Elegant, subtle animations; showing smooth data flow

::: code-group

```dart [Blue Wave]
connectionTheme: ConnectionTheme(
  animationEffect: GradientFlowEffect(
    colors: [
      Colors.blue.withOpacity(0.0),
      Colors.blue,
      Colors.lightBlue,
      Colors.blue,
      Colors.blue.withOpacity(0.0),
    ],
    speed: 1,
    gradientLength: 0.3,
  ),
)
```

```dart [Rainbow]
connectionTheme: ConnectionTheme(
  animationEffect: GradientFlowEffect(
    colors: [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
    ],
    speed: 0.5,
    gradientLength: 0.5,
  ),
)
```

```dart [Alert]
// Red alert flow
connectionTheme: ConnectionTheme(
  animationEffect: GradientFlowEffect(
    colors: [
      Colors.red.withOpacity(0.0),
      Colors.red,
      Colors.red.shade900,
      Colors.red,
      Colors.red.withOpacity(0.0),
    ],
    speed: 2,  // Fast
    gradientLength: 0.2,
  ),
)
```

```dart [Subtle]
// Very subtle gradient
connectionTheme: ConnectionTheme(
  animationEffect: GradientFlowEffect(
    colors: [
      Colors.grey.withOpacity(0.0),
      Colors.grey.withOpacity(0.5),
      Colors.grey.withOpacity(0.0),
    ],
    speed: 0.3,  // Very slow
    gradientLength: 0.15,
    connectionOpacity: 0.5,
  ),
)
```

:::

Creates a pulsing or breathing effect by animating the connection's opacity and
optionally its width.

```dart
PulseEffect(
  speed: 1,              // Complete pulse cycles per animation period
  minOpacity: 0.4,       // Minimum opacity during pulse
  maxOpacity: 1.0,       // Maximum opacity during pulse
  widthVariation: 1.5,   // Width multiplier at peak (1.0 = no variation)
)
```

::: details 🖼️ Pulse Effect
Animation showing connections pulsing/breathing with opacity and width variation: subtle pulse (minimal change), heartbeat (dramatic), width emphasis, and fast blink. Shows minOpacity to maxOpacity transitions.
:::

**Best for**: Highlighting connections, showing heartbeat/health, drawing
attention

::: code-group

```dart [Subtle Pulse]
connectionTheme: ConnectionTheme(
  animationEffect: PulseEffect(
    speed: 1,
    minOpacity: 0.7,
    maxOpacity: 1.0,
    widthVariation: 1.0, // No width change
  ),
)
```

```dart [Heartbeat]
// Heartbeat-like pulse
connectionTheme: ConnectionTheme(
  animationEffect: PulseEffect(
    speed: 2,  // Faster pulse
    minOpacity: 0.3,
    maxOpacity: 1.0,
    widthVariation: 1.8,
  ),
)
```

```dart [Width Pulse]
// Emphasize width changes
connectionTheme: ConnectionTheme(
  animationEffect: PulseEffect(
    speed: 1,
    minOpacity: 0.8,
    maxOpacity: 1.0,
    widthVariation: 2.0,  // 2x width at peak
  ),
)
```

```dart [Fast Blink]
// Rapid blinking for alerts
connectionTheme: ConnectionTheme(
  animationEffect: PulseEffect(
    speed: 4,  // Very fast
    minOpacity: 0.2,
    maxOpacity: 1.0,
    widthVariation: 1.0,
  ),
)
```

:::

## Applying Effects

### Theme-Level (All Connections)

Apply an effect to all connections via the theme:

```dart
final theme = NodeFlowTheme(
  connectionTheme: ConnectionTheme(
    style: ConnectionStyles.smoothstep,
    color: Colors.grey,
    strokeWidth: 2.0,
    // Default animation effect for ALL connections
    animationEffect: ParticleEffect(
      particleCount: 3,
      speed: 1,
      connectionOpacity: 0.3,
    ),
  ),
  // Control animation cycle duration
  connectionAnimationDuration: const Duration(seconds: 2),
);

controller.setTheme(theme);
```

::: info
**Animation Duration**: The `connectionAnimationDuration` controls how long
  one complete cycle takes. Effects with `speed: 1` will complete one cycle in
  this duration.

:::

### Per-Connection (Selective)

Override the theme's default effect on individual connections:

```dart
// Standard connection with theme default
controller.addConnection(Connection(
  id: 'conn-normal',
  sourceNodeId: 'node-1',
  sourcePortId: 'out',
  targetNodeId: 'node-2',
  targetPortId: 'in',
  // Uses theme's default effect
));

// Critical connection with custom pulse
controller.addConnection(Connection(
  id: 'conn-critical',
  sourceNodeId: 'node-2',
  sourcePortId: 'out',
  targetNodeId: 'node-3',
  targetPortId: 'in',
  // Override with pulse effect
  animationEffect: PulseEffect(
    speed: 2,
    minOpacity: 0.5,
    maxOpacity: 1.0,
    widthVariation: 1.5,
  ),
));

// Static connection (no animation)
controller.addConnection(Connection(
  id: 'conn-static',
  sourceNodeId: 'node-3',
  sourcePortId: 'out',
  targetNodeId: 'node-4',
  targetPortId: 'in',
  animationEffect: null, // Explicitly disable
));
```

## Controlling Animation Speed

The animation duration is set at the theme level and affects all effects:

::: code-group

```dart [Normal Speed]
final theme = NodeFlowTheme(
  connectionAnimationDuration: const Duration(seconds: 2),
  connectionTheme: ConnectionTheme(
    animationEffect: ParticleEffect(
      speed: 1, // 1 cycle per 2 seconds
    ),
  ),
);
```

```dart [Slow]
final theme = NodeFlowTheme(
  connectionAnimationDuration: const Duration(seconds: 4),
  connectionTheme: ConnectionTheme(
    animationEffect: FlowingDashEffect(
      speed: 1,  // 1 cycle per 4 seconds = slow
    ),
  ),
);
```

```dart [Fast]
final theme = NodeFlowTheme(
  connectionAnimationDuration: const Duration(milliseconds: 1000),
  connectionTheme: ConnectionTheme(
    animationEffect: GradientFlowEffect(
      speed: 1,  // 1 cycle per 1 second = fast
    ),
  ),
);
```

```dart [Variable Speed]
// Duration set at 2 seconds
final theme = NodeFlowTheme(
  connectionAnimationDuration: const Duration(seconds: 2),
  connectionTheme: ConnectionTheme(
    animationEffect: ParticleEffect(
      speed: 2, // 2 cycles per 2 seconds = 1 cycle/second
    ),
  ),
);

// Override on specific connection
Connection(
  id: 'fast-conn',
  animationEffect: ParticleEffect(
    speed: 4, // 4 cycles per 2 seconds = 2 cycles/second
  ),
)
```

:::

::: info
Connection effects render at high frequency and can impact performance when overused.
Use them selectively to highlight important connections rather than animating everything.
Too many animated connections will degrade performance and slow down the user experience.

:::

## What's Next?

Explore related topics:

- [Connection Labels](/docs/advanced/connection-labels) - Add text
  labels to connections
- [Theming](/docs/theming/overview) - Customize the overall appearance
- [Connections](/docs/core-concepts/connections) - Learn more about
  connections

::: tip
**Experiment!** Try mixing different effects to find what works best for your
  use case. The effects are designed to work together beautifully.

:::
