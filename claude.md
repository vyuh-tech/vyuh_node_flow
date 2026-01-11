## What is this?

This is a node-based flow editor for Flutter applications, inspired by React
Flow and designed for building visual programming interfaces, workflow editors,
and interactive diagrams.

## Tech

- Flutter
- Dart

# State Management

- Uses MobX for state management
- Only raw observables, no annotations

# Always Note

- The Web Server or App is always running in the background
- We are using Melos workspace so use its commands to bootstrap and update
  projects
- Do not use the buildXXX methods for building Flutter UI trees; instead, create
  semantic widgets for better composability and readability.
- Use semantic naming conventions for variables, functions, and classes to
  improve code readability and maintainability.
- After any code change, run `melos analyze` to check for code quality and
  linting issues
- Keep the documentation up to date whenever you add a new feature.
- Ensure that all code changes are thoroughly tested before merging into the
  main branch.
