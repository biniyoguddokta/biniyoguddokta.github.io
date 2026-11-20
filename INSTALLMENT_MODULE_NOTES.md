# কিস্তিতে পণ্য — Google Sheets Backend সংযোগ

## সংযুক্ত ফিচার
- Dashboard-এর `কিস্তিতে পণ্য` টাইল থেকে মডিউল খোলে; আগের Investment মডিউল অপরিবর্তিত।
- `ApiService`-এ `getInstallmentData`, contract create/update/delete, payment add/delete এবং expense add/delete endpoint যুক্ত।
- কিস্তির চুক্তি, ক্রেতা, পণ্য, পেমেন্ট ও ব্যয়ের তথ্য Google Apps Script API দিয়ে Google Sheets-এ সংরক্ষণ/লোড হয়; এই মডিউলের নতুন তথ্য আর SharedPreferences-এ সংরক্ষণ হয় না।
- ক্রেতার ধরন: বিদ্যমান সদস্য অথবা বাইরের নতুন ক্রেতা। বিদ্যমান সদস্য বেছে নিলে সদস্য তালিকা থেকে নাম/ফোন বসে।
- জামিনদারের নাম ও ফোন, ঠিকানা, পণ্যের ক্রয়/বিক্রয়মূল্য, মেয়াদ, ডাউনপেমেন্ট ও শুরুর তারিখসহ চুক্তি।
- কিস্তি আদায়, আদায়ের ইতিহাস, বকেয়া হিসাব, মাসভিত্তিক আদায়, ব্যবসায়িক অতিরিক্ত ব্যয় যোগ/মুছা এবং আয়-ব্যয়ের সারাংশ।
- সফল write-এর পর API cache clear করে সার্ভার থেকে নতুন তথ্য লোড হয়।
- GitHub Actions workflow Java 21 ব্যবহার করে।

## প্রয়োজনীয় Backend
Google Apps Script-এ `getInstallmentData`, `installmentSaveContract`, `installmentDeleteContract`, `installmentAddPayment`, `installmentDeletePayment`, `installmentSaveExpense`, `installmentDeleteExpense` action থাকতে হবে এবং পাঁচটি Installment sheet তৈরি থাকতে হবে। App-এর `ApiService.baseUrl` অবশ্যই সক্রিয় Web App deployment URL হতে হবে।

## গুরুত্বপূর্ণ নিরাপত্তা সীমাবদ্ধতা
বর্তমান Apps Script কোডে Admin যাচাই `actorPhone` request field-এর ওপর নির্ভর করে। এটি প্রকৃত authentication নয়—কেউ API request তৈরি করে অন্য Admin-এর ফোন নম্বর পাঠাতে পারে। পাশাপাশি `getInstallmentData`-এ server-side user authorization নেই। তাই এই Backend-কে বাস্তব গ্রাহকের সংবেদনশীল তথ্যসহ প্রকাশ্যে ব্যবহারের আগে server-side authentication/authorization যোগ করা আবশ্যক।

## যাচাইয়ের অবস্থা
- API action ও field mapping source-level review করা হয়েছে।
- Dart/Flutter SDK এই কাজের পরিবেশে পাওয়া যায়নি; তাই `flutter analyze`, APK build বা ফোনে live API CRUD পরীক্ষা করা হয়নি। GitHub Actions build এবং test data দিয়ে create/edit/payment/delete/expense পরীক্ষা আবশ্যক।
