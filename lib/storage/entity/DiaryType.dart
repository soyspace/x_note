enum DiaryType {
  //'Y'-年, 'M'-月, 'D'-日，'N'-笔记，'A'-附件
  Y,M,D,N,A;
  static DiaryType fromString(String value) {
    return DiaryType.values.firstWhere((element) => element.name == value);
  }
  String getName() {
    return name;
  }
}