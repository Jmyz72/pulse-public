import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/bill_payment_verification_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/bill.dart';
import '../bloc/living_tools_bloc.dart';

class BillPaymentProofSheet extends StatefulWidget {
  final Bill bill;
  final BillMember member;
  final BillPaymentVerificationService verificationService;

  const BillPaymentProofSheet({
    super.key,
    required this.bill,
    required this.member,
    required this.verificationService,
  });

  @override
  State<BillPaymentProofSheet> createState() => _BillPaymentProofSheetState();
}

class _BillPaymentProofSheetState extends State<BillPaymentProofSheet> {
  File? _imageFile;
  bool _isUploading = false;
  bool _isVerifying = false;
  String? _statusMessage;
  BillPaymentVerificationResult? _verificationResult;

  final List<Map<String, dynamic>> _banks = [
    {
      'name': 'Maybank',
      'package': 'com.maybank2u.m2umobile',
      'url': 'https://www.maybank2u.com.my',
    },
    {
      'name': 'CIMB',
      'package': 'com.cimb.cimbclicks',
      'url': 'https://www.cimbclicks.com.my',
    },
    {
      'name': 'Public Bank',
      'package': 'com.pbebank.pbe',
      'url': 'https://www.pbebank.com',
    },
    {
      'name': 'RHB',
      'package': 'com.rhbgroup.rhbmobile',
      'url': 'https://www.rhbgroup.com',
    },
    {
      'name': 'Touch n Go',
      'package': 'my.com.tngdigital.ewallet',
      'url': 'tngewallet://',
    },
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _verificationResult = null;
        _statusMessage = null;
      });
      _verifyProof();
    }
  }

  Future<void> _verifyProof() async {
    if (_imageFile == null) return;

    setState(() {
      _isVerifying = true;
      _statusMessage = 'AI is verifying your receipt...';
    });

    try {
      final bytes = await _imageFile!.readAsBytes();
      final result = await widget.verificationService.verifyPaymentProof(
        imageBytes: Uint8List.fromList(bytes),
        expectedAmount: widget.member.share,
        expectedRecipient: widget.bill.paymentDetails?.accountName,
      );

      setState(() {
        _verificationResult = result;
        _isVerifying = false;
        _statusMessage = result.isMatch
            ? '✅ Payment details match!'
            : '⚠️ Details might not match. Confidence: ${(result.confidence * 100).toInt()}%';
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _statusMessage =
            '❌ AI verification failed. You can still upload manually.';
      });
    }
  }

  Future<void> _uploadAndSubmit() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('bill_proofs')
          .child(
            '${widget.bill.id}_${widget.member.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

      await storageRef.putFile(_imageFile!);
      final imageUrl = await storageRef.getDownloadURL();

      if (mounted) {
        context.read<LivingToolsBloc>().add(
          LivingToolsBillPaymentProofUploaded(
            billId: widget.bill.id,
            memberId: widget.member.userId,
            proofImageUrl: imageUrl,
            transactionRef: _verificationResult?.transactionId,
          ),
        );

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment proof uploaded successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  void _launchBankApp(Map<String, dynamic> bank) async {
    final url = Uri.parse(bank['url']);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to browser or store
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open ${bank['name']}. Please open it manually.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = widget.bill.paymentDetails;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pay Bill',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount to pay: RM ${widget.member.share.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            if (details != null) ...[
              const Text(
                'Payment Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  children: [
                    _buildDetailRow('Bank', details.bankName ?? 'N/A'),
                    _buildDetailRow(
                      'Account Name',
                      details.accountName ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Account No.',
                      details.accountNumber ?? 'N/A',
                      canCopy: true,
                    ),
                    if (details.duitNowId != null)
                      _buildDetailRow(
                        'DuitNow ID',
                        details.duitNowId!,
                        canCopy: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text(
              '1. Open Bank App',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _banks
                    .map(
                      (bank) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(bank['name']),
                          onPressed: () => _launchBankApp(bank),
                          backgroundColor: AppColors.secondary.withValues(
                            alpha: 0.1,
                          ),
                          labelStyle: const TextStyle(
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              '2. Upload Screenshot',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _isUploading ? null : _pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.getGlassBorder(0.3),
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 40,
                            color: AppColors.textTertiary,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap to upload receipt screenshot',
                            style: TextStyle(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
              ),
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (_isVerifying)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    if (_isVerifying) const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            CustomButton(
              text: 'Submit for Verification',
              onPressed: _imageFile == null ? null : _uploadAndSubmit,
              isLoading: _isUploading,
              backgroundColor: AppColors.primary,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (canCopy) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$label copied!'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
