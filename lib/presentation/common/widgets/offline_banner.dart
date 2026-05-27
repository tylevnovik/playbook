import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/connection_checker/connection_checker.dart';

class OfflineBanner extends StatelessWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return StreamBuilder<bool>(
      stream: ConnectionChecker.onConnectionChanged,
      initialData: true,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        return Column(
          children: [
            AnimatedCrossFade(
              firstChild: Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.error,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      loc.get('offlineWarning'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: isOnline
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
