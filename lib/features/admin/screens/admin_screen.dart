import 'package:flutter/material.dart';
import '../../../services/api/admin_service.dart';
import '../../../services/local/storage_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _users = [];
  int _totalUsers = 0;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _loadingStats = true;
  bool _loadingUsers = true;
  bool _loadingMore = false;
  String? _searchText;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await StorageService.loadAuthToken();
    if (token == null) return;
    await Future.wait([_fetchStats(token), _fetchUsers(token, reset: true)]);
  }

  Future<void> _fetchStats(String token) async {
    final s = await AdminService.getStats(token: token);
    if (mounted)
      setState(() {
        _stats = s;
        _loadingStats = false;
      });
  }

  Future<void> _fetchUsers(String token, {bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _loadingUsers = true;
      });
    } else {
      setState(() {
        _loadingMore = true;
      });
    }
    final result = await AdminService.getUsers(
      token: token,
      page: _currentPage,
      pageSize: _pageSize,
      search: _searchText,
    );
    if (mounted) {
      setState(() {
        if (reset) {
          _users = (result?['users'] as List?) ?? [];
        } else {
          _users.addAll((result?['users'] as List?) ?? []);
        }
        _totalUsers = result?['totalUsers'] ?? 0;
        _loadingUsers = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _search(String query) async {
    _searchText = query.isEmpty ? null : query;
    final token = await StorageService.loadAuthToken();
    if (token == null) return;
    await _fetchUsers(token, reset: true);
  }

  Future<void> _loadNextPage() async {
    if (_loadingMore) return;
    if (_users.length >= _totalUsers) return;
    _currentPage++;
    final token = await StorageService.loadAuthToken();
    if (token == null) return;
    await _fetchUsers(token);
  }

  Future<void> _confirmDelete(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text(
          'Are you sure you want to delete ${user['fullName'] ?? user['username']}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final token = await StorageService.loadAuthToken();
    if (token == null) return;
    final ok = await AdminService.deleteUser(
      token: token,
      userId: user['userId'],
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'User deleted' : 'Failed to delete user'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      if (ok) await _fetchUsers(token, reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FF),
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4A7DFF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // Stats section
            SliverToBoxAdapter(child: _buildStatsSection()),
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _search,
                  decoration: InputDecoration(
                    hintText: 'Search users by name, email…',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF4A7DFF),
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _search('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            // User count label
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  '$_totalUsers users total',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),
            ),
            // User list
            if (_loadingUsers)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_users.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('No users found')),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  if (i == _users.length) {
                    return _users.length < _totalUsers
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: _loadingMore
                                  ? const CircularProgressIndicator()
                                  : TextButton(
                                      onPressed: _loadNextPage,
                                      child: const Text('Load more'),
                                    ),
                            ),
                          )
                        : const SizedBox(height: 24);
                  }
                  return _buildUserTile(_users[i] as Map<String, dynamic>);
                }, childCount: _users.length + 1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_loadingStats) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_stats == null) return const SizedBox.shrink();

    final cards = [
      _StatCard(
        label: 'Total Users',
        value: '${_stats!['totalUsers'] ?? 0}',
        icon: Icons.people,
        color: const Color(0xFF4A7DFF),
      ),
      _StatCard(
        label: 'Active Today',
        value: '${_stats!['activeUsersToday'] ?? 0}',
        icon: Icons.today,
        color: const Color(0xFF34C759),
      ),
      _StatCard(
        label: 'Videos Watched',
        value: '${_stats!['totalVideosWatched'] ?? 0}',
        icon: Icons.play_circle_outline,
        color: const Color(0xFFFF9500),
      ),
      _StatCard(
        label: 'Resumes',
        value: '${_stats!['totalResumes'] ?? 0}',
        icon: Icons.description_outlined,
        color: const Color(0xFFAF52DE),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.7,
        children: cards,
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final name = user['fullName'] ?? user['username'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final career = user['selectedCareer'] as String?;
    final progress = (user['overallProgress'] as num?)?.toDouble() ?? 0.0;
    final hasResume = user['hasResume'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF4A7DFF).withOpacity(0.15),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Color(0xFF4A7DFF),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              email,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (career != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.route_outlined,
                    size: 12,
                    color: Color(0xFFB8A67A),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      career,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB8A67A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${progress.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4A7DFF),
                    ),
                  ),
                ],
              ),
            ],
            if (hasResume)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 11,
                      color: Color(0xFF34C759),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Has resume',
                      style: TextStyle(fontSize: 11, color: Color(0xFF34C759)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmDelete(user),
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
