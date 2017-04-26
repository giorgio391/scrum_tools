
abstract class PersistedData {
  String get author;
  DateTime get timestamp;
  Map<String, dynamic> get data;
}

abstract class RepositorySync {

  PersistedData save(String key, Map<String, dynamic> data, [String author]);
  PersistedData get(String key);
  PersistedData delete(String key, [String author]);
  PersistedData operator[] (String key);

}
