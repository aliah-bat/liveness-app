import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/theme.dart';
import '../../../core/utils/helpers.dart';
import '../services/ocr_service.dart';
import '../../dashboard/widgets/bottom_nav.dart';
import '../services/bill_service.dart';

class BillScreen extends StatefulWidget {
  const BillScreen({super.key});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  final OCRService _ocrService = OCRService();
  final ImagePicker _picker = ImagePicker();
  
  // OCR related
  File? _selectedImage;
  bool _isProcessing = false;
  
  // Manual entry related
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDueDate;
  
  // Shared
  Map<String, dynamic>? _extractedData;
  bool _isOCRMode = true;

  @override
  void dispose() {
    _ocrService.dispose();
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _extractedData = null;
        });
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to pick image', isError: true);
      }
    }
  }

  Future<void> _captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _extractedData = null;
        });
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to capture image', isError: true);
      }
    }
  }

  Future<void> _extractData() async {
  if (_selectedImage == null) {
    Helpers.showSnackBar(context, 'Please upload a bill image first', isError: true);
    return;
  }

  setState(() => _isProcessing = true);

  try {
    final data = await _ocrService.extractBillData(_selectedImage!.path);
    
    setState(() {
      _extractedData = {
        'title': data['title'],
        'amount': data['amount'],
        'dueDate': data['dueDate'] ?? DateTime.now().add(Duration(days: 30)), // Default to 30 days from now if null
        'rawText': data['rawText'],
      };
      _isProcessing = false;
    });

    if (mounted) {
      Helpers.showSnackBar(context, 'Data extracted successfully!');
    }
  } catch (e) {
    setState(() => _isProcessing = false);
    
    if (mounted) {
      Helpers.showSnackBar(context, 'Failed to extract data: $e', isError: true);
    }
  }
}
  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _submitManualBill() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDueDate == null) {
      Helpers.showSnackBar(context, 'Please select a due date', isError: true);
      return;
    }

    setState(() {
      _extractedData = {
        'title': _titleController.text.trim(),
        'amount': double.parse(_amountController.text.trim()),
        'dueDate': _selectedDueDate,
        'rawText': 'Manual entry',
      };
    });

    Helpers.showSnackBar(context, 'Bill details captured!');
  }

  Future<void> _uploadBill() async {
    if (_extractedData == null) {
      Helpers.showSnackBar(context, 'Please extract or enter bill data first', isError: true);
      return;
    }

    try {
      final billService = BillService();
      
      await billService.createBill(
        title: _extractedData!['title'],
        amount: _extractedData!['amount'],
        dueDate: _extractedData!['dueDate'],
        imageUrl: _selectedImage?.path,
        rawText: _extractedData!['rawText'],
      );

      Helpers.showSnackBar(context, 'Bill saved successfully!');
      
      setState(() {
        _selectedImage = null;
        _extractedData = null;
        _titleController.clear();
        _amountController.clear();
        _selectedDueDate = null;
      });
      
      Navigator.pop(context);
    } catch (e) {
      Helpers.showSnackBar(context, 'Failed to save bill: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Your Bills',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tabs
                      Row(
                        children: [
                          Expanded(
                            child: _isOCRMode
                                ? ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: Icon(Icons.document_scanner),
                                    label: Text('Bill OCR'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  )
                                : OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() => _isOCRMode = true);
                                    },
                                    icon: Icon(Icons.document_scanner),
                                    label: Text('Bill OCR'),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _isOCRMode
                                ? OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() => _isOCRMode = false);
                                    },
                                    icon: Icon(Icons.keyboard),
                                    label: Text('Key in Bill'),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: Icon(Icons.keyboard),
                                    label: Text('Key in Bill'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      if (_isOCRMode) ..._buildOCRContent() else ..._buildManualContent(),

                      SizedBox(height: 24),

                      Text(
                        'Extracted Data',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: 12),

                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildDataRow(
                              'Title Bill',
                              _extractedData?['title'] ?? '-',
                            ),
                            SizedBox(height: 12),
                            _buildDataRow(
                              'Total Bill',
                              _extractedData != null
                                  ? 'RM ${_extractedData!['amount'].toStringAsFixed(2)}'
                                  : '-',
                            ),
                            SizedBox(height: 12),
                            _buildDataRow(
                              'Due Date',
                              _extractedData?['dueDate'] != null
                                  ? _formatDate(_extractedData!['dueDate'])
                                  : '-',
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _extractedData != null ? _uploadBill : null,
                          child: Text(
                            'Upload Bill',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(currentIndex: 1),
    );
  }

  List<Widget> _buildOCRContent() {
    return [
      Text(
        'Upload or Capture Bill Image',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),

      SizedBox(height: 12),

      // Camera and Gallery buttons
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _captureImage,
              icon: Icon(Icons.camera_alt),
              label: Text('Camera'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.photo_library),
              label: Text('Gallery'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),

      SizedBox(height: 12),

      GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: _selectedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.file_present,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please upload a Bill image to extract the data',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),

      SizedBox(height: 16),

      SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _extractData,
          child: _isProcessing
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Extract Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    ];
  }

  List<Widget> _buildManualContent() {
    return [
      Text(
        'Key in Bill Details',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),

      SizedBox(height: 12),

      Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Bill Title',
                hintText: 'e.g., Electricity Bill',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter bill title';
                }
                return null;
              },
            ),

            SizedBox(height: 16),

            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Total Amount',
                hintText: 'e.g., 150.00',
                prefixText: 'RM ',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter amount';
                }
                if (double.tryParse(value.trim()) == null) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),

            SizedBox(height: 16),

            GestureDetector(
              onTap: _selectDueDate,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDueDate != null
                          ? _formatDate(_selectedDueDate!)
                          : 'Due Date',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDueDate != null ? Colors.black : Colors.grey[600],
                      ),
                    ),
                    Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitManualBill,
                child: Text(
                  'Submit Bill',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildDataRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}