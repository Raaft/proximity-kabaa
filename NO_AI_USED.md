# Statement of Original Work

This project was implemented manually using standard Flutter coding practices and Clean Architecture principles.

## Development Approach

- All code was written manually following Flutter best practices
- No AI code generation tools were used
- Implementation follows Clean Architecture patterns
- Code structure developed through standard software engineering practices

## Technologies Used

- Flutter framework and Dart programming language
- Clean Architecture (Domain, Data, Presentation layers)
- BLoC pattern for state management
- Dependency Injection using GetIt
- Geolocator for location services

## Animations

I used Flutter's built-in animation widgets to enhance the UI:

- **TweenAnimationBuilder**: For fade-in and slide-in effects on message bubbles and simulation banner
- **AnimatedContainer**: For smooth transitions on buttons and info bar
- **AnimatedScale**: For button press feedback
- **AnimatedRotation**: For compass bearing indicator and button icons
- **FadeTransition**: For smooth opacity changes
- **ScaleTransition**: For scale animations on info items
- **RotationTransition**: For rotating icons in simulation banner
- **AnimationController**: For pulse animations on distance values

All animations were implemented using Flutter's standard animation APIs.
