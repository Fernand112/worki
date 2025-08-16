import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:worki/constants/app_constants.dart';
import 'package:worki/models/user_profile.dart';
import 'package:worki/models/job_model.dart';
import 'package:worki/screens/applicant_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserProfile? _userProfile;
  List<JobApplication> _myApplications = [];
  List<Job> _myJobs = [];
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Load user profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        _userProfile = UserProfile.fromFirestore(userDoc);
      }

      // Load user applications
      final applicationsQuery = await FirebaseFirestore.instance
          .collection('job_applications')
          .where('applicantId', isEqualTo: user.uid)
          .get();
      
      _myApplications = applicationsQuery.docs
          .map((doc) => JobApplication.fromFirestore(doc))
          .toList();
      
      // Sort applications by date (newest first)
      _myApplications.sort((a, b) {
        if (a.appliedAt == null && b.appliedAt == null) return 0;
        if (a.appliedAt == null) return 1;
        if (b.appliedAt == null) return -1;
        return b.appliedAt!.compareTo(a.appliedAt!);
      });

      // Load user's published jobs
      final jobsQuery = await FirebaseFirestore.instance
          .collection('jobs')
          .where('authorId', isEqualTo: user.uid)
          .get();
      
      _myJobs = jobsQuery.docs
          .map((doc) => Job.fromFirestore(doc))
          .toList();
      
      // Sort jobs by createdAt (newest first)
      _myJobs.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      // Load notifications
      final notificationsQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .limit(20)
          .get();
      
      _notifications = notificationsQuery.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      
      // Sort notifications by date (newest first)
      _notifications.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editProfile() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EditProfileDialog(userProfile: _userProfile),
    );

    if (result != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update(result);
          
          _loadUserData(); // Reload data
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error actualizando perfil: $e')),
          );
        }
      }
    }
  }

  Widget _buildProfileTab() {
    if (_userProfile == null) {
      return const Center(child: Text('Error cargando perfil'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Photo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade100,
            ),
            child: _userProfile!.profileImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      _userProfile!.profileImageUrl!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.person, size: 60, color: Colors.blue.shade600);
                      },
                    ),
                  )
                : Icon(Icons.person, size: 60, color: Colors.blue.shade600),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            _userProfile!.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _userProfile!.email,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          // Edit Profile Button
          ElevatedButton.icon(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit),
            label: const Text(AppConstants.editProfile),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Bio
          if (_userProfile!.bio != null && _userProfile!.bio!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppConstants.bio,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_userProfile!.bio!),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Skills
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppConstants.mySkills,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_userProfile!.skills.isEmpty)
                    const Text('No has agregado habilidades aún')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _userProfile!.skills.map((skill) {
                        return Chip(
                          label: Text(skill),
                          backgroundColor: Colors.blue.shade50,
                          labelStyle: TextStyle(color: Colors.blue.shade700),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsTab() {
    if (_myApplications.isEmpty) {
      return const Center(
        child: Text(
          AppConstants.noApplications,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myApplications.length,
      itemBuilder: (context, index) {
        final application = _myApplications[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('Trabajo ID: ${application.jobId}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Oferta: €${application.offerAmount.toStringAsFixed(2)}'),
                Text('Estado: ${_getStatusText(application.status)}'),
                if (application.appliedAt != null)
                  Text('Aplicado: ${_formatDate(application.appliedAt!)}'),
              ],
            ),
            trailing: _getStatusIcon(application.status),
          ),
        );
      },
    );
  }

  Widget _buildJobsTab() {
    if (_myJobs.isEmpty) {
      return const Center(
        child: Text(
          AppConstants.noJobsPublished,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myJobs.length,
      itemBuilder: (context, index) {
        final job = _myJobs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(job.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('Presupuesto: €${job.budget.toStringAsFixed(2)}'),
                if (job.createdAt != null)
                  Text('Publicado: ${_formatDate(job.createdAt!)}'),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _viewJobApplications(job),
              child: const Text(AppConstants.viewApplications),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsTab() {
    if (_notifications.isEmpty) {
      return const Center(
        child: Text(
          AppConstants.noNotifications,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: notification.isRead ? null : Colors.blue.shade50,
          child: ListTile(
            leading: Icon(
              notification.isRead ? Icons.mail_outline : Icons.mail,
              color: notification.isRead ? Colors.grey : Colors.blue,
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.body),
                if (notification.createdAt != null)
                  Text(
                    _formatDate(notification.createdAt!),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            onTap: () => _markNotificationAsRead(notification),
          ),
        );
      },
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return AppConstants.pending;
      case 'accepted':
        return AppConstants.accepted;
      case 'rejected':
        return AppConstants.rejected;
      default:
        return status;
    }
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      case 'accepted':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'rejected':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.help, color: Colors.grey);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _viewJobApplications(Job job) async {
    try {
      final applicationsQuery = await FirebaseFirestore.instance
          .collection('job_applications')
          .where('jobId', isEqualTo: job.id)
          .get();
      
      final applications = applicationsQuery.docs
          .map((doc) => JobApplication.fromFirestore(doc))
          .toList();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _JobApplicationsDialog(
            job: job,
            applications: applications,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando postulaciones: $e')),
      );
    }
  }

  Future<void> _markNotificationAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.id)
          .update({'isRead': true});
      
      _loadUserData(); // Reload notifications
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.profile),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Perfil'),
            Tab(icon: Icon(Icons.work), text: 'Postulaciones'),
            Tab(icon: Icon(Icons.business_center), text: 'Mis Trabajos'),
            Tab(icon: Icon(Icons.notifications), text: 'Notificaciones'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildApplicationsTab(),
                _buildJobsTab(),
                _buildNotificationsTab(),
              ],
            ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final UserProfile? userProfile;

  const _EditProfileDialog({this.userProfile});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _bioController;
  late TextEditingController _skillController;
  List<String> _skills = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile?.name ?? '');
    _lastNameController = TextEditingController(text: widget.userProfile?.lastName ?? '');
    _bioController = TextEditingController(text: widget.userProfile?.bio ?? '');
    _skillController = TextEditingController();
    _skills = List.from(widget.userProfile?.skills ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppConstants.editProfile),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: AppConstants.name,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa tu nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: AppConstants.lastName,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa tu apellido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: AppConstants.bio,
                  hintText: AppConstants.bioHint,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skillController,
                      decoration: const InputDecoration(
                        labelText: AppConstants.addSkill,
                        hintText: AppConstants.skillHint,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addSkill,
                    child: const Text('Agregar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_skills.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: _skills.map((skill) {
                    return Chip(
                      label: Text(skill),
                      onDeleted: () => _removeSkill(skill),
                      backgroundColor: Colors.blue.shade50,
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppConstants.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
                'lastName': _lastNameController.text.trim(),
                'bio': _bioController.text.trim(),
                'skills': _skills,
              });
            }
          },
          child: const Text(AppConstants.save),
        ),
      ],
    );
  }
}

class _JobApplicationsDialog extends StatelessWidget {
  final Job job;
  final List<JobApplication> applications;

  const _JobApplicationsDialog({
    required this.job,
    required this.applications,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Postulaciones para: ${job.title}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: applications.isEmpty
            ? const Center(child: Text('No hay postulaciones aún'))
            : ListView.builder(
                itemCount: applications.length,
                itemBuilder: (context, index) {
                  final app = applications[index];
                  return Card(
                    child: ListTile(
                      title: Text(app.applicantName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Oferta: \$${app.offerAmount.toStringAsFixed(0)}'),
                          Text('Carta: ${app.coverLetter}'),
                          Text('Estado: ${app.status}'),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ApplicantProfileScreen(
                                application: app,
                                job: job,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Ver Perfil'),
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppConstants.close),
        ),
      ],
    );
  }
}
