/// English/Hindi dictionary for the language toggle.
///
/// Hindi values are meant to be understood when READ ALOUD by someone who
/// cannot read any script -- not just correct Devanagari spelling. Prefer
/// genuine Hindi vocabulary over transliterating the English word (e.g.
/// "सामान" for "Product", not "प्रोडक्ट"). Loanwords that are already
/// standard in everyday *spoken* Hindi (पॉइंट्स, फोन, कैमरा, लॉगिन, ...)
/// are fine to keep -- the bar is "would the target user recognize this
/// word spoken aloud", not "is this pure Sanskrit-derived Hindi".
///
/// Add new keys here as new screens are built; missing keys fall back to
/// the English key itself.
const Map<String, String> hiStrings = {
  'Welcome back': 'वापसी पर स्वागत है',
  'Login to continue': 'जारी रखने के लिए लॉगिन करें',
  'Mobile number': 'मोबाइल नंबर',
  'Password': 'पासवर्ड',
  'Login': 'लॉगिन करें',
  'Logging in...': 'लॉगिन हो रहा है...',
  'Create new account': 'नया खाता बनाएं',
  'Register': 'रजिस्टर करें',
  'Registering...': 'रजिस्टर हो रहा है...',
  'Tell us about your shop': 'अपनी दुकान के बारे में बताएं',
  'Full name': 'पूरा नाम',
  'Shop name': 'दुकान का नाम',
  'Address': 'पता',
  'Back to login': 'लॉगिन पर वापस जाएं',
  'Approval pending': 'अनुमोदन प्रतीक्षित है',
  'Your account is being reviewed by the admin.':
      'आपके खाते की समीक्षा एडमिन द्वारा की जा रही है।',
  'Refresh status': 'स्थिति ताज़ा करें',
  'Checking...': 'जांच हो रही है...',
  'Still pending approval': 'अभी भी अनुमोदन का इंतज़ार है',
  'Location access': 'लोकेशन एक्सेस',
  'Help us track field visits': 'फील्ड विज़िट ट्रैक करने में मदद करें',
  'We use location data to track carpenter visits and activity, even in the background.':
      'हम कारपेंटर की विज़िट और एक्टिविटी ट्रैक करने के लिए लोकेशन डेटा का उपयोग करते हैं, बैकग्राउंड में भी।',
  'We use your location while the app is open to show your last known position to the admin team.':
      'जब तक ऐप खुला है, हम आपकी लोकेशन एडमिन टीम को दिखाने के लिए इस्तेमाल करते हैं।',
  'I agree to share my location with the company.':
      'मैं कंपनी के साथ अपना लोकेशन शेयर करने के लिए सहमत हूं।',
  'Allow location access': 'लोकेशन एक्सेस की अनुमति दें',
  'Continue without sharing': 'शेयर किए बिना जारी रखें',
  'Redeemable Points': 'रिडीमेबल पॉइंट्स',
  'Total Points': 'कुल पॉइंट्स',
  'Activity': 'एक्टिविटी',
  'Redeem cash': 'नकद भुनाएं',
  'Top carpenters': 'टॉप कारपेंटर',
  'You': 'आप',
  'Offers': 'ऑफर',
  'Today & weekly': 'आज और साप्ताहिक',
  'Create order': 'ऑर्डर बनाएं',
  'Image, manual or voice': 'फोटो, लिखकर या आवाज़ से',
  'Redeem points': 'पॉइंट्स भुनाएं',
  'Gifts & cash': 'इनाम और नकद',
  'Suggestions': 'सुझाव',
  'Share a lead': 'लीड शेयर करें',
  'Order history': 'पुराने ऑर्डर',
  'Track past orders': 'पुराने ऑर्डर ट्रैक करें',
  'My account': 'मेरा खाता',
  'Bank, UPI & profile': 'बैंक, यूपीआई और जानकारी',
  'Points': 'पॉइंट्स',
  'pts': 'पॉइंट्स',
  'Current balance': 'मौजूदा बैलेंस',
  'Points activity': 'पॉइंट्स एक्टिविटी',
  'Redeem as cash': 'नकद के रूप में भुनाएं',
  'Redeem a gift': 'इनाम लें',
  'Convert points to your account': 'पॉइंट्स को अपने खाते में बदलें',
  'Rate: 1 point = 1 rupee. Min 500 pts':
      'दर: 1 पॉइंट = 1 रुपया। न्यूनतम 500 पॉइंट्स',
  'Rate: 1 point = 1 rupee. Min {n} pts': 'दर: 1 पॉइंट = 1 रुपया। न्यूनतम {n} पॉइंट्स',
  'Redeem {n} points for cash? This cannot be undone.': '{n} पॉइंट्स को नकद के रूप में भुनाएं? इसे पूर्ववत नहीं किया जा सकता।',
  'Scan to pay via UPI · tap to enlarge': 'यूपीआई से पे करने के लिए स्कैन करें · बड़ा करने के लिए टैप करें',
  'Points to redeem': 'भुनाने के लिए पॉइंट्स',
  'Pays to your account': 'आपके खाते में भुगतान होगा',
  'No payout account set up yet': 'अभी तक कोई भुगतान खाता सेट नहीं है',
  'Confirm redemption': 'भुनाने की पुष्टि करें',
  'Change account details': 'खाता विवरण बदलें',
  'View points': 'पॉइंट्स देखें',
  'Back to dashboard': 'होम पर वापस जाएं',
  'Today': 'आज',
  'Weekly': 'साप्ताहिक',
  'Create order now': 'अभी ऑर्डर बनाएं',
  'Back to offers': 'ऑफर पर वापस जाएं',
  'View PDF': 'पीडीएफ देखें',
  'Gifts': 'इनाम',
  'My gifts': 'मेरे इनाम',
  'No gifts redeemed yet': 'अभी तक कोई इनाम नहीं लिया',
  'Redeem': 'भुनाएं',
  'Locked': 'अभी नहीं',
  'Out of stock': 'स्टॉक खत्म',
  'Need {n} more pts': '{n} पॉइंट्स और चाहिए',
  'Back to gifts': 'इनाम पर वापस जाएं',
  'Gift redeemed': 'इनाम मिल गया',
  'View my gifts': 'मेरे इनाम देखें',
  'Points used': 'इस्तेमाल किए गए पॉइंट्स',
  'Delivery status': 'डिलीवरी स्टेटस',
  'Confirm redemption?': 'भुनाने की पुष्टि करें?',
  'Are you sure you want to redeem this gift?': 'क्या आप वाकई यह इनाम लेना चाहते हैं?',
  'Suggest a lead': 'लीड सुझाएं',
  'Refer someone who needs work done':
      'किसी ऐसे को रेफर करें जिसे काम करवाना है',
  'Your leads': 'आपकी लीड्स',
  'No leads submitted yet': 'अभी तक कोई लीड नहीं भेजी',
  'Name': 'नाम',
  'Phone number': 'फोन नंबर',
  'Location (optional)': 'लोकेशन (वैकल्पिक)',
  'Submit lead': 'लीड सबमिट करें',
  'Lead submitted': 'लीड सबमिट हो गई',
  'Our team will reach out. You earn points if it converts.':
      'हमारी टीम संपर्क करेगी। कन्वर्ट होने पर आपको पॉइंट्स मिलेंगे।',
  'Name and phone number are required': 'नाम और फोन नंबर ज़रूरी हैं',
  'Add another': 'एक और जोड़ें',
  'Pick how you want to order': 'चुनें कि आप कैसे ऑर्डर करना चाहते हैं',
  'Upload order image': 'ऑर्डर की फोटो अपलोड करें',
  'Snap or pick a photo': 'फोटो लें या चुनें',
  'Manual entry': 'हाथ से लिखें',
  'Add products and quantities': 'सामान और मात्रा जोड़ें',
  'Voice note': 'आवाज़',
  'Record your order by voice': 'अपना ऑर्डर आवाज़ में रिकॉर्ड करें',
  'Camera': 'कैमरा',
  'Gallery': 'गैलरी',
  'Remarks': 'टिप्पणी',
  'Remarks (optional)': 'टिप्पणी (वैकल्पिक)',
  'Submit order': 'ऑर्डर सबमिट करें',
  'Uploading...': 'अपलोड हो रहा है...',
  'Manual order': 'लिखकर ऑर्डर',
  'Product': 'सामान',
  'Products': 'सामान',
  'Qty': 'मात्रा',
  'Add product': 'सामान जोड़ें',
  'Add at least one product': 'कम से कम एक सामान जोड़ें',
  'Voice order': 'आवाज़ ऑर्डर',
  'Tap the mic and describe your order': 'माइक दबाएं और अपना ऑर्डर बताएं',
  'Recording...': 'रिकॉर्डिंग जारी है...',
  'Re-record': 'फिर से रिकॉर्ड करें',
  'Stop and submit': 'रोकें और सबमिट करें',
  'Order submitted': 'ऑर्डर सबमिट हो गया',
  'Order is now pending review. You will earn points once approved.':
      'ऑर्डर अब समीक्षा में है। अनुमोदन होने पर आपको पॉइंट्स मिलेंगे।',
  'View order': 'ऑर्डर देखें',
  'Order amount': 'ऑर्डर राशि',
  'Points to earn': 'अर्जित होने वाले पॉइंट्स',
  'Status timeline': 'स्टेटस टाइमलाइन',
  'View invoice': 'बिल देखें',
  'Download invoice': 'बिल डाउनलोड करें',
  'Back to orders': 'ऑर्डर पर वापस जाएं',
  'Back to order': 'ऑर्डर पर वापस जाएं',
  'No orders yet': 'अभी तक कोई ऑर्डर नहीं',
  'Could not display this order': 'यह ऑर्डर दिखाया नहीं जा सका',
  'Notifications': 'सूचनाएं',
  'Where we send your money': 'हम आपका पैसा कहां भेजें',
  'Scan to pay via UPI': 'यूपीआई से पे करने के लिए स्कैन करें',
  'Scan a UPI QR code': 'यूपीआई क्यूआर कोड स्कैन करें',
  'Scan QR code': 'क्यूआर कोड स्कैन करें',
  'Enter details manually instead': 'इसके बजाय खुद टाइप करें',
  'QR scanned': 'क्यूआर कोड स्कैन हो गया',
  'Could not read this QR code': 'यह क्यूआर कोड पढ़ा नहीं जा सका',
  'UPI ID': 'यूपीआई आईडी',
  'Bank': 'बैंक',
  'Account': 'खाता',
  'IFSC': 'IFSC कोड',
  '-- not set --': '-- सेट नहीं है --',
  'Change QR code': 'क्यूआर कोड बदलें',
  'Upload QR code': 'क्यूआर कोड अपलोड करें',
  'QR upload failed': 'क्यूआर कोड अपलोड नहीं हो सका',
  'Could not save': 'सेव नहीं हो सका',
  'Save bank/UPI details?': 'बैंक/यूपीआई विवरण सेव करें?',
  'These details are used to send your cash redemption payouts. Make sure they are correct.':
      'इन विवरणों का उपयोग आपके नकद भुगतान भेजने के लिए किया जाता है। सुनिश्चित करें कि ये सही हैं।',
  'Save': 'सेव करें',
  'Saving...': 'सेव हो रहा है...',
  'Account details saved': 'खाता विवरण सेव हो गया',
  'Add account details': 'खाता विवरण जोड़ें',
  'Points balance': 'पॉइंट्स बैलेंस',
  'Edit account details': 'खाता विवरण बदलें',
  'View profile': 'जानकारी देखें',
  'Bank and UPI details': 'बैंक और यूपीआई विवरण',
  'Last sync 2 min ago': 'पिछला सिंक 2 मिनट पहले',
  'Enabled': 'सक्षम',
  'Edit profile': 'जानकारी बदलें',
  'Save changes': 'बदलाव सेव करें',
  'Logout': 'लॉगआउट',
  'Are you sure you want to logout?': 'क्या आप वाकई लॉगआउट करना चाहते हैं?',
  'Language': 'भाषा',
  'Home': 'होम',
  'Orders': 'मेरे ऑर्डर',
  'Profile': 'मेरी जानकारी',
  'Pending': 'पेंडिंग',
  'On store': 'स्टोर पर',
  'In store': 'स्टोर पर',
  'Delivered': 'डिलीवर हो गया',
  'New': 'नया',
  'Contacted': 'संपर्क हुआ',
  'Qualified': 'योग्य पाया गया',
  'Converted': 'लीड सफल हुई',
  'Closed': 'बंद',
  'Processing': 'प्रक्रिया में',
  'Fulfilled': 'पूरा हुआ',
  'Dashboard': 'होम',
  'Upload profile photo': 'प्रोफाइल फोटो अपलोड करें',
  'Add photo': 'फोटो जोड़ें',
  'Change photo': 'फोटो बदलें',
  'Photo uploaded': 'फोटो अपलोड हो गई',
  'Photo upload failed': 'फोटो अपलोड नहीं हो सकी',
  'Fill all required fields': 'सभी ज़रूरी जानकारी भरें',
  'Aaj hi order dene me fayada': 'आज ही ऑर्डर देने में फायदा',
  'Is hafte order dene me fayada': 'इस हफ्ते ऑर्डर देने में फायदा',
  'Description': 'विवरण',
  'Latest update': 'नवीनतम अपडेट',
  'No notifications yet': 'अभी कोई सूचना नहीं',
  'See all notifications': 'सभी सूचनाएं देखें',
  'Font size': 'अक्षर आकार',
  'Small': 'छोटा',
  'Normal': 'सामान्य',
  'Large': 'बड़ा',
  'Extra large': 'अतिरिक्त बड़ा',
  'Confirm': 'पुष्टि करें',
  'Cancel': 'रद्द करें',
  'Use current location': 'मौजूदा लोकेशन उपयोग करें',
  'Location captured': 'लोकेशन कैप्चर हो गई',
  'Location services are off': 'लोकेशन सेवा बंद है',
  'Location permission denied': 'लोकेशन की अनुमति नहीं मिली',
  'Points earned': 'अर्जित पॉइंट्स',
  'Mark as delivered': 'डिलीवर हुआ चिह्नित करें',
  'I received this': 'मुझे यह मिल गया',
  'Play voice note': 'आवाज़ सुनें',
  'Stop': 'रोकें',
  'Submitted': 'सबमिट हुआ',
  'Order image': 'ऑर्डर फोटो',
  'View image': 'फोटो देखें',
  'Retry upload': 'फिर से अपलोड करें',
  'Submitting...': 'सबमिट हो रहा है...',
  'Recording... tap to stop': 'रिकॉर्डिंग जारी है... रोकने के लिए टैप करें',
  'Recording saved': 'रिकॉर्डिंग सेव हो गई',
  'Not recording': 'रिकॉर्डिंग नहीं हो रही',
  'No voice note for this order': 'इस ऑर्डर के लिए कोई आवाज़ रिकॉर्डिंग नहीं है',
  'Could not start recording': 'रिकॉर्डिंग शुरू नहीं हो सकी',
  'Could not play recording': 'रिकॉर्डिंग चलाई नहीं जा सकी',
  'Recording failed': 'रिकॉर्डिंग नहीं हो सकी',
  'Upload failed': 'अपलोड नहीं हो सका',
  'Could not submit order': 'ऑर्डर सबमिट नहीं हो सका',
  'Microphone permission denied': 'माइक्रोफ़ोन की अनुमति नहीं मिली',
  'Contacts permission denied': 'कॉन्टैक्ट्स की अनुमति नहीं मिली',
  'Pick from contacts': 'कॉन्टैक्ट्स से चुनें',
  'Speak now' : 'अब बोलें',
  'Listening...': 'सुन रहा है...',
  'Tap the mic and speak': 'माइक दबाएं और बोलें',
  'Could not hear that, try again': 'सुनाई नहीं दिया, फिर से कोशिश करें',
  'Speech input not available on this device': 'इस डिवाइस पर आवाज़ से टाइप करना उपलब्ध नहीं है',
  'Play instructions': 'निर्देश सुनें',
  'This is your home screen. You can see your points here. To place a new order, press the "Create order" button below.':
      'यह आपका होम स्क्रीन है। यहाँ आप अपने पॉइंट्स देख सकते हैं। नया ऑर्डर डालने के लिए नीचे "ऑर्डर बनाएं" बटन दबाएं।',
  'There are three ways to place an order: take a photo, write it yourself, or describe it by voice. Press whichever feels easiest.':
      'ऑर्डर देने के तीन तरीके हैं: फोटो खींचें, खुद लिखें, या आवाज़ में बताएं। जो आपको आसान लगे उसे दबाएं।',
  'This screen shows all your points and their history. To turn points into cash or a reward, press the buttons below.':
      'यह स्क्रीन आपके सारे पॉइंट्स और उनकी जानकारी दिखाती है। पॉइंट्स को नकद या इनाम में बदलने के लिए नीचे के बटन दबाएं।',
  'This screen shows your order\'s full details and status. You can recognize your order by the photo or icon at the top.':
      'यह स्क्रीन आपके ऑर्डर की पूरी जानकारी और स्टेटस दिखाती है। ऊपर की फोटो या आइकन देखकर आप अपना ऑर्डर पहचान सकते हैं।',
  'Your order has been submitted. You will earn points once it is reviewed.':
      'आपका ऑर्डर जमा हो गया है। समीक्षा के बाद आपको पॉइंट्स मिलेंगे।',
  'Get started': 'शुरू करें',
  'Order  ·  Earn points  ·  Redeem': 'ऑर्डर करें · पॉइंट्स कमाएं · भुनाएं',
  'Valid till {n}': '{n} तक मान्य',
  '₹{n} on the way': '₹{n} भेजा जा रहा है',
  '{n} points redeemed. Credited within 24 hrs.': '{n} पॉइंट्स भुनाए गए। 24 घंटे में आपके खाते में आ जाएंगे।',
  'We will notify you on each update.': 'हर अपडेट पर हम आपको बताएंगे।',
  'No leaderboard activity yet': 'अभी तक कोई लीडरबोर्ड गतिविधि नहीं',
  'Email': 'ईमेल',
  'Discard changes?': 'बदलाव छोड़ें?',
  "You have unsaved changes (including any uploaded photo) that will be lost if you don't tap 'Save changes'.":
      "आपके बदलाव (और कोई अपलोड की गई फोटो) सेव नहीं हुए हैं — 'बदलाव सेव करें' न दबाने पर ये खो जाएंगे।",
  'Keep editing': 'बदलाव जारी रखें',
  'Discard': 'छोड़ दें',
  'Name cannot be empty': 'नाम खाली नहीं हो सकता',
  "Photo uploaded — tap 'Save changes' below to apply it": "फोटो अपलोड हो गई — इसे लागू करने के लिए नीचे 'बदलाव सेव करें' दबाएं",
  'Update available': 'अपडेट उपलब्ध है',
  'Update now': 'अभी अपडेट करें',
  'Later': 'बाद में',
};

class AppLocale {
  AppLocale(this.isHindi);
  bool isHindi;

  String tr(String key) {
    if (!isHindi) return key;
    return hiStrings[key] ?? key;
  }

  /// Translates a template containing a single `{n}` placeholder, e.g.
  /// `trf('Rate: 1 point = 1 rupee. Min {n} pts', 500)`.
  String trf(String key, Object n) => tr(key).replaceAll('{n}', '$n');
}

/// Points-ledger `desc` and notification `title`/`body` text is written as
/// plain English by whichever backend created the event (admin_console's
/// approve/redeem actions, or this app's own redemption calls) and stored
/// verbatim in Firestore -- there's no per-language copy. Rather than bake
/// a language into stored data (which would leave old history stuck in
/// whatever language was active when it was written), these fixed
/// templates are recognized and translated at DISPLAY time instead.
/// Anything that doesn't match a known template (e.g. a custom message an
/// admin typed by hand) is left as-is.
String translateDynamicText(AppLocale locale, String text) {
  if (!locale.isHindi || text.isEmpty) return text;
  String trStatus(String s) => hiStrings[s] ?? s;

  final priceCorrected = RegExp(r'^Order #(.+) \(price corrected\)$').firstMatch(text);
  if (priceCorrected != null) return 'ऑर्डर #${priceCorrected.group(1)} (मूल्य में सुधार)';

  final order = RegExp(r'^Order #(.+)$').firstMatch(text);
  if (order != null) return 'ऑर्डर #${order.group(1)}';

  if (text == 'Points credited') return 'पॉइंट्स जमा हुए';

  final pointsForOrder = RegExp(r'^\+(\d+) points for your order$').firstMatch(text);
  if (pointsForOrder != null) return '+${pointsForOrder.group(1)} पॉइंट्स — आपके ऑर्डर के लिए';

  final pointsForLead = RegExp(r'^\+(\d+) points for your lead reaching (\w+)$').firstMatch(text);
  if (pointsForLead != null) return '+${pointsForLead.group(1)} पॉइंट्स — आपकी लीड ${trStatus(pointsForLead.group(2)!)} होने पर';

  if (text == 'New offer') return 'नया ऑफर';

  final offerLive = RegExp(r'^(.+) is now live!$').firstMatch(text);
  if (offerLive != null) return '${offerLive.group(1)} अभी उपलब्ध है!';

  if (text == 'Redemption update') return 'भुनाई अपडेट';

  final redemptionStatus = RegExp(r'^Your redemption status is now (.+)$').firstMatch(text);
  if (redemptionStatus != null) return 'आपकी भुनाई की स्थिति अब ${trStatus(redemptionStatus.group(1)!)} है';

  final leadBonus = RegExp(r'^Lead (\w+) bonus$').firstMatch(text);
  if (leadBonus != null) return '${trStatus(leadBonus.group(1)!)} लीड पर बोनस';

  final giftRedemption = RegExp(r'^Gift Redemption[:—]\s*(.+)$').firstMatch(text);
  if (giftRedemption != null) return 'इनाम भुनाया: ${giftRedemption.group(1)}';

  if (text == 'Redeemed as cash') return 'नकद के रूप में भुनाया गया';

  return text;
}
