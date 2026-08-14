import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/models/carer.dart';

void main() {
  group('Extended Carer Model Tests', () {
    test('Carer creation with all new fields', () {
      final carer = Carer(
        id: 'test-carer-id',
        name: 'John Doe',
        email: 'john.doe@example.com',
        phone: '555-1234',
        employeeNumber: 'EMP123456',
        dbsNumber: 'DBS123456',
        dbsExpiryDate: DateTime(2025, 12, 31),
        dbsCertificateUrl: 'https://example.com/dbs-certificate.pdf',
        idDocumentUrl: 'https://example.com/id-document.pdf',
        idExpiryDate: DateTime(2024, 6, 30),
        proofOfResidenceUrl: 'https://example.com/residence-proof.pdf',
        proofOfResidenceExpiry: DateTime(2024, 8, 15),
        infectionControlUrl: 'https://example.com/infection-control.pdf',
        infectionControlExpiry: DateTime(2024, 12, 31),
        manualHandlingUrl: 'https://example.com/manual-handling.pdf',
        manualHandlingExpiry: DateTime(2025, 3, 31),
        safeguardingUrl: 'https://example.com/safeguarding.pdf',
        safeguardingExpiry: DateTime(2025, 6, 30),
        fitnessToWorkExpiry: DateTime(2024, 10, 15),
        sortCode: '123456',
        accountNumber: '12345678',
        photoUrl: 'https://example.com/photo.jpg',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(carer.id, 'test-carer-id');
      expect(carer.name, 'John Doe');
      expect(carer.email, 'john.doe@example.com');
      expect(carer.phone, '555-1234');
      expect(carer.employeeNumber, 'EMP123456');
      expect(carer.dbsNumber, 'DBS123456');
      expect(carer.dbsExpiryDate, DateTime(2025, 12, 31));
      expect(carer.dbsCertificateUrl, 'https://example.com/dbs-certificate.pdf');
      expect(carer.idDocumentUrl, 'https://example.com/id-document.pdf');
      expect(carer.idExpiryDate, DateTime(2024, 6, 30));
      expect(carer.proofOfResidenceUrl, 'https://example.com/residence-proof.pdf');
      expect(carer.proofOfResidenceExpiry, DateTime(2024, 8, 15));
      expect(carer.infectionControlUrl, 'https://example.com/infection-control.pdf');
      expect(carer.infectionControlExpiry, DateTime(2024, 12, 31));
      expect(carer.manualHandlingUrl, 'https://example.com/manual-handling.pdf');
      expect(carer.manualHandlingExpiry, DateTime(2025, 3, 31));
      expect(carer.safeguardingUrl, 'https://example.com/safeguarding.pdf');
      expect(carer.safeguardingExpiry, DateTime(2025, 6, 30));
      expect(carer.fitnessToWorkExpiry, DateTime(2024, 10, 15));
      expect(carer.sortCode, '123456');
      expect(carer.accountNumber, '12345678');
      expect(carer.photoUrl, 'https://example.com/photo.jpg');
      expect(carer.isActive, true);
    });

    test('Carer toMap conversion with all fields', () {
      final carer = Carer(
        id: 'test-carer-id',
        name: 'John Doe',
        email: 'john.doe@example.com',
        phone: '555-1234',
        employeeNumber: 'EMP123456',
        dbsNumber: 'DBS123456',
        dbsExpiryDate: DateTime(2025, 12, 31),
        dbsCertificateUrl: 'https://example.com/dbs-certificate.pdf',
        idDocumentUrl: 'https://example.com/id-document.pdf',
        idExpiryDate: DateTime(2024, 6, 30),
        proofOfResidenceUrl: 'https://example.com/residence-proof.pdf',
        proofOfResidenceExpiry: DateTime(2024, 8, 15),
        infectionControlUrl: 'https://example.com/infection-control.pdf',
        infectionControlExpiry: DateTime(2024, 12, 31),
        manualHandlingUrl: 'https://example.com/manual-handling.pdf',
        manualHandlingExpiry: DateTime(2025, 3, 31),
        safeguardingUrl: 'https://example.com/safeguarding.pdf',
        safeguardingExpiry: DateTime(2025, 6, 30),
        fitnessToWorkExpiry: DateTime(2024, 10, 15),
        sortCode: '123456',
        accountNumber: '12345678',
        photoUrl: 'https://example.com/photo.jpg',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = carer.toMap();
      
      expect(map['id'], 'test-carer-id');
      expect(map['name'], 'John Doe');
      expect(map['email'], 'john.doe@example.com');
      expect(map['phone'], '555-1234');
      expect(map['employee_number'], 'EMP123456');
      expect(map['dbs_number'], 'DBS123456');
      expect(map['dbs_expiry_date'], DateTime(2025, 12, 31));
      expect(map['dbs_certificate_url'], 'https://example.com/dbs-certificate.pdf');
      expect(map['id_document_url'], 'https://example.com/id-document.pdf');
      expect(map['id_expiry_date'], DateTime(2024, 6, 30));
      expect(map['proof_of_residence_url'], 'https://example.com/residence-proof.pdf');
      expect(map['proof_of_residence_expiry'], DateTime(2024, 8, 15));
      expect(map['infection_control_url'], 'https://example.com/infection-control.pdf');
      expect(map['infection_control_expiry'], DateTime(2024, 12, 31));
      expect(map['manual_handling_url'], 'https://example.com/manual-handling.pdf');
      expect(map['manual_handling_expiry'], DateTime(2025, 3, 31));
      expect(map['safeguarding_url'], 'https://example.com/safeguarding.pdf');
      expect(map['safeguarding_expiry'], DateTime(2025, 6, 30));
      expect(map['fitness_to_work_expiry'], DateTime(2024, 10, 15));
      expect(map['sort_code'], '123456');
      expect(map['account_number'], '12345678');
      expect(map['photo_url'], 'https://example.com/photo.jpg');
      expect(map['is_active'], true);
    });

    test('Carer fromMap conversion with all fields', () {
      final map = {
        'id': 'test-carer-id',
        'name': 'John Doe',
        'email': 'john.doe@example.com',
        'phone': '555-1234',
        'employee_number': 'EMP123456',
        'dbs_number': 'DBS123456',
        'dbs_expiry_date': DateTime(2025, 12, 31),
        'dbs_certificate_url': 'https://example.com/dbs-certificate.pdf',
        'id_document_url': 'https://example.com/id-document.pdf',
        'id_expiry_date': DateTime(2024, 6, 30),
        'proof_of_residence_url': 'https://example.com/residence-proof.pdf',
        'proof_of_residence_expiry': DateTime(2024, 8, 15),
        'infection_control_url': 'https://example.com/infection-control.pdf',
        'infection_control_expiry': DateTime(2024, 12, 31),
        'manual_handling_url': 'https://example.com/manual-handling.pdf',
        'manual_handling_expiry': DateTime(2025, 3, 31),
        'safeguarding_url': 'https://example.com/safeguarding.pdf',
        'safeguarding_expiry': DateTime(2025, 6, 30),
        'fitness_to_work_expiry': DateTime(2024, 10, 15),
        'sort_code': '123456',
        'account_number': '12345678',
        'photo_url': 'https://example.com/photo.jpg',
        'is_active': true,
        'created_at': DateTime.now(),
        'updated_at': DateTime.now(),
      };

      final carer = Carer.fromMap(map);
      
      expect(carer.id, 'test-carer-id');
      expect(carer.name, 'John Doe');
      expect(carer.email, 'john.doe@example.com');
      expect(carer.phone, '555-1234');
      expect(carer.employeeNumber, 'EMP123456');
      expect(carer.dbsNumber, 'DBS123456');
      expect(carer.dbsExpiryDate, DateTime(2025, 12, 31));
      expect(carer.dbsCertificateUrl, 'https://example.com/dbs-certificate.pdf');
      expect(carer.idDocumentUrl, 'https://example.com/id-document.pdf');
      expect(carer.idExpiryDate, DateTime(2024, 6, 30));
      expect(carer.proofOfResidenceUrl, 'https://example.com/residence-proof.pdf');
      expect(carer.proofOfResidenceExpiry, DateTime(2024, 8, 15));
      expect(carer.infectionControlUrl, 'https://example.com/infection-control.pdf');
      expect(carer.infectionControlExpiry, DateTime(2024, 12, 31));
      expect(carer.manualHandlingUrl, 'https://example.com/manual-handling.pdf');
      expect(carer.manualHandlingExpiry, DateTime(2025, 3, 31));
      expect(carer.safeguardingUrl, 'https://example.com/safeguarding.pdf');
      expect(carer.safeguardingExpiry, DateTime(2025, 6, 30));
      expect(carer.fitnessToWorkExpiry, DateTime(2024, 10, 15));
      expect(carer.sortCode, '123456');
      expect(carer.accountNumber, '12345678');
      expect(carer.photoUrl, 'https://example.com/photo.jpg');
      expect(carer.isActive, true);
    });

  });
}