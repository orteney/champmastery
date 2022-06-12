import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:champmastery/di/di.dart';
import 'package:champmastery/presentation/champions_disenchanter/champions_disenchanter_widget.dart';
import 'package:champmastery/presentation/champions_table/champions_table_widget.dart';
import 'package:champmastery/presentation/core/widgets/app_version.dart';
import 'package:champmastery/presentation/core/widgets/unknown_bloc_state.dart';
import 'package:champmastery/presentation/summoner/summoner_widget.dart';

import 'bloc/home_bloc.dart';
import 'screens/message_with_retry.dart';
import 'screens/message_wth_loading.dart';
import 'screens/pick_lol_path.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        getIt(),
        getIt(),
        getIt(),
        getIt(),
        getIt(),
      )..add(StartHomeEvent()),
      child: Scaffold(
        body: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state is InitialHomeState) {
              return const MessageWithLoading(message: 'Соединяюсь с League of Legends... 🤔');
            }

            if (state is LolPathUnspecifiedHomeState) {
              return PickLolPathScreen(
                customMessage: state.message,
                onRetryTap: () => context.read<HomeBloc>().add(StartHomeEvent()),
                onPickedPath: (path) => context.read<HomeBloc>().add(PickLolPathHomeEvent(pickedPath: path)),
              );
            }

            if (state is LolNotLaunchedOrWrongPathProvidedHomeState) {
              return MessageWithRetryScreen(
                message: 'Похоже лига не запущена, нажми "повторить", когда запустится 🙃',
                onTapRetry: () => context.read<HomeBloc>().add(StartHomeEvent()),
              );
            }

            if (state is ErrorHomeState) {
              return MessageWithRetryScreen(
                message: state.message,
                onTapRetry: () => context.read<HomeBloc>().add(StartHomeEvent()),
              );
            }

            if (state is LoadingSummonerInfoHomeState) {
              return const MessageWithLoading(message: 'Загружаю информацию о призывателе');
            }

            if (state is LoadedHomeState) {
              Widget body;

              switch (state.destination) {
                case Destination.mastery:
                  body = ChampionsTableWidget(summonerId: state.summonerId);
                  break;
                case Destination.disenchanter:
                  body = const ChampionsDisenchanterWidget();
                  break;
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NavigationDrawer(currentDestination: state.destination),
                  Expanded(child: body),
                ],
              );
            }

            return UnknownBlocState(blocState: state);
          },
        ),
      ),
    );
  }
}

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({
    super.key,
    required this.currentDestination,
  });

  final Destination currentDestination;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF151515),
      child: SizedBox(
        width: 216,
        child: Column(
          children: [
            const Card(
              elevation: 0,
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SummonerWidget(),
              ),
            ),
            Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Column(
                children: [
                  NavigationMenuItem(
                    destination: Destination.mastery,
                    isChecked: currentDestination == Destination.mastery,
                  ),
                  NavigationMenuItem(
                    destination: Destination.disenchanter,
                    isChecked: currentDestination == Destination.disenchanter,
                  ),
                ],
              ),
            ),
            const Spacer(),
            const SizedBox(height: 16),
            const AppVersion(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class NavigationMenuItem extends StatelessWidget {
  const NavigationMenuItem({
    super.key,
    required this.destination,
    required this.isChecked,
  });

  final Destination destination;
  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    String name;

    switch (destination) {
      case Destination.mastery:
        name = 'МАСТЕРСТВО';
        break;
      case Destination.disenchanter:
        name = 'РАСПЫЛИТЕЛЬ';
        break;
    }

    return ListTile(
      title: Text(name),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      style: ListTileStyle.drawer,
      selected: isChecked,
      onTap: () => context.read<HomeBloc>().add(TapDestinationHomeEvent(destination)),
    );
  }
}
