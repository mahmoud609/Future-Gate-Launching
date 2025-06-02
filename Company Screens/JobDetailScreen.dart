import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  static const String routeName = "/JobDetailScreen";

  const JobDetailScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  _JobDetailScreenState createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  // Form controllers
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController();
  final _fieldController = TextEditingController();
  final _typeController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _lookingForController = TextEditingController();
  final _willBeDoingController = TextEditingController();

  Map<String, dynamic> _jobData = {};

  @override
  void initState() {
    super.initState();
    _loadJobData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _fieldController.dispose();
    _typeController.dispose();
    _qualificationsController.dispose();
    _lookingForController.dispose();
    _willBeDoingController.dispose();
    super.dispose();
  }

  Future<void> _loadJobData() async {
    try {
      final jobDoc = await FirebaseFirestore.instance
          .collection('interns')
          .doc(widget.jobId)
          .get();

      if (jobDoc.exists) {
        setState(() {
          _jobData = jobDoc.data() as Map<String, dynamic>;
          _isLoading = false;

          // Set controller values
          _titleController.text = _jobData['title'] ?? '';
          _locationController.text = _jobData['location'] ?? '';
          _durationController.text = _jobData['duration'] ?? '';
          _fieldController.text = _jobData['field'] ?? '';
          _typeController.text = _jobData['type'] ?? '';
          _qualificationsController.text = _jobData['preferredQualifications'] ?? '';
          _lookingForController.text = _jobData['whatWeAreLookingFor'] ?? '';
          _willBeDoingController.text = _jobData['whatYouWillBeDoing'] ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job not found')),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading job: $error')),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('interns')
          .doc(widget.jobId)
          .update({
        'title': _titleController.text,
        'location': _locationController.text,
        'duration': _durationController.text,
        'field': _fieldController.text,
        'type': _typeController.text,
        'preferredQualifications': _qualificationsController.text,
        'whatWeAreLookingFor': _lookingForController.text,
        'whatYouWillBeDoing': _willBeDoingController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Internship updated successfully')),
      );
    } catch (error) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating internship: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Internship' : 'Internship Details',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          _isEditing
              ? IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isEditing = false;
                // Reset controllers to original values
                _titleController.text = _jobData['title'] ?? '';
                _locationController.text = _jobData['location'] ?? '';
                _durationController.text = _jobData['duration'] ?? '';
                _fieldController.text = _jobData['field'] ?? '';
                _typeController.text = _jobData['type'] ?? '';
                _qualificationsController.text = _jobData['preferredQualifications'] ?? '';
                _lookingForController.text = _jobData['whatWeAreLookingFor'] ?? '';
                _willBeDoingController.text = _jobData['whatYouWillBeDoing'] ?? '';
              });
            },
          )
              : IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildJobHeader(),
                SizedBox(height: 24),
                _buildSectionTitle('Basic Information'),
                _buildTextField(
                  label: 'Job Title',
                  controller: _titleController,
                  enabled: _isEditing,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a job title';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  label: 'Location',
                  controller: _locationController,
                  enabled: _isEditing,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a location';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  label: 'Duration',
                  controller: _durationController,
                  enabled: _isEditing,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a duration';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  label: 'Field',
                  controller: _fieldController,
                  enabled: _isEditing,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a field';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  label: 'Type',
                  controller: _typeController,
                  enabled: _isEditing,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a type';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                _buildSectionTitle('Details'),
                _buildTextField(
                  label: 'Preferred Qualifications',
                  controller: _qualificationsController,
                  enabled: _isEditing,
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter preferred qualifications';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  label: 'What We Are Looking For',
                  controller: _lookingForController,
                  enabled: _isEditing,
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter what you are looking for';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  label: 'What You Will Be Doing',
                  controller: _willBeDoingController,
                  enabled: _isEditing,
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter what interns will be doing';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32),
                if (_isEditing)
                  Center(
                    child: _isSaving
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF196AB3),
                        padding: EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                _buildApplicationStats(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobHeader() {
    final timestamp = _jobData['timestamp'] as Timestamp?;
    final createdAt = timestamp?.toDate() ?? DateTime.now();
    final formattedDate =
    DateFormat('MMMM d, yyyy').format(createdAt);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _jobData['title'] ?? 'No Title',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text(
                'Posted on $formattedDate',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(width: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF196AB3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _jobData['type'] ?? 'No Type',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF196AB3),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _jobData['location'] ?? 'No Location',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.access_time_outlined, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _jobData['duration'] ?? 'No Duration',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF196AB3),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: enabled ? Colors.grey[700] : Colors.grey[600],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF196AB3), width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          filled: !enabled,
          fillColor: enabled ? Colors.transparent : Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: maxLines > 1 ? 16 : 0,
          ),
        ),
        style: TextStyle(
          color: enabled ? Colors.black87 : Colors.grey[700],
          fontSize: 16,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildApplicationStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Student_Applicant')
          .where('internshipId', isEqualTo: widget.jobId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading applicants'));
        }

        final applicants = snapshot.data?.docs ?? [];
        final pendingCount = applicants
            .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'pending')
            .length;
        final acceptedCount = applicants
            .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'accepted')
            .length;
        final rejectedCount = applicants
            .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'rejected')
            .length;

        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Application Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total', applicants.length.toString(), Colors.blue[700]!),
                  _buildStatItem('Pending', pendingCount.toString(), Colors.amber[700]!),
                  _buildStatItem('Accepted', acceptedCount.toString(), Colors.green[700]!),
                  _buildStatItem('Rejected', rejectedCount.toString(), Colors.red[700]!),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Navigate to applicants list
                  // You can implement this in a future step
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF196AB3),
                  elevation: 0,
                  side: BorderSide(color: Color(0xFF196AB3)),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All Applicants',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}