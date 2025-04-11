import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:localbusiness/views/admin/admin_services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdminService.isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SpinKitWave(
                    color: Color.fromARGB(255, 133, 128,
                        128), // Or use Theme.of(context).colorScheme.primary
                    size: 50.0,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Verifying Admin Access',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.data!) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 80,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Admin Access Required',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.red[400],
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You need administrator privileges to access this page',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/welcome_page');
                    },
                    child: const Text('RETURN TO HOME'),
                  ),
                ],
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: const Text('Admin Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: true,
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[800]!, Colors.blue[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: () async {
                    final confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Logout'),
                        content: const Text(
                            'Are you sure you want to logout from admin panel?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await AdminService.logout();
                      Navigator.pushReplacementNamed(context, '/welcome_page');
                    }
                  },
                ),
              ],
              bottom: TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 4,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.business_rounded),
                    text: 'Businesses',
                  ),
                  Tab(
                    icon: const Icon(Icons.reviews_rounded),
                    text: 'Reviews',
                  ),
                  Tab(
                    icon: const Icon(Icons.people_alt_rounded),
                    text: 'Users',
                  ),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                _FlaggedBusinesses(),
                _FlaggedReviews(),
                _FlaggedUsers(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FlaggedBusinesses extends StatelessWidget {
  const _FlaggedBusinesses();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: AdminService.getFlaggedBusinesses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SpinKitWave(
              color: Color.fromARGB(255, 133, 128,
                  128), // Or use Theme.of(context).colorScheme.primary
              size: 50.0,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 20),
                Text(
                  'Error loading businesses',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 60,
                  color: Colors.green[400],
                ),
                const SizedBox(height: 20),
                Text(
                  'No flagged businesses',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  'All businesses are currently clean',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Force refresh the stream
            await FirebaseFirestore.instance.disableNetwork();
            await FirebaseFirestore.instance.enableNetwork();
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final flagCount = data['flags'] ?? 0;
              final flaggedAt = (data['flaggedAt'] as Timestamp?)?.toDate();

              return _AdminListItem(
                title: data['name'] ?? 'Unnamed Business',
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.flag,
                          size: 16,
                          color: Colors.red[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$flagCount ${flagCount == 1 ? 'flag' : 'flags'}',
                          style: TextStyle(color: Colors.red[400]),
                        ),
                      ],
                    ),
                    if (flaggedAt != null)
                      Text(
                        'Flagged on ${DateFormat('MMM d, y • h:mm a').format(flaggedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                  ],
                ),
                onAction: () => _showBusinessActions(context, doc),
                color: Colors.blue[50],
              );
            },
          ),
        );
      },
    );
  }

  void _showBusinessActions(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final businessName = data['name'] ?? 'this business';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Manage Business',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.blue),
              title: const Text('Clear Flags'),
              subtitle: const Text('Reset the flag count to zero'),
              onTap: () async {
                Navigator.pop(context);
                final success = await _showConfirmationDialog(
                  context,
                  title: 'Clear Flags?',
                  content:
                      'Are you sure you want to clear all flags for $businessName?',
                );
                if (success) {
                  await doc.reference.update({'flags': 0});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Flags cleared for $businessName'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Business'),
              subtitle: const Text('Permanently remove this business'),
              onTap: () async {
                Navigator.pop(context);
                final success = await _showConfirmationDialog(
                  context,
                  title: 'Delete Business?',
                  content:
                      'Are you sure you want to permanently delete $businessName? This action cannot be undone.',
                  isDestructive: true,
                );
                if (success) {
                  try {
                    await AdminService.deleteBusiness(doc.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$businessName deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _FlaggedReviews extends StatelessWidget {
  const _FlaggedReviews();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: AdminService.getFlaggedReviews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: SpinKitWave(
            color: Color.fromARGB(255, 133, 128,
                128), // Or use Theme.of(context).colorScheme.primary
            size: 50.0,
          ));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 20),
                Text(
                  'Error loading reviews',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 60,
                  color: Colors.green[400],
                ),
                const SizedBox(height: 20),
                Text(
                  'No flagged reviews',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  'All reviews are currently clean',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await FirebaseFirestore.instance.disableNetwork();
            await FirebaseFirestore.instance.enableNetwork();
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final flagCount = data['flags'] ?? 0;
              final flaggedAt = (data['flaggedAt'] as Timestamp?)?.toDate();
              final comment = data['comment'] ?? 'No comment';
              final rating = data['rating'] ?? 0;

              return _AdminListItem(
                title: comment.length > 50
                    ? '${comment.substring(0, 50)}...'
                    : comment,
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.flag,
                          size: 16,
                          color: Colors.red[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$flagCount ${flagCount == 1 ? 'flag' : 'flags'}',
                          style: TextStyle(color: Colors.red[400]),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text('$rating'),
                          ],
                        ),
                      ],
                    ),
                    if (flaggedAt != null)
                      Text(
                        'Flagged on ${DateFormat('MMM d, y • h:mm a').format(flaggedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                  ],
                ),
                onAction: () => _showReviewActions(context, doc),
                color: Colors.orange[50],
              );
            },
          ),
        );
      },
    );
  }
}

void _showReviewActions(BuildContext context, DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final commentPreview = (data['comment'] as String? ?? 'No comment')
      .substring(0, (data['comment']?.length ?? 0) > 30 ? 30 : null);

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Manage Review',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Colors.blue),
            title: const Text('Clear Flags'),
            subtitle: const Text('Reset the flag count to zero'),
            onTap: () async {
              Navigator.pop(context);
              final success = await _showConfirmationDialog(
                context,
                title: 'Clear Flags?',
                content:
                    'Are you sure you want to clear all flags for review "$commentPreview..."?',
              );
              if (success) {
                await doc.reference.update({'flags': 0});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Review flags cleared'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Review'),
            subtitle: const Text('Permanently remove this review'),
            onTap: () async {
              Navigator.pop(context);
              final success = await _showConfirmationDialog(
                context,
                title: 'Delete Review?',
                content:
                    'Are you sure you want to permanently delete this review? This action cannot be undone.',
                isDestructive: true,
              );
              if (success) {
                try {
                  final userId = doc.reference.parent.parent?.id;
                  if (userId != null) {
                    await AdminService.deleteReview(doc.id, userId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Review deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _FlaggedUsers extends StatelessWidget {
  const _FlaggedUsers();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: AdminService.getFlaggedUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: SpinKitWave(
            color: Color.fromARGB(255, 133, 128,
                128), // Or use Theme.of(context).colorScheme.primary
            size: 50.0,
          ));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 20),
                Text(
                  'Error loading users',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 60,
                  color: Colors.green[400],
                ),
                const SizedBox(height: 20),
                Text(
                  'No flagged users',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  'All users are currently clean',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await FirebaseFirestore.instance.disableNetwork();
            await FirebaseFirestore.instance.enableNetwork();
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final flagCount = data['totalFlagsReceived'] ?? 0;
              final status = data['status'] ?? 'active';
              final isBanned = status == 'banned';

              return _AdminListItem(
                title: data['email'] ?? 'No email',
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.flag,
                          size: 16,
                          color: Colors.red[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$flagCount ${flagCount == 1 ? 'flag' : 'flags'}',
                          style: TextStyle(color: Colors.red[400]),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                isBanned ? Colors.red[100] : Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isBanned ? 'BANNED' : 'ACTIVE',
                            style: TextStyle(
                              color: isBanned ? Colors.red : Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Joined ${DateFormat('MMM d, y').format((data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now())}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
                onAction: () => _showUserActions(context, doc),
                color: Colors.purple[50],
              );
            },
          ),
        );
      },
    );
  }
}

void _showUserActions(BuildContext context, DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final email = data['email'] ?? 'this user';
  final isBanned = (data['status'] ?? 'active') == 'banned';

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Manage User',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_reset, color: Colors.orange),
            title: const Text('Reset Flags'),
            subtitle: const Text('Set flag count back to zero'),
            onTap: () async {
              Navigator.pop(context);
              final success = await _showConfirmationDialog(
                context,
                title: 'Reset Flags?',
                content: 'Are you sure you want to reset flags for $email?',
              );
              if (success) {
                await doc.reference.update({'totalFlagsReceived': 0});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Flags reset for $email'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
          ),
          const Divider(height: 1),
          if (!isBanned)
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Ban User'),
              subtitle: const Text('Prevent this user from accessing the app'),
              onTap: () async {
                Navigator.pop(context);
                final success = await _showConfirmationDialog(
                  context,
                  title: 'Ban User?',
                  content:
                      'Are you sure you want to ban $email? They will no longer be able to access the app.',
                  isDestructive: true,
                );
                if (success) {
                  await doc.reference.update({'status': 'banned'});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$email has been banned'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
          if (isBanned)
            ListTile(
              leading: const Icon(Icons.undo, color: Colors.green),
              title: const Text('Unban User'),
              subtitle: const Text('Restore access to this user'),
              onTap: () async {
                Navigator.pop(context);
                final success = await _showConfirmationDialog(
                  context,
                  title: 'Unban User?',
                  content:
                      'Are you sure you want to restore access for $email?',
                );
                if (success) {
                  await doc.reference.update({'status': 'active'});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$email has been unbanned'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete User'),
            subtitle: const Text('Permanently remove this user account'),
            onTap: () async {
              Navigator.pop(context);
              final success = await _showConfirmationDialog(
                context,
                title: 'Delete User?',
                content:
                    'Are you sure you want to permanently delete $email? This action cannot be undone.',
                isDestructive: true,
              );
              if (success) {
                try {
                  await AdminService.deleteUser(doc.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$email deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _AdminListItem extends StatelessWidget {
  final String title;
  final Widget subtitle;
  final VoidCallback onAction;
  final Color? color;

  const _AdminListItem({
    required this.title,
    required this.subtitle,
    required this.onAction,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onAction,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    subtitle,
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: onAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> _showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String content,
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'Confirm',
            style: TextStyle(
              color: isDestructive ? Colors.red : null,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
