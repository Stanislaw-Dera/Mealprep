import 'package:flutter/material.dart';

import '../../data/sync.dart';

/// Sekcja „Synchronizacja" w Ustawieniach: logowanie, stan, „Synchronizuj teraz".
///
/// [sync] jest `null`, gdy aplikację zbudowano bez `supabase.json`.
class SyncSection extends StatefulWidget {
  const SyncSection({super.key, required this.sync});

  final SyncController? sync;

  @override
  State<SyncSection> createState() => _SyncSectionState();
}

class _SyncSectionState extends State<SyncSection> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signingIn = false;
  String? _loginError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final sync = widget.sync!;
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _loginError = 'Podaj e-mail i hasło.');
      return;
    }
    setState(() {
      _signingIn = true;
      _loginError = null;
    });
    final error = await sync.signIn(_email.text, _password.text);
    if (!mounted) return;
    setState(() {
      _signingIn = false;
      _loginError = error;
    });
    if (error == null) _password.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sync = widget.sync;
    if (sync == null) {
      return Text(
        'Synchronizacja wyłączona: aplikację zbudowano bez supabase.json. '
        'Dane są tylko na tym urządzeniu.',
        style: theme.textTheme.bodySmall,
      );
    }
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) =>
          sync.signedIn ? _signedIn(theme, sync) : _signInForm(theme),
    );
  }

  Widget _signInForm(ThemeData theme) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zaloguj się, żeby plan, ustawienia i listę zakupów mieć na '
            'wszystkich urządzeniach. Bez logowania wszystko działa lokalnie.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              children: [
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  decoration: const InputDecoration(
                    labelText: 'Hasło',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _signIn(),
                ),
              ],
            ),
          ),
          if (_loginError != null) ...[
            const SizedBox(height: 8),
            Text(
              _loginError!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _signingIn ? null : _signIn,
            icon: const Icon(Icons.login),
            label: const Text('Zaloguj'),
          ),
        ],
      ),
    );
  }

  Widget _signedIn(ThemeData theme, SyncController sync) {
    final String state;
    if (sync.busy) {
      state = 'Synchronizuję…';
    } else if (sync.lastSync == null) {
      state = 'Jeszcze nie zsynchronizowano.';
    } else {
      state =
          'Ostatnia synchronizacja: ${_when(sync.lastSync!)}.'
          '${sync.pending > 0 ? ' Niewysłane zmiany: ${sync.pending}.' : ''}';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Zalogowano jako ${sync.email}'),
        const SizedBox(height: 4),
        Text(state, style: theme.textTheme.bodySmall),
        if (sync.error != null) ...[
          const SizedBox(height: 8),
          Text(sync.error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: sync.busy ? null : sync.syncNow,
              icon: const Icon(Icons.sync),
              label: const Text('Synchronizuj teraz'),
            ),
            TextButton.icon(
              onPressed: sync.signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Wyloguj'),
            ),
          ],
        ),
      ],
    );
  }
}

/// „dziś 14:05", „wczoraj 09:30" albo „8.11 21:00".
String _when(DateTime t) {
  final now = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  final time = '${t.hour}:${two(t.minute)}';
  final day = DateTime(t.year, t.month, t.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'dziś $time';
  if (diff == 1) return 'wczoraj $time';
  return '${t.day}.${t.month} $time';
}
