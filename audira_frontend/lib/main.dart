import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/cart_provider.dart';
import 'core/providers/audio_provider.dart';
import 'core/providers/library_provider.dart';
import 'core/providers/download_provider.dart';
import 'features/home/screens/main_layout.dart';

void main() {
  runApp(const AudiraApp());
}

class AudiraApp extends StatefulWidget {
  const AudiraApp({super.key});

  @override
  State<AudiraApp> createState() => _AudiraAppState();
}

class _AudiraAppState extends State<AudiraApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
      ],
      child: const _AppContent(),
    );
  }
}

class _AppContent extends StatefulWidget {
  const _AppContent();

  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  int? _lastUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAuthenticationChange();
  }

  void _checkAuthenticationChange() {
    final authProvider = Provider.of<AuthProvider>(context, listen: true);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);

    // Check if user just logged in or changed
    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      final currentUserId = authProvider.currentUser!.id;

      if (_lastUserId != currentUserId) {
        // User just logged in or changed, load cart, library, and downloads
        _lastUserId = currentUserId;
        // Schedule for after the current frame to avoid calling during build
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await cartProvider.loadCart(currentUserId);
          await libraryProvider.loadLibrary(currentUserId);
          await downloadProvider.initialize();
        });
      }
    } else if (_lastUserId != null) {
      // User just logged out, clear data
      final userId = _lastUserId!;
      _lastUserId = null;
      // Schedule for after the current frame to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await cartProvider.clearCart(userId);
        await libraryProvider.clearLibrary(userId: userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audira',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRoutes.generateRoute,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return const MainLayout();
        },
      ),
    );
  }
}
