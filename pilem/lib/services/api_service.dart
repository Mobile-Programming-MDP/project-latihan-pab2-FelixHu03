import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://api.themoviedb.org/3";
  static const String apiKey = '26c5b95fcb664bbf00f1762455c6c749';
  // untuk mengambil film mana yang lagi ada
  Future<List<Map<String, dynamic>>> getAllMovies() async{
    final response =  await http.get(Uri.parse("$baseUrl/movie/now_playing?api_key=$apiKey"));
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['results']);
  }
  // untuk mengambil data film yang sedang trending pada minggu ini
  Future<List<Map<String,dynamic>>> getTrendingMovie() async{
    final response = await http.get(Uri.parse("$baseUrl/trending/movie/week?api_key=$apiKey"));
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['results']);
  }
  // untuk mengambil data film yang popular
  Future<List<Map<String,dynamic>>> getPopularMovie() async{
    final response = await http.get(Uri.parse("$baseUrl/movie/popular?api_key=$apiKey"));
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['results']);
  }
  // untuk Mencari movie
  Future<List<Map<String,dynamic>>> searchMovie (String query) async{
    final response = await http.get(Uri.parse("$baseUrl/search/movie?query=$query&api_key=$apiKey"));
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['results']);
  }
}