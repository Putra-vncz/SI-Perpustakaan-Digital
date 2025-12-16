// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookingStatusAdapter extends TypeAdapter<BookingStatus> {
  @override
  final int typeId = 12;

  @override
  BookingStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BookingStatus.active;
      case 1:
        return BookingStatus.claimed;
      case 2:
        return BookingStatus.expired;
      case 3:
        return BookingStatus.cancelled;
      default:
        return BookingStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, BookingStatus obj) {
    switch (obj) {
      case BookingStatus.active:
        writer.writeByte(0);
        break;
      case BookingStatus.claimed:
        writer.writeByte(1);
        break;
      case BookingStatus.expired:
        writer.writeByte(2);
        break;
      case BookingStatus.cancelled:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
