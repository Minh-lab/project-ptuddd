import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_cubit.dart';

/// Nút đăng xuất đặt trên AppBar; hỏi xác nhận trước khi đăng xuất.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _confirmAndSignOut(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<AuthCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Đăng xuất?'),
          content: const Text(
            'Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng SmartNote.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }
    await cubit.signOut();
    messenger.showSnackBar(const SnackBar(content: Text('Đã đăng xuất.')));
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Đăng xuất',
      icon: const Icon(Icons.logout),
      onPressed: () => _confirmAndSignOut(context),
    );
  }
}
