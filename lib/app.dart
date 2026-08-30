import 'package:flutter/material.dart';
import 'package:meus_recibos/core/database/app_database.dart';
import 'package:meus_recibos/core/theme/app_theme.dart';
import 'package:meus_recibos/repositories/client_repository.dart';
import 'package:meus_recibos/repositories/profile_repository.dart';
import 'package:meus_recibos/screens/clients/client_controller.dart';
import 'package:meus_recibos/screens/home/home_screen.dart';
import 'package:meus_recibos/screens/profiles/profile_controller.dart';
import 'package:provider/provider.dart';

class MeusRecibosApp extends StatelessWidget {
  const MeusRecibosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              ProfileController(ProfileRepository(AppDatabase.instance))
                ..loadProfiles(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ClientController(ClientRepository(AppDatabase.instance))
                ..loadClients(),
        ),
      ],
      child: MaterialApp(
        title: 'Meus Recibos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    );
  }
}
