import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:worki/constants/app_constants.dart';
import 'package:worki/models/job_model.dart';
import 'package:worki/models/user_profile.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;

  const JobDetailScreen({Key? key, required this.job}) : super(key: key);

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _offerController = TextEditingController();
  final _coverLetterController = TextEditingController();
  bool _isLoading = false;
  bool _hasApplied = false;
  String _authorName = '';

  @override
  void initState() {
    super.initState();
    _loadAuthorInfo();
    _checkIfAlreadyApplied();
  }

  @override
  void dispose() {
    _offerController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthorInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.job.authorId)
          .get();
      
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _authorName = '${data['name'] ?? ''} ${data['lastName'] ?? ''}'.trim();
          if (_authorName.isEmpty) {
            _authorName = AppConstants.defaultUserName;
          }
        });
      }
    } catch (e) {
      // Error loading author info - use default
      setState(() {
        _authorName = AppConstants.defaultUserName;
      });
    }
  }

  Future<void> _checkIfAlreadyApplied() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('job_applications')
          .where('jobId', isEqualTo: widget.job.id)
          .where('applicantId', isEqualTo: currentUser.uid)
          .get();

      if (mounted) {
        setState(() {
          _hasApplied = querySnapshot.docs.isNotEmpty;
        });
      }
    } catch (e) {
      // Error checking application status
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar('Error: Usuario no autenticado');
      return;
    }

    // Check if user is trying to apply to their own job
    if (currentUser.uid == widget.job.authorId) {
      _showSnackBar(AppConstants.cannotApplyOwnJob);
      return;
    }

    if (_hasApplied) {
      _showSnackBar(AppConstants.alreadyApplied);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user's name
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      String applicantName = AppConstants.defaultUserName;
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        applicantName = '${userData['name'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
        if (applicantName.isEmpty) {
          applicantName = AppConstants.defaultUserName;
        }
      }

      final application = JobApplication(
        id: '',
        jobId: widget.job.id,
        applicantId: currentUser.uid,
        applicantName: applicantName,
        offerAmount: double.parse(_offerController.text.trim()),
        coverLetter: _coverLetterController.text.trim(),
        appliedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('job_applications')
          .add(application.toMap());

      // Create notification for job author
      await _createNotificationForJobAuthor(application, applicantName);

      if (mounted) {
        _showSnackBar(AppConstants.applicationSent);
        setState(() {
          _hasApplied = true;
        });
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al enviar postulación: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createNotificationForJobAuthor(JobApplication application, String applicantName) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: widget.job.authorId,
        title: AppConstants.newApplicationTitle,
        body: '$applicantName ${AppConstants.newApplicationBody} "${widget.job.title}"',
        type: 'application',
        data: {
          'jobId': widget.job.id,
          'applicationId': application.id,
          'applicantId': application.applicantId,
        },
      );

      await FirebaseFirestore.instance
          .collection('notifications')
          .add(notification.toMap());
    } catch (e) {
      // Handle notification creation error silently
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showApplicationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(AppConstants.makeOffer),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _offerController,
                    decoration: const InputDecoration(
                      labelText: AppConstants.offerAmount,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.euro),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingresa tu oferta';
                      }
                      final offer = double.tryParse(value.trim());
                      if (offer == null || offer <= 0) {
                        return 'Por favor ingresa una oferta válida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _coverLetterController,
                    decoration: const InputDecoration(
                      labelText: AppConstants.coverLetter,
                      hintText: AppConstants.coverLetterHint,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor escribe una carta de presentación';
                      }
                      if (value.trim().length < 20) {
                        return 'La carta debe tener al menos 20 caracteres';
                      }
                      return null;
                    },
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
              onPressed: _isLoading ? null : () {
                Navigator.of(context).pop();
                _submitApplication();
              },
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(AppConstants.submitApplication),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnJob = currentUser?.uid == widget.job.authorId;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.jobDetails),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Title
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.job.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${AppConstants.postedBy}: $_authorName',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Budget
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.euro, color: Colors.green, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppConstants.jobBudget,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '€${widget.job.budget.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.job.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Skills
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppConstants.requiredSkillsTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: widget.job.skills.map((skill) {
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
            const SizedBox(height: 24),

            // Apply Button
            if (!isOwnJob)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _hasApplied ? null : _showApplicationDialog,
                  icon: Icon(_hasApplied ? Icons.check : Icons.send),
                  label: Text(
                    _hasApplied ? AppConstants.alreadyApplied : AppConstants.applyToJob,
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasApplied ? Colors.grey : Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            if (isOwnJob)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este es tu trabajo publicado',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
