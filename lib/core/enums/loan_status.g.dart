// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoanStatusAdapter extends TypeAdapter<LoanStatus> {
  @override
  final int typeId = 13;

  @override
  LoanStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LoanStatus.active;
      case 1:
        return LoanStatus.returned;
      case 2:
        return LoanStatus.overdue;
      case 3:
        return LoanStatus.pendingReturn;
      default:
        return LoanStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, LoanStatus obj) {
    switch (obj) {
      case LoanStatus.active:
        writer.writeByte(0);
        break;
      case LoanStatus.returned:
        writer.writeByte(1);
        break;
      case LoanStatus.overdue:
        writer.writeByte(2);
        break;
      case LoanStatus.pendingReturn:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
