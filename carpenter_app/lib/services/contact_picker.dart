import 'package:flutter_contacts/flutter_contacts.dart';

/// Opens the device's native contact-picker UI so a carpenter can pick a
/// lead's phone number by tapping instead of typing/reading digits
/// (Section 2.1). Uses the external-picker intent, which the OS handles in
/// its own process -- unlike querying contacts directly, this does NOT
/// require the READ_CONTACTS runtime permission prompt.
///
/// Returns the picked contact's first phone number, or null if the user
/// cancelled, denied access, or the contact has no number.
Future<String?> pickContactPhone() async {
  try {
    final contact = await FlutterContacts.openExternalPick();
    if (contact == null) return null;
    final full = await FlutterContacts.getContact(contact.id, withProperties: true);
    final phones = full?.phones ?? contact.phones;
    if (phones.isEmpty) return null;
    return phones.first.number;
  } catch (_) {
    return null;
  }
}
