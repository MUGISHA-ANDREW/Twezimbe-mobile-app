import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:twezimbeapp/core/theme/app_theme.dart';

enum _ExportAction { csv, pdf }

class AdminUserDetailsPage extends StatefulWidget {
  const AdminUserDetailsPage({
    required this.userId,
    this.initialUserData,
    super.key,
  });

  final String userId;
  final Map<String, dynamic>? initialUserData;

  @override
  State<AdminUserDetailsPage> createState() => _AdminUserDetailsPageState();
}

class _AdminUserDetailsPageState extends State<AdminUserDetailsPage> {
  static const int _pageSize = 20;

  bool _isUpdatingKyc = false;
  bool _isUpdatingAdminRole = false;
  bool _isExporting = false;

  bool _isLoadingLoans = false;
  bool _hasMoreLoans = true;
  String? _loanError;
  DocumentSnapshot<Map<String, dynamic>>? _lastLoanDoc;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _loanDocs =
      <QueryDocumentSnapshot<Map<String, dynamic>>>[];

  bool _isLoadingTransactions = false;
  bool _hasMoreTransactions = true;
  String? _transactionError;
  DocumentSnapshot<Map<String, dynamic>>? _lastTransactionDoc;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _transactionDocs =
      <QueryDocumentSnapshot<Map<String, dynamic>>>[];

  bool _isLoadingNotifications = false;
  bool _hasMoreNotifications = true;
  String? _notificationError;
  DocumentSnapshot<Map<String, dynamic>>? _lastNotificationDoc;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _notificationDocs =
      <QueryDocumentSnapshot<Map<String, dynamic>>>[];

  DocumentReference<Map<String, dynamic>> get _userRef =>
      FirebaseFirestore.instance.collection('users').doc(widget.userId);

  @override
  void initState() {
    super.initState();
    _loadLoanApplications(refresh: true);
    _loadTransactions(refresh: true);
    _loadNotifications(refresh: true);
  }

  Future<void> _loadLoanApplications({required bool refresh}) async {
    if (_isLoadingLoans) {
      return;
    }

    setState(() {
      _isLoadingLoans = true;
      if (refresh) {
        _loanError = null;
      }
    });

    try {
      var query = _userRef
          .collection('loanApplications')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (!refresh && _lastLoanDoc != null) {
        query = query.startAfterDocument(_lastLoanDoc!);
      }

      final snapshot = await query.get();
      if (!mounted) {
        return;
      }

      setState(() {
        if (refresh) {
          _loanDocs
            ..clear()
            ..addAll(snapshot.docs);
          _lastLoanDoc = snapshot.docs.isEmpty ? null : snapshot.docs.last;
        } else {
          _loanDocs.addAll(snapshot.docs);
          if (snapshot.docs.isNotEmpty) {
            _lastLoanDoc = snapshot.docs.last;
          }
        }
        _hasMoreLoans = snapshot.docs.length == _pageSize;
        _loanError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loanError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLoans = false;
        });
      }
    }
  }

  Future<void> _loadTransactions({required bool refresh}) async {
    if (_isLoadingTransactions) {
      return;
    }

    setState(() {
      _isLoadingTransactions = true;
      if (refresh) {
        _transactionError = null;
      }
    });

    try {
      var query = _userRef
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (!refresh && _lastTransactionDoc != null) {
        query = query.startAfterDocument(_lastTransactionDoc!);
      }

      final snapshot = await query.get();
      if (!mounted) {
        return;
      }

      setState(() {
        if (refresh) {
          _transactionDocs
            ..clear()
            ..addAll(snapshot.docs);
          _lastTransactionDoc = snapshot.docs.isEmpty
              ? null
              : snapshot.docs.last;
        } else {
          _transactionDocs.addAll(snapshot.docs);
          if (snapshot.docs.isNotEmpty) {
            _lastTransactionDoc = snapshot.docs.last;
          }
        }
        _hasMoreTransactions = snapshot.docs.length == _pageSize;
        _transactionError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _transactionError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTransactions = false;
        });
      }
    }
  }

  Future<void> _loadNotifications({required bool refresh}) async {
    if (_isLoadingNotifications) {
      return;
    }

    setState(() {
      _isLoadingNotifications = true;
      if (refresh) {
        _notificationError = null;
      }
    });

    try {
      var query = _userRef
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (!refresh && _lastNotificationDoc != null) {
        query = query.startAfterDocument(_lastNotificationDoc!);
      }

      final snapshot = await query.get();
      if (!mounted) {
        return;
      }

      setState(() {
        if (refresh) {
          _notificationDocs
            ..clear()
            ..addAll(snapshot.docs);
          _lastNotificationDoc = snapshot.docs.isEmpty
              ? null
              : snapshot.docs.last;
        } else {
          _notificationDocs.addAll(snapshot.docs);
          if (snapshot.docs.isNotEmpty) {
            _lastNotificationDoc = snapshot.docs.last;
          }
        }
        _hasMoreNotifications = snapshot.docs.length == _pageSize;
        _notificationError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _notificationError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNotifications = false;
        });
      }
    }
  }

  Future<void> _updateKycStatus(String status) async {
    if (_isUpdatingKyc) {
      return;
    }

    setState(() => _isUpdatingKyc = true);
    try {
      await _userRef.set({
        'kycStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('KYC status updated to $status')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update KYC status: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingKyc = false);
      }
    }
  }

  Future<void> _toggleAdminRole(bool makeAdmin) async {
    if (_isUpdatingAdminRole) {
      return;
    }

    setState(() => _isUpdatingAdminRole = true);
    try {
      await _userRef.set({
        'isAdmin': makeAdmin,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            makeAdmin
                ? 'User promoted to admin successfully.'
                : 'Admin role removed successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update admin role: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAdminRole = false);
      }
    }
  }

  Future<void> _handleExportAction(
    _ExportAction action,
    Map<String, dynamic> currentUserData,
  ) async {
    if (_isExporting) {
      return;
    }

    setState(() => _isExporting = true);
    try {
      final userData = Map<String, dynamic>.from(currentUserData);
      final loans = await _fetchAllCollectionDocs('loanApplications');
      final transactions = await _fetchAllCollectionDocs('transactions');
      final notifications = await _fetchAllCollectionDocs('notifications');

      final fullName = _stringValue(
        userData['fullName'],
        fallback: widget.userId,
      );
      final fileBaseName = _buildExportFileName(fullName);

      String? savedPath;
      switch (action) {
        case _ExportAction.csv:
          savedPath = await _exportCsv(
            fileBaseName: fileBaseName,
            userData: userData,
            loans: loans,
            transactions: transactions,
            notifications: notifications,
          );
          break;
        case _ExportAction.pdf:
          savedPath = await _exportPdf(
            fileBaseName: fileBaseName,
            userData: userData,
            loans: loans,
            transactions: transactions,
            notifications: notifications,
          );
          break;
      }

      if (!mounted) {
        return;
      }

      final exportType = action == _ExportAction.csv ? 'CSV' : 'PDF';
      if (savedPath == null || savedPath.trim().isEmpty) {
        _showMessage('$exportType export completed successfully.');
      } else {
        _showMessage('$exportType export saved to: $savedPath');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Export failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllCollectionDocs(
    String collectionName,
  ) async {
    const int pageSize = 300;
    final List<Map<String, dynamic>> allRows = <Map<String, dynamic>>[];
    DocumentSnapshot<Map<String, dynamic>>? lastDoc;

    while (true) {
      var query = _userRef
          .collection(collectionName)
          .orderBy('createdAt', descending: true)
          .limit(pageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        break;
      }

      for (final doc in snapshot.docs) {
        final row = Map<String, dynamic>.from(doc.data());
        row['_docId'] = doc.id;
        allRows.add(row);
      }

      lastDoc = snapshot.docs.last;
      if (snapshot.docs.length < pageSize) {
        break;
      }
    }

    return allRows;
  }

  Future<String?> _exportCsv({
    required String fileBaseName,
    required Map<String, dynamic> userData,
    required List<Map<String, dynamic>> loans,
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> notifications,
  }) async {
    final csv = _buildCsvContent(
      userData: userData,
      loans: loans,
      transactions: transactions,
      notifications: notifications,
    );

    return FileSaver.instance.saveFile(
      name: fileBaseName,
      bytes: Uint8List.fromList(utf8.encode(csv)),
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }

  Future<String?> _exportPdf({
    required String fileBaseName,
    required Map<String, dynamic> userData,
    required List<Map<String, dynamic>> loans,
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> notifications,
  }) async {
    final report = pw.Document();
    report.addPage(
      pw.MultiPage(
        build: (context) {
          final List<pw.Widget> widgets = <pw.Widget>[
            pw.Text(
              'Twezimbe Admin User Details Report',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Generated: ${_formatDateTime(DateTime.now())}'),
            pw.SizedBox(height: 12),
            pw.Text(
              'User Summary',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            _pdfTable(
              headers: const <String>['Field', 'Value'],
              rows: <List<String>>[
                <String>['User ID', widget.userId],
                <String>[
                  'Full Name',
                  _stringValue(userData['fullName'], fallback: '-'),
                ],
                <String>[
                  'Email',
                  _stringValue(userData['email'], fallback: '-'),
                ],
                <String>[
                  'Phone',
                  _stringValue(userData['phoneNumber'], fallback: '-'),
                ],
                <String>[
                  'Customer ID',
                  _stringValue(userData['customerId'], fallback: '-'),
                ],
                <String>[
                  'KYC Status',
                  _stringValue(userData['kycStatus'], fallback: '-'),
                ],
                <String>[
                  'Account Type',
                  _stringValue(userData['accountType'], fallback: '-'),
                ],
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'Loan Applications (${loans.length})',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            _pdfTable(
              headers: const <String>[
                'Date',
                'Application ID',
                'Type',
                'Amount',
                'Period',
                'Status',
              ],
              rows: loans
                  .map(
                    (row) => <String>[
                      _formatDateTime(row['createdAt']),
                      _stringValue(row['applicationId'], fallback: '-'),
                      _stringValue(row['loanType'], fallback: '-'),
                      _formatUgx(_intValue(row['amountValue'])),
                      _stringValue(row['period'], fallback: '-'),
                      _stringValue(row['status'], fallback: '-'),
                    ],
                  )
                  .toList(growable: false),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'Transactions (${transactions.length})',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            _pdfTable(
              headers: const <String>[
                'Date',
                'Title',
                'Subtitle',
                'Amount',
                'Direction',
              ],
              rows: transactions
                  .map(
                    (row) => <String>[
                      _formatDateTime(row['createdAt']),
                      _stringValue(row['title'], fallback: '-'),
                      _stringValue(row['subtitle'], fallback: '-'),
                      _formatUgx(_intValue(row['amountValue'])),
                      _boolValue(row['isCredit']) ? 'Credit' : 'Debit',
                    ],
                  )
                  .toList(growable: false),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'Notifications (${notifications.length})',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            _pdfTable(
              headers: const <String>[
                'Date',
                'Title',
                'Message',
                'Type',
                'Read',
              ],
              rows: notifications
                  .map(
                    (row) => <String>[
                      _formatDateTime(row['createdAt']),
                      _stringValue(row['title'], fallback: '-'),
                      _stringValue(row['message'], fallback: '-'),
                      _stringValue(row['type'], fallback: '-'),
                      _boolValue(row['isRead']) ? 'Yes' : 'No',
                    ],
                  )
                  .toList(growable: false),
            ),
          ];
          return widgets;
        },
      ),
    );

    return FileSaver.instance.saveFile(
      name: fileBaseName,
      bytes: await report.save(),
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  String _buildCsvContent({
    required Map<String, dynamic> userData,
    required List<Map<String, dynamic>> loans,
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> notifications,
  }) {
    final buffer = StringBuffer();

    void writeSection(
      String title,
      List<String> headers,
      List<List<String>> rows,
    ) {
      buffer.writeln(_csvRow(<String>[title]));
      buffer.writeln(_csvRow(headers));
      if (rows.isEmpty) {
        buffer.writeln(_csvRow(const <String>['No records']));
      } else {
        for (final row in rows) {
          buffer.writeln(_csvRow(row));
        }
      }
      buffer.writeln();
    }

    writeSection(
      'User Summary',
      const <String>['Field', 'Value'],
      <List<String>>[
        <String>['Generated At', _formatDateTime(DateTime.now())],
        <String>['User ID', widget.userId],
        <String>[
          'Full Name',
          _stringValue(userData['fullName'], fallback: '-'),
        ],
        <String>['Email', _stringValue(userData['email'], fallback: '-')],
        <String>['Phone', _stringValue(userData['phoneNumber'], fallback: '-')],
        <String>[
          'Customer ID',
          _stringValue(userData['customerId'], fallback: '-'),
        ],
        <String>[
          'KYC Status',
          _stringValue(userData['kycStatus'], fallback: '-'),
        ],
        <String>[
          'Account Type',
          _stringValue(userData['accountType'], fallback: '-'),
        ],
      ],
    );

    writeSection(
      'Loan Applications (${loans.length})',
      const <String>[
        'Date',
        'Application ID',
        'Type',
        'Amount',
        'Period',
        'Purpose',
        'Status',
      ],
      loans
          .map(
            (row) => <String>[
              _formatDateTime(row['createdAt']),
              _stringValue(row['applicationId'], fallback: '-'),
              _stringValue(row['loanType'], fallback: '-'),
              _formatUgx(_intValue(row['amountValue'])),
              _stringValue(row['period'], fallback: '-'),
              _stringValue(row['purpose'], fallback: '-'),
              _stringValue(row['status'], fallback: '-'),
            ],
          )
          .toList(growable: false),
    );

    writeSection(
      'Transactions (${transactions.length})',
      const <String>['Date', 'Title', 'Subtitle', 'Amount', 'Direction'],
      transactions
          .map(
            (row) => <String>[
              _formatDateTime(row['createdAt']),
              _stringValue(row['title'], fallback: '-'),
              _stringValue(row['subtitle'], fallback: '-'),
              _formatUgx(_intValue(row['amountValue'])),
              _boolValue(row['isCredit']) ? 'Credit' : 'Debit',
            ],
          )
          .toList(growable: false),
    );

    writeSection(
      'Notifications (${notifications.length})',
      const <String>['Date', 'Title', 'Message', 'Type', 'Read'],
      notifications
          .map(
            (row) => <String>[
              _formatDateTime(row['createdAt']),
              _stringValue(row['title'], fallback: '-'),
              _stringValue(row['message'], fallback: '-'),
              _stringValue(row['type'], fallback: '-'),
              _boolValue(row['isRead']) ? 'Yes' : 'No',
            ],
          )
          .toList(growable: false),
    );

    return buffer.toString();
  }

  String _csvRow(List<String> values) {
    return values.map(_csvEscape).join(',');
  }

  String _csvEscape(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  pw.Widget _pdfTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows.isEmpty
          ? <List<String>>[List<String>.filled(headers.length, '-')]
          : rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellPadding: const pw.EdgeInsets.all(4),
      headerPadding: const pw.EdgeInsets.all(4),
    );
  }

  String _buildExportFileName(String fullName) {
    final normalized = fullName
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final subject = normalized.isEmpty ? widget.userId : normalized;
    return 'user_${subject}_history_${_timestampForFileName()}';
  }

  String _timestampForFileName() {
    final now = DateTime.now();
    final yyyy = now.year.toString();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    return '$yyyy$mm$dd-$hh$min$ss';
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userRef.snapshots(),
      builder: (context, snapshot) {
        final liveData = snapshot.data?.data();
        final userData =
            liveData ?? widget.initialUserData ?? <String, dynamic>{};

        final fullName = _stringValue(
          userData['fullName'],
          fallback: 'Unknown User',
        );
        final email = _stringValue(userData['email']);

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(fullName),
              centerTitle: true,
              actions: [
                if (_isExporting)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                IconButton(
                  tooltip: 'Refresh data',
                  onPressed: () {
                    _loadLoanApplications(refresh: true);
                    _loadTransactions(refresh: true);
                    _loadNotifications(refresh: true);
                  },
                  icon: const Icon(Icons.refresh),
                ),
                PopupMenuButton<_ExportAction>(
                  tooltip: 'Export',
                  onSelected: (action) {
                    _handleExportAction(action, userData);
                  },
                  itemBuilder: (context) =>
                      const <PopupMenuEntry<_ExportAction>>[
                        PopupMenuItem<_ExportAction>(
                          value: _ExportAction.csv,
                          child: Text('Export CSV'),
                        ),
                        PopupMenuItem<_ExportAction>(
                          value: _ExportAction.pdf,
                          child: Text('Export PDF'),
                        ),
                      ],
                ),
              ],
            ),
            body: Column(
              children: [
                _buildHeader(userData),
                if (email.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        email,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                Material(
                  color: Colors.white,
                  child: const TabBar(
                    labelColor: AppColors.primaryBlue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primaryBlue,
                    tabs: [
                      Tab(text: 'Loans'),
                      Tab(text: 'Transactions'),
                      Tab(text: 'Notifications'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildLoanApplicationsTab(),
                      _buildTransactionsTab(),
                      _buildNotificationsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Map<String, dynamic> userData) {
    final fullName = _stringValue(
      userData['fullName'],
      fallback: 'Unknown User',
    );
    final phone = _stringValue(userData['phoneNumber'], fallback: '-');
    final customerId = _stringValue(userData['customerId'], fallback: '-');
    final kycStatus = _stringValue(userData['kycStatus'], fallback: 'Pending');
    final accountType = _stringValue(
      userData['accountType'],
      fallback: 'Savings Account',
    );
    final isAdmin = _boolValue(userData['isAdmin']);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(userData),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customer ID: $customerId',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              _statusChip(kycStatus),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _metaTag(Icons.phone, phone),
              _metaTag(Icons.account_balance_wallet, accountType),
              _metaTag(
                Icons.calendar_today,
                _formatDate(userData['createdAt']),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isUpdatingKyc
                      ? null
                      : () => _updateKycStatus('Rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                    side: const BorderSide(color: AppColors.errorRed),
                  ),
                  child: const Text('Reject KYC'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isUpdatingKyc
                      ? null
                      : () => _updateKycStatus('KYC Verified'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                  ),
                  child: const Text('Approve KYC'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUpdatingAdminRole
                  ? null
                  : () => _toggleAdminRole(!isAdmin),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAdmin
                    ? AppColors.errorRed
                    : AppColors.primaryBlue,
              ),
              icon: Icon(
                isAdmin ? Icons.remove_moderator : Icons.admin_panel_settings,
              ),
              label: Text(isAdmin ? 'Remove Admin Role' : 'Grant Admin Role'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanApplicationsTab() {
    return _buildPaginatedList(
      docs: _loanDocs,
      isLoading: _isLoadingLoans,
      hasMore: _hasMoreLoans,
      error: _loanError,
      emptyLabel: 'No loan applications found for this user.',
      onRefresh: () => _loadLoanApplications(refresh: true),
      onLoadMore: () => _loadLoanApplications(refresh: false),
      itemBuilder: (doc) {
        final data = doc.data();
        final status = _stringValue(data['status'], fallback: 'Pending Review');
        final amount = _formatUgx(_intValue(data['amountValue']));

        return _cardTile(
          title: _stringValue(data['loanType'], fallback: 'Loan Application'),
          subtitle:
              'Amount: $amount\nPeriod: ${_stringValue(data['period'], fallback: '-')}\nPurpose: ${_stringValue(data['purpose'], fallback: '-')}',
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statusChip(status),
              const SizedBox(height: 6),
              Text(
                _formatDateTime(data['createdAt']),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionsTab() {
    return _buildPaginatedList(
      docs: _transactionDocs,
      isLoading: _isLoadingTransactions,
      hasMore: _hasMoreTransactions,
      error: _transactionError,
      emptyLabel: 'No transactions found for this user.',
      onRefresh: () => _loadTransactions(refresh: true),
      onLoadMore: () => _loadTransactions(refresh: false),
      itemBuilder: (doc) {
        final data = doc.data();
        final isCredit = _boolValue(data['isCredit']);
        final amount = _formatUgx(_intValue(data['amountValue']));
        final amountColor = isCredit
            ? AppColors.successGreen
            : AppColors.errorRed;

        return _cardTile(
          title: _stringValue(data['title'], fallback: 'Transaction'),
          subtitle: _stringValue(data['subtitle'], fallback: '-'),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${isCredit ? '+' : '-'} $amount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatDateTime(data['createdAt']),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationsTab() {
    return _buildPaginatedList(
      docs: _notificationDocs,
      isLoading: _isLoadingNotifications,
      hasMore: _hasMoreNotifications,
      error: _notificationError,
      emptyLabel: 'No notifications found for this user.',
      onRefresh: () => _loadNotifications(refresh: true),
      onLoadMore: () => _loadNotifications(refresh: false),
      itemBuilder: (doc) {
        final data = doc.data();
        final isRead = _boolValue(data['isRead']);

        return _cardTile(
          title: _stringValue(data['title'], fallback: 'Notification'),
          subtitle: _stringValue(data['message'], fallback: '-'),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isRead ? 'Read' : 'Unread',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isRead ? Colors.grey.shade600 : AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatDateTime(data['createdAt']),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaginatedList({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required bool isLoading,
    required bool hasMore,
    required String? error,
    required String emptyLabel,
    required Future<void> Function() onRefresh,
    required Future<void> Function() onLoadMore,
    required Widget Function(QueryDocumentSnapshot<Map<String, dynamic>> doc)
    itemBuilder,
  }) {
    if (error != null && docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.errorRed),
              const SizedBox(height: 8),
              Text(
                'Failed to load data.',
                style: TextStyle(color: Colors.grey.shade800),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: onRefresh, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
        itemCount: docs.length + 1,
        itemBuilder: (context, index) {
          if (index < docs.length) {
            return itemBuilder(docs[index]);
          }

          if (docs.isEmpty && isLoading) {
            return const Padding(
              padding: EdgeInsets.only(top: 28),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (docs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 26),
              child: Center(
                child: Text(
                  emptyLabel,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            );
          }

          if (!hasMore) {
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Text(
                  'End of history',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton.icon(
                      onPressed: onLoadMore,
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Load more'),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> data) {
    final photoUrl = _stringValue(data['photoUrl']);
    final fullName = _stringValue(data['fullName'], fallback: 'U');
    final initials = fullName.isEmpty ? 'U' : fullName[0].toUpperCase();

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
      ),
      child: ClipOval(
        child: photoUrl.isEmpty
            ? Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              )
            : Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _metaTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'Approved':
      case 'KYC Verified':
      case 'Active':
      case 'Paid Off':
        color = AppColors.successGreen;
        break;
      case 'Rejected':
        color = AppColors.errorRed;
        break;
      default:
        color = AppColors.primaryOrange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _cardTile({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing,
        ],
      ),
    );
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    if (text.isEmpty) {
      return fallback;
    }
    return text;
  }

  bool _boolValue(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  int _intValue(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }

  String _formatDate(dynamic value) {
    final date = _asDateTime(value);
    if (date == null) {
      return '-';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatDateTime(dynamic value) {
    final date = _asDateTime(value);
    if (date == null) {
      return '-';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String _formatUgx(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final idxFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return 'UGX ${buffer.toString()}';
  }
}
