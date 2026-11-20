import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // In-memory response cache shared by every screen for this app session.
  // Successful write requests clear it so changed data is fetched next time.
  static final Map<String, dynamic> _getCache = {};
  static final Map<String, Future<dynamic>> _pendingGets = {};
  static int _cacheGeneration = 0;

  static void clearCache() {
    _cacheGeneration++;
    _getCache.clear();
    _pendingGets.clear();
  }

  static const String baseUrl = 'https://script.google.com/macros/s/AKfycby8WDNL-Mvy34P04vw_zbkexLjE8OjqDIXVlP7HYS6Bq6R_v8SEqhLPx3sL0Q89YdvetQ/exec'; 

  static Future<dynamic> _getData(String action) async {
    if (_getCache.containsKey(action)) return _getCache[action];
    final pending = _pendingGets[action];
    if (pending != null) return pending;

    final requestGeneration = _cacheGeneration;
    final request = _fetchData(action);
    _pendingGets[action] = request;
    try {
      final result = await request;
      // Cache only valid responses. Permission/server/network errors must
      // remain retryable rather than being kept as stale cached values.
      if (requestGeneration == _cacheGeneration &&
          (result is! Map || !result.containsKey('error'))) {
        _getCache[action] = result;
      }
      return result;
    } finally {
      if (identical(_pendingGets[action], request)) {
        _pendingGets.remove(action);
      }
    }
  }

  static Future<dynamic> _fetchData(String action) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl?action=$action'));
      if (res.body.contains("<!DOCTYPE html>") || res.body.contains("<html>")) return {"error": "Permission Issue"};
      if (res.statusCode == 200) return jsonDecode(res.body);
      return {"error": "Server Error: ${res.statusCode}"};
    } catch (e) { return {"error": "Internet Issue: $e"}; }
  }

  static Future<Map<String, dynamic>> _postData(String action, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl?action=$action'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      
      if (res.statusCode == 302) {
        clearCache();
        return {"status": "success", "message": "Success (302)"};
      }
      if (res.body.contains("<!DOCTYPE html>") || res.body.contains("<html>")) return {"status": "error", "message": "Permission Issue"};
      
      if (res.statusCode == 200) {
        try {
          var decoded = jsonDecode(res.body);
          if (decoded is! Map || decoded['status'] != 'error') {
            clearCache();
          }
          return decoded;
        } catch (e) {
           clearCache();
           return {"status": "success", "message": "Success"};
        }
      }
      return {"status": "error", "message": "Server Error: ${res.statusCode}"};
    } catch (e) { return {"status": "error", "message": "Internet Issue: $e"}; }
  }

  static Future<dynamic> getAllMembers() => _getData("getAllMembers");
  static Future<Map<String, dynamic>> addMember({required String name, required String phone, required String email, required String pin, required String role, required String designation}) 
    => _postData("addMember", {"name": name, "phone": phone, "email": email, "pin": pin, "role": role, "designation": designation});
  static Future<Map<String, dynamic>> updateRole({required String phone, required String newRole}) 
    => _postData("updateRole", {"phone": phone, "newRole": newRole});
  static Future<Map<String, dynamic>> updateDesignation({required String phone, required String designation}) 
    => _postData("updateDesignation", {"phone": phone, "designation": designation});
  static Future<Map<String, dynamic>> updatePin({required String phone, required String newPin}) 
    => _postData("updatePin", {"phone": phone, "newPin": newPin});
  static Future<Map<String, dynamic>> updateProfilePic({required String phone, required String base64})
    => _postData("updateProfilePic", {"phone": phone, "base64": base64});
    
  static Future<dynamic> getTransactions() => _getData("getTransactions");
  static Future<Map<String, dynamic>> addTransaction({required String type, required String amount, required String note, required String memberName, required String status, required String date, required String paymentMethod}) 
    => _postData("addTransaction", {"type": type, "amount": amount, "note": note, "memberName": memberName, "status": status, "date": date, "paymentMethod": paymentMethod});
  static Future<Map<String, dynamic>> updateTransactionStatus({required String rowIndex, required String status})
    => _postData("updateTransactionStatus", {"rowIndex": rowIndex, "status": status});
  static Future<Map<String, dynamic>> generateAutoDue() => _postData("generateAutoDue", {});
  static Future<dynamic> getInvestments() => _getData("getInvestments");
  static Future<Map<String, dynamic>> addInvestment({required String sector, required String projectName, required String investAmount, required String startDate, required String endDate, required String profitAmount}) 
    => _postData("addInvestment", {"sector": sector, "projectName": projectName, "investAmount": investAmount, "startDate": startDate, "endDate": endDate, "profitAmount": profitAmount});
  static Future<Map<String, dynamic>> completeInvestment({required String rowIndex, required String profitAmount, required String completionDate, required String note}) 
    => _postData("completeInvestment", {"rowIndex": rowIndex, "profitAmount": profitAmount, "completionDate": completionDate, "note": note});
    

  // কিস্তিতে পণ্য: Google Sheets Backend API
  static Future<dynamic> getInstallmentData() => _getData("getInstallmentData");
  static Future<Map<String, dynamic>> saveInstallmentContract(Map<String, dynamic> data) => _postData("installmentSaveContract", data);
  static Future<Map<String, dynamic>> deleteInstallmentContract({required String contractId, required String actorPhone}) => _postData("installmentDeleteContract", {"contractId": contractId, "actorPhone": actorPhone});
  static Future<Map<String, dynamic>> addInstallmentPayment(Map<String, dynamic> data) => _postData("installmentAddPayment", data);
  static Future<Map<String, dynamic>> deleteInstallmentPayment({required String paymentId, required String actorPhone}) => _postData("installmentDeletePayment", {"paymentId": paymentId, "actorPhone": actorPhone});
  static Future<Map<String, dynamic>> saveInstallmentExpense(Map<String, dynamic> data) => _postData("installmentSaveExpense", data);
  static Future<Map<String, dynamic>> deleteInstallmentExpense({required String expenseId, required String actorPhone}) => _postData("installmentDeleteExpense", {"expenseId": expenseId, "actorPhone": actorPhone});

  // Meetings & Constitution
  static Future<dynamic> getMeetings() => _getData("getMeetings");
  static Future<Map<String, dynamic>> addMeeting({required String date, required String title, required String description}) 
    => _postData("addMeeting", {"date": date, "title": title, "description": description});
    
  static Future<dynamic> getConstitution() => _getData("getConstitution");
  static Future<Map<String, dynamic>> addConstitution({required String title, required String content}) 
    => _postData("addConstitution", {"title": title, "content": content});
    
  static Future<dynamic> getLateFees() => _getData("getLateFees");
}