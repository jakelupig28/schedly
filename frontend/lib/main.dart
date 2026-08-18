import 'package:flutter/material';
import 'package:provider/provider';
import 'theme/app_theme.dart';
import 'providers/schedule_provider.dart';
import 'screens/onboarding_screen.dart';

void main() {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
      ],
      child: const SchedlyApp(),
    ),
  );
}

class SchedlyApp extends StatelessWidget {
  const SchedlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'Schedly 🎓',
          debugShowCheckedModeBanner: false,
          themeMode: provider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const OnboardingScreen(),
        );
      },
    );
  }
}
