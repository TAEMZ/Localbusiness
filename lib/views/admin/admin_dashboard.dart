import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:localbusiness/views/admin/admin_services.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdminService.isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.data!) {
          return Center(
            child: Text(
              'Admin access required',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          );
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Admin Dashboard'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await AdminService.logout();
                    Navigator.pushReplacementNamed(context, '/welcome_page');
                  },
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.business)),
                  Tab(icon: Icon(Icons.reviews)),
                  Tab(icon: Icon(Icons.people)),
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No flagged businesses'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _AdminListItem(
              title: data['name'] ?? 'Unnamed Business',
              subtitle: 'Flags: ${data['flags']} • '
                  '${DateFormat.yMd().add_Hms().format((data['flaggedAt'] as Timestamp?)?.toDate() ?? DateTime.now())}',
              onAction: () => _showBusinessActions(context, doc),
            );
          },
        );
      },
    );
  }

  void _showBusinessActions(BuildContext context, DocumentSnapshot doc) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.blue),
              title: const Text('Clear Flags'),
              onTap: () async {
                await doc.reference.update({'flags': 0});
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Business'),
              onTap: () async {
                await AdminService.deleteBusiness(doc.id);
                Navigator.pop(context);
              },
            ),
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
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint("Error loading flagged reviews: ${snapshot.error}");
          return const Center(child: Text('Error loading flagged reviews'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('No flagged reviews found.'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _AdminListItem(
              title: data['comment'] ?? 'No comment',
              subtitle: 'Flags: ${data['flags'] ?? 0} • '
                  '${DateFormat.yMd().add_Hms().format((data['flaggedAt'] as Timestamp?)?.toDate() ?? DateTime.now())}',
              onAction: () => _showReviewActions(context, doc),
            );
          },
        );
      },
    );
  }
}

void _showReviewActions(BuildContext context, DocumentSnapshot doc) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Colors.blue),
            title: const Text('Clear Flags'),
            onTap: () {
              doc.reference.update({'flags': 0});
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Review'),
            onTap: () async {
              final userId = doc.reference.parent.parent?.id;
              if (userId != null) {
                await AdminService.deleteReview(doc.id, userId);
              }
              Navigator.pop(context);
            },
          ),
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No flagged users'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _AdminListItem(
              title: data['email'] ?? 'No email',
              subtitle: 'Flags: ${data['totalFlagsReceived']} • '
                  'Status: ${data['status'] ?? 'active'}',
              onAction: () => _showUserActions(context, doc),
            );
          },
        );
      },
    );
  }

  void _showUserActions(BuildContext context, DocumentSnapshot doc) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lock_reset, color: Colors.orange),
              title: const Text('Reset Flags'),
              onTap: () async {
                await doc.reference.update({'totalFlagsReceived': 0});
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block User'),
              onTap: () async {
                await doc.reference.update({'status': 'banned'});
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.undo, color: Colors.green),
              title: const Text('Unblock User'),
              onTap: () async {
                await doc.reference.update({'status': 'active'});
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete User'),
              onTap: () async {
                await AdminService.deleteUser(doc.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onAction;

  const _AdminListItem({
    required this.title,
    required this.subtitle,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: onAction,
        ),
      ),
    );
  }
}
