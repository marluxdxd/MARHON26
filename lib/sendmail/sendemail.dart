import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> sendEmail({
  required String to,
  required String subject,
  required String text,
}) async {
  final url = Uri.parse(
    'https://fzllmarnhzdhleoqopsx.functions.supabase.co/sendEmail',
  );

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ6bGxtYXJuaHpkaGxlb3FvcHN4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwMDM5MjEsImV4cCI6MjA4MDU3OTkyMX0.t77W7a2Aw5PCMpXtYUBBwBVOqlvwsnNiXHDTmRtcavU', // <-- anon key
      },
      body: jsonEncode({
        'to': to,
        'subject': subject,
        'text': text,
      }),
    );

    if (response.statusCode == 200) {
      print('Email sent successfully!');
    } else {
      print('Failed to send email: ${response.body}');
    }
  } catch (e) {
    print('Error sending email: $e');
  }
}