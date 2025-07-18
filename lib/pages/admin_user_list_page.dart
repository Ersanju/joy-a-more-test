import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_chat_page.dart';

class AdminUserListPage extends StatelessWidget {
  const AdminUserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseFirestore.instance.collection('users');

    return Scaffold(
      appBar: AppBar(title: const Text("User Chats")),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userId = userDoc.id;
              final data = userDoc.data() as Map<String, dynamic>;

              // Priority: name > email > phone > userId
              final userName = (data['name']?.toString().trim().isNotEmpty == true)
                  ? data['name']
                  : (data['email']?.toString().trim().isNotEmpty == true)
                  ? data['email']
                  : (data['phone']?.toString().trim().isNotEmpty == true)
                  ? data['phone']
                  : userId;

              return ListTile(
                title: Text(userName),
                subtitle: Text("User ID: $userId"),
                trailing: const Icon(Icons.chat),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminChatPage(userId: userId),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
