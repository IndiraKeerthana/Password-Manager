import 'package:flutter/material.dart';
import '../services/encryption_service.dart';

class ChangeMasterKeyDialog extends StatefulWidget {
  const ChangeMasterKeyDialog({super.key});

  @override
  State<ChangeMasterKeyDialog> createState() => _ChangeMasterKeyDialogState();
}

class _ChangeMasterKeyDialogState extends State<ChangeMasterKeyDialog> {
  final _currentKeyController = TextEditingController();
  final _newKeyController = TextEditingController();
  final _confirmKeyController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _currentKeyController.dispose();
    _newKeyController.dispose();
    _confirmKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final currentKey = _currentKeyController.text;
    final newKey = _newKeyController.text;
    final confirmKey = _confirmKeyController.text;

    if (currentKey.isEmpty) {
      setState(() => _error = 'Please enter your current master key.');
      return;
    }

    if (newKey.length < 6) {
      setState(() => _error = 'New master key must be at least 6 characters.');
      return;
    }

    if (newKey != confirmKey) {
      setState(() => _error = 'New master key and confirmation do not match.');
      return;
    }

    if (currentKey == newKey) {
      setState(() => _error = 'New master key must be different from current master key.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await EncryptionService.changeMasterKey(
        currentMasterKey: currentKey,
        newMasterKey: newKey,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Master key changed successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        if (e is StateError) {
          _error = e.message;
        } else {
          _error = 'Failed to change master key: $e';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Master Key'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your current master key and a new master key. '
              'Your saved passwords will remain safe and accessible.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _currentKeyController,
              obscureText: _obscureCurrent,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Current Master Key',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureCurrent = !_obscureCurrent);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newKeyController,
              obscureText: _obscureNew,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'New Master Key',
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureNew = !_obscureNew);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmKeyController,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_submitting) _handleSubmit();
              },
              decoration: InputDecoration(
                labelText: 'Confirm New Master Key',
                prefixIcon: const Icon(Icons.key_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  },
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _handleSubmit,
          child: _submitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}
