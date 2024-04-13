import 'dart:convert';
import 'package:http/http.dart' as http;

class DataFetcher {
  // Function to fetch JSON data
  static Future<dynamic> getJSON(String url, {Map<String, String>? headers}) async {
    try {
      var response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Handle error
        print('Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {
      // Handle exception
      print('Error: $e');

      return null;
    }
  }

}
