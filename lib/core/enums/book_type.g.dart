// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookTypeAdapter extends TypeAdapter<BookType> {
  @override
  final int typeId = 11;

  @override
  BookType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BookType.physical;
      case 1:
        return BookType.ebook;
      default:
        return BookType.physical;
    }
  }

  @override
  void write(BinaryWriter writer, BookType obj) {
    switch (obj) {
      case BookType.physical:
        writer.writeByte(0);
        break;
      case BookType.ebook:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
