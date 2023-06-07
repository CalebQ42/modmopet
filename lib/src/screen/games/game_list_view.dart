import 'package:easy_localization/easy_localization.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:modmopet/src/entity/emulator.dart';
import 'package:modmopet/src/entity/game.dart';
import 'package:modmopet/src/entity/game_meta.dart';
import 'package:modmopet/src/provider/emulator_provider.dart';
import 'package:modmopet/src/provider/game_list_provider.dart';
import 'package:modmopet/src/screen/emulator_picker/emulator_picker_view.dart';
import 'package:modmopet/src/screen/games/games_emulator_view.dart';
import 'package:modmopet/src/screen/mods/mods_view.dart';
import 'package:modmopet/src/themes/color_schemes.g.dart';
import 'package:modmopet/src/widgets/mm_breadcrumbs_bar.dart';
import 'package:modmopet/src/widgets/mm_evelated_button.dart';
import 'package:modmopet/src/widgets/mm_loading_indicator.dart';

/// Displays a list of the games installed at the emulator
class GameListView extends HookConsumerWidget {
  static const routeName = '/game_list';
  const GameListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emulator = ref.watch(emulatorProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const MMBreadcrumbsBar('Games - Overview'),
        const SizedBox(
          height: 140.0,
          width: double.maxFinite,
          child: GamesEmulatorView(),
        ),
        Container(
          height: 45,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(
                width: 1,
                color: MMColors.instance.backgroundBorder,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [createActionMenu(context, ref)],
          ),
        ),
        Expanded(
          child: emulator.when(
            data: (emulator) {
              if (emulator != null) {
                return buildGameListView(emulator, context, ref);
              }

              return emulatorNotFoundView(context, ref);
            },
            error: (error, _) => Text(error.toString()),
            loading: () => MMLoadingIndicator(),
          ),
        ),
      ],
    );
  }

  Widget buildGameListView(
      Emulator emulator, BuildContext context, WidgetRef ref) {
    final games = ref.watch(gameListProvider);
    return games.when(
      loading: () => MMLoadingIndicator(),
      error: (err, stack) => Text(err.toString()),
      data: (games) {
        if (games.isNotEmpty == true) {
          return ListView.builder(
            restorationId: 'modListView',
            itemCount: games.length,
            itemBuilder: (BuildContext context, int index) {
              final Game game = games[index];
              return Material(
                type: MaterialType.transparency,
                child: ListTile(
                  title: Text(game.title),
                  minVerticalPadding: 15.0,
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FastCachedImage(
                        url: game.iconUrl,
                        cacheHeight: 50,
                        cacheWidth: 50,
                      ),
                    ],
                  ),
                  subtitle: Text('by ${game.publisher}',
                      style: Theme.of(context).textTheme.bodySmall),
                  trailing: Container(
                    width: 175.0,
                    padding: const EdgeInsets.only(left: 10.0),
                    decoration: emulator.hasMetadataSupport == true
                        ? BoxDecoration(
                            border: Border(
                                left: BorderSide(
                                    width: 1,
                                    color: MMColors.instance.backgroundBorder)),
                          )
                        : null,
                    child: emulator.hasMetadataSupport && game.meta != null
                        ? buildGameMetadataInfo(
                            game.meta!,
                            Theme.of(context).textTheme,
                          )
                        : Container(),
                  ),
                  onTap: () {
                    ref.watch(gameProvider.notifier).state = game;
                    Navigator.restorablePushNamed(
                      context,
                      ModsView.routeName,
                    );
                  },
                ),
              );
            },
          );
        }

        return buildNoGamesFoundView(context, ref);
      },
    );
  }

  Widget emulatorNotFoundView(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 600.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 86.0,
            color: MMColors.instance.primary,
          ),
          Text(
            'emulator_not_found_title'.tr(),
            style: textTheme.bodyLarge?.copyWith(
              color: MMColors.instance.bodyText,
              fontSize: 21.0,
            ),
          ),
          Text(
            'emulator_not_found_text'.tr(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 20.0,
          ),
          MMElevatedButton.primary(
            onPressed: () {
              ref.read(selectedEmulatorIdProvider.notifier).state = null;
              Navigator.pushReplacementNamed(
                context,
                EmulatorPickerView.routeName,
              );
            },
            child: Text('emulator_not_found_button'.tr()),
          ),
        ],
      ),
    );
  }

  Widget buildNoGamesFoundView(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 600.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 86.0,
            color: MMColors.instance.primary,
          ),
          Text(
            'no_games_found_title'.tr(),
            style: textTheme.bodyLarge?.copyWith(
              color: MMColors.instance.bodyText,
              fontSize: 21.0,
            ),
          ),
          Text(
            'no_games_found_text'.tr(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 20.0,
          ),
          MMElevatedButton.primary(
            onPressed: () => ref.invalidate(gameListProvider),
            child: Text('no_games_found_button'.tr()),
          ),
        ],
      ),
    );
  }

  Widget buildGameMetadataInfo(GameMeta meta, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 25.0,
          padding: const EdgeInsets.only(right: 6.0),
          child: const Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                Icons.timer,
                size: 16.0,
              ),
              Icon(
                Icons.calendar_month_sharp,
                size: 16.0,
              )
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  formatDurationToPlayTime(Duration(minutes: meta.playTime),
                      extended: true),
                  style: textTheme.bodySmall
                      ?.copyWith(color: MMColors.instance.secondary)),
              Text(formatDateTimeToReadable(meta.lastPlayed!),
                  style: textTheme.bodySmall
                      ?.copyWith(color: MMColors.instance.secondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget createActionMenu(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Reload',
          onPressed: () => ref.invalidate(gameListProvider),
          color: MMColors.instance.primary,
          icon: const Icon(
            Icons.refresh_outlined,
            size: 24.0,
          ),
        ),
      ],
    );
  }

  String formatDurationToPlayTime(Duration duration, {bool extended = false}) {
    final hh = (duration.inHours).toString();
    final mm = (duration.inMinutes % 60).toString();
    String hours = 'h';
    String minutes = 'm';

    if (extended) {
      hours = ' ${plural('hour', duration.inHours)}';
      minutes = ' ${plural('minute', duration.inMinutes % 60)}';
    }

    return '$hh$hours $mm$minutes';
  }

  String formatDateTimeToReadable(DateTime dateTime) {
    return DateFormat.yMMMd().format(dateTime);
  }
}
