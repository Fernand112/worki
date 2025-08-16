import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:worki/constants/app_constants.dart';
import 'package:worki/models/user_profile.dart';
import 'package:worki/models/job_model.dart';

class ApplicantProfileScreen extends StatefulWidget {
  final JobApplication application;
  final Job job;

  const ApplicantProfileScreen({
    Key? key,
    required this.application,
    required this.job,
  }) : super(key: key);

  @override
  State<ApplicantProfileScreen> createState() => _ApplicantProfileScreenState();
}

class _ApplicantProfileScreenState extends State<ApplicantProfileScreen> {
  UserProfile? _applicantProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplicantProfile();
  }

  Future<void> _loadApplicantProfile() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.application.applicantId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _applicantProfile = UserProfile.fromFirestore(userDoc);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateApplicationStatus(String status) async {
    try {
      // Update application status
      await FirebaseFirestore.instance
          .collection('job_applications')
          .doc(widget.application.id)
          .update({'status': status});

      // Create notification for applicant
      final notification = NotificationModel(
        id: '',
        userId: widget.application.applicantId,
        title: status == 'accepted' 
            ? 'Propuesta Aceptada ✅' 
            : 'Propuesta Rechazada ❌',
        body: status == 'accepted'
            ? 'Tu propuesta para "${widget.job.title}" ha sido aceptada. ¡Felicidades!'
            : 'Tu propuesta para "${widget.job.title}" ha sido rechazada.',
        type: 'application_response',
        data: {
          'jobId': widget.job.id,
          'applicationId': widget.application.id,
          'status': status,
        },
      );

      await FirebaseFirestore.instance
          .collection('notifications')
          .add(notification.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'accepted' 
                ? 'Postulante aceptado exitosamente'
                : 'Postulante rechazado'),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Postulante'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applicantProfile == null
              ? const Center(child: Text('Error cargando perfil'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Applicant Profile Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Profile Photo
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.shade100,
                                ),
                                child: _applicantProfile!.profileImageUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                          _applicantProfile!.profileImageUrl!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(Icons.person, size: 50, color: Colors.blue.shade600);
                                          },
                                        ),
                                      )
                                    : Icon(Icons.person, size: 50, color: Colors.blue.shade600),
                              ),
                              const SizedBox(height: 16),

                              // Name
                              Text(
                                _applicantProfile!.displayName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _applicantProfile!.email,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Bio Card
                      if (_applicantProfile!.bio != null && _applicantProfile!.bio!.isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Biografía',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(_applicantProfile!.bio!),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Skills Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Habilidades',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_applicantProfile!.skills.isEmpty)
                                const Text('No ha agregado habilidades')
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: _applicantProfile!.skills.map((skill) {
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

                      const SizedBox(height: 16),

                      // Application Details Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detalles de la Propuesta',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.attach_money, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Oferta: \$${widget.application.offerAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Fecha: ${widget.application.appliedAt?.day}/${widget.application.appliedAt?.month}/${widget.application.appliedAt?.year}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Carta de Presentación:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.application.coverLetter,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      if (widget.application.status == 'pending')
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _updateApplicationStatus('accepted'),
                                icon: const Icon(Icons.check),
                                label: const Text('Aceptar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _updateApplicationStatus('rejected'),
                                icon: const Icon(Icons.close),
                                label: const Text('Rechazar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: widget.application.status == 'accepted' 
                                ? Colors.green.shade50 
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.application.status == 'accepted' 
                                  ? Colors.green 
                                  : Colors.red,
                            ),
                          ),
                          child: Text(
                            widget.application.status == 'accepted' 
                                ? '✅ Postulante Aceptado' 
                                : '❌ Postulante Rechazado',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: widget.application.status == 'accepted' 
                                  ? Colors.green.shade700 
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
