import 'package:flutter/material.dart';

enum AppNavSection {
  dashboard,
  patients,
  patientDetail,
  pharmacyBills,
  settings,
}

enum PatientDetailTab {
  overview,
  consultations,
  treatmentsSessions,
  progressPhotos,
  billing,
  history,
}

enum SessionState {
  scheduled,
  arrived,
  inProgress,
  completed,
}

class PharmacyBillItem {
  final int id;
  final String name;
  final int amount;
  final String lastDate;
  String status;

  PharmacyBillItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.lastDate,
    required this.status,
  });
}

class BillReminderItem {
  final String name;
  final int daysRemaining;
  final String dueDate;
  final int amount;
  final String badge;
  bool isClosed;
  bool isPaid;

  BillReminderItem({
    required this.name,
    required this.daysRemaining,
    required this.dueDate,
    required this.amount,
    required this.badge,
    this.isClosed = false,
    this.isPaid = false,
  });
}

class PatientRecord {
  final String id;
  final String patientId;
  final String name;
  final int age;
  final String dob;
  final String gender;
  final String phone;
  final String address;
  final String source;
  final List<String> concerns;
  final String assignedDoctor;
  final String status;
  final String treatment;
  final String initials;
  final Color avatarColor;

  PatientRecord({
    required this.id,
    required this.patientId,
    required this.name,
    required this.age,
    required this.dob,
    required this.gender,
    required this.phone,
    required this.address,
    required this.source,
    required this.concerns,
    required this.assignedDoctor,
    required this.status,
    required this.treatment,
    required this.initials,
    required this.avatarColor,
  });
}

class AppViewModel extends ChangeNotifier {
  AppNavSection _currentSection = AppNavSection.dashboard;
  PatientDetailTab _currentPatientTab = PatientDetailTab.overview;
  String _selectedMonth = 'Apr';
  final int _selectedYear = 2025;
  String _searchQuery = '';

  // Patient Detail State
  SessionState _sessionState = SessionState.scheduled;
  String? _arrivalTime;
  String? _startTime;
  String? _endTime;

  // Selected Patient
  late PatientRecord _selectedPatient;

  // Pharmacy list
  final List<PharmacyBillItem> _pharmacyBills = [
    PharmacyBillItem(id: 1, name: 'Sun Pharma', amount: 25000, lastDate: '30 Jun 2025', status: 'Upcoming'),
    PharmacyBillItem(id: 2, name: 'Cipla', amount: 18500, lastDate: '15 Jun 2025', status: 'Upcoming'),
    PharmacyBillItem(id: 3, name: 'Mankind Pharma', amount: 42000, lastDate: '30 May 2025', status: 'Upcoming'),
    PharmacyBillItem(id: 4, name: 'Alkem Laboratories', amount: 12800, lastDate: '10 May 2025', status: 'Due Soon'),
    PharmacyBillItem(id: 5, name: 'Zydus', amount: 31000, lastDate: '30 Apr 2025', status: 'Due Soon'),
    PharmacyBillItem(id: 6, name: 'Abbott', amount: 27600, lastDate: '25 Apr 2025', status: 'Urgent'),
    PharmacyBillItem(id: 7, name: "Dr. Reddy's", amount: 19200, lastDate: '20 Apr 2025', status: 'Urgent'),
    PharmacyBillItem(id: 8, name: 'Torrent Pharma', amount: 11500, lastDate: '15 Apr 2025', status: 'Overdue'),
    PharmacyBillItem(id: 9, name: 'Intas Pharmaceuticals', amount: 8400, lastDate: '05 Apr 2025', status: 'Settled'),
  ];

  // Reminders list
  final List<BillReminderItem> _reminders = [
    BillReminderItem(name: 'Abbott', daysRemaining: 5, dueDate: '25 Apr 2025', amount: 27600, badge: 'Urgent'),
    BillReminderItem(name: 'Zydus', daysRemaining: 15, dueDate: '30 Apr 2025', amount: 31000, badge: 'Due Soon'),
    BillReminderItem(name: 'Alkem Laboratories', daysRemaining: 25, dueDate: '10 May 2025', amount: 12800, badge: 'Due Soon'),
    BillReminderItem(name: 'Mankind Pharma', daysRemaining: 45, dueDate: '30 May 2025', amount: 42600, badge: 'Upcoming'),
  ];

  // Follow up patients
  final List<PatientRecord> _patients = [
    PatientRecord(
      id: '1',
      patientId: '#PT-1001',
      name: 'Priya Menon',
      age: 27,
      dob: '18 Aug 1998',
      gender: 'Female',
      phone: '+91 98765 43210',
      address: '12/A, Marine Drive, Kochi - 682011',
      source: 'Google Search',
      concerns: ['Laser', 'Skin'],
      assignedDoctor: 'Dr. Anjali Nair',
      status: 'Active Treatment',
      treatment: 'Laser Hair Reduction',
      initials: 'PM',
      avatarColor: const Color(0xFFD1E7DD),
    ),
    PatientRecord(
      id: '2',
      patientId: '#PT-1002',
      name: 'Arjun Nair',
      age: 31,
      dob: '05 Jan 1994',
      gender: 'Male',
      phone: '+91 98950 12345',
      address: 'Panampilly Nagar, Kochi - 682036',
      source: 'Walk-in',
      concerns: ['Skin'],
      assignedDoctor: 'Dr. Rohit Kumar',
      status: 'Active Treatment',
      treatment: 'Acne Treatment',
      initials: 'AN',
      avatarColor: const Color(0xFFE2E8F0),
    ),
    PatientRecord(
      id: '3',
      patientId: '#PT-1003',
      name: 'Sneha Varghese',
      age: 29,
      dob: '12 Mar 1996',
      gender: 'Female',
      phone: '+91 81234 56789',
      address: '28/4, Green View Apartments, Kadavanthra, Kochi - 682020, Kerala',
      source: 'Instagram',
      concerns: ['Skin', 'Laser'],
      assignedDoctor: 'Dr. Anjali Nair',
      status: 'Active Treatment',
      treatment: 'Skin Rejuvenation',
      initials: 'SK',
      avatarColor: const Color(0xFFD1E7DD),
    ),
    PatientRecord(
      id: '4',
      patientId: '#PT-1004',
      name: 'Rohan Mathew',
      age: 34,
      dob: '22 Nov 1990',
      gender: 'Male',
      phone: '+91 98654 32109',
      address: 'Edapally, Kochi - 682024',
      source: 'Referral',
      concerns: ['Hair'],
      assignedDoctor: 'Dr. Karthik Iyer',
      status: 'Active Treatment',
      treatment: 'Hair PRP',
      initials: 'RM',
      avatarColor: const Color(0xFFDBEAFE),
    ),
    PatientRecord(
      id: '5',
      patientId: '#PT-1005',
      name: 'Anjali Suresh',
      age: 26,
      dob: '14 Jun 1999',
      gender: 'Female',
      phone: '+91 97462 09876',
      address: 'Kaloor, Kochi - 682017',
      source: 'Instagram',
      concerns: ['Laser'],
      assignedDoctor: 'Dr. Meera Thomas',
      status: 'Active Treatment',
      treatment: 'Laser Toning',
      initials: 'AS',
      avatarColor: const Color(0xFFE0E7FF),
    ),
    PatientRecord(
      id: '6',
      patientId: '#PT-1006',
      name: 'Karthik Iyer',
      age: 38,
      dob: '09 Sep 1987',
      gender: 'Male',
      phone: '+91 99678 54321',
      address: 'Vyttila, Kochi - 682019',
      source: 'Facebook',
      concerns: ['Body Aesthetics'],
      assignedDoctor: 'Dr. Rohit Kumar',
      status: 'Active Treatment',
      treatment: 'Body Contouring',
      initials: 'KI',
      avatarColor: const Color(0xFFFEE2E2),
    ),
  ];

  AppViewModel() {
    _selectedPatient = _patients[2]; // Default to Sneha Varghese (#PT-1003)
  }

  // Getters
  AppNavSection get currentSection => _currentSection;
  PatientDetailTab get currentPatientTab => _currentPatientTab;
  String get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  String get searchQuery => _searchQuery;
  SessionState get sessionState => _sessionState;
  String? get arrivalTime => _arrivalTime;
  String? get startTime => _startTime;
  String? get endTime => _endTime;
  PatientRecord get selectedPatient => _selectedPatient;
  List<PharmacyBillItem> get pharmacyBills => _pharmacyBills;
  List<BillReminderItem> get activeReminders => _reminders.where((r) => !r.isClosed && !r.isPaid).toList();
  List<PatientRecord> get patients => _patients;

  // Actions
  void navigateTo(AppNavSection section) {
    _currentSection = section;
    notifyListeners();
  }

  void selectPatient(PatientRecord patient) {
    _selectedPatient = patient;
    _currentSection = AppNavSection.patientDetail;
    _currentPatientTab = PatientDetailTab.overview;
    notifyListeners();
  }

  void setPatientTab(PatientDetailTab tab) {
    _currentPatientTab = tab;
    notifyListeners();
  }

  void selectMonth(String month) {
    _selectedMonth = month;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Session State Progressions
  void recordPatientArrival() {
    _sessionState = SessionState.arrived;
    final now = DateTime.now();
    _arrivalTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    notifyListeners();
  }

  void startSession() {
    _sessionState = SessionState.inProgress;
    final now = DateTime.now();
    _startTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    notifyListeners();
  }

  void endSession() {
    _sessionState = SessionState.completed;
    final now = DateTime.now();
    _endTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    notifyListeners();
  }

  void resetSession() {
    _sessionState = SessionState.scheduled;
    _arrivalTime = null;
    _startTime = null;
    _endTime = null;
    notifyListeners();
  }

  // Pharmacy Actions
  void markReminderAsPaid(String pharmacyName) {
    for (var r in _reminders) {
      if (r.name == pharmacyName) {
        r.isPaid = true;
      }
    }
    for (var b in _pharmacyBills) {
      if (b.name == pharmacyName) {
        b.status = 'Settled';
      }
    }
    notifyListeners();
  }

  void closeReminder(String pharmacyName) {
    for (var r in _reminders) {
      if (r.name == pharmacyName) {
        r.isClosed = true;
      }
    }
    notifyListeners();
  }

  void addPharmacyBill({
    required String name,
    required int amount,
    required String dueDate,
  }) {
    _pharmacyBills.insert(
      0,
      PharmacyBillItem(
        id: _pharmacyBills.length + 1,
        name: name,
        amount: amount,
        lastDate: dueDate,
        status: 'Upcoming',
      ),
    );
    notifyListeners();
  }

  void addNewPatient({
    required String name,
    required int age,
    required String gender,
    required String phone,
    required String address,
    required String source,
    required String concern,
    required String doctor,
  }) {
    final newId = '#PT-100${_patients.length + 1}';
    final initials = name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    final newPatient = PatientRecord(
      id: (_patients.length + 1).toString(),
      patientId: newId,
      name: name,
      age: age,
      dob: '01 Jan 1995',
      gender: gender,
      phone: phone,
      address: address,
      source: source,
      concerns: [concern],
      assignedDoctor: doctor,
      status: 'Active Treatment',
      treatment: concern,
      initials: initials.isEmpty ? 'PT' : initials,
      avatarColor: const Color(0xFFD1E7DD),
    );
    _patients.insert(0, newPatient);
    _selectedPatient = newPatient;
    _currentSection = AppNavSection.patientDetail;
    notifyListeners();
  }
}
