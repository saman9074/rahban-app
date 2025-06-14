// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_packet.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflinePacketAdapter extends TypeAdapter<OfflinePacket> {
  @override
  final int typeId = 0;

  @override
  OfflinePacket read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflinePacket(
      tripId: fields[0] as String,
      encryptedData: fields[1] as String,
      tripStatusValue: fields[2] as int,
      timestamp: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, OfflinePacket obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.tripId)
      ..writeByte(1)
      ..write(obj.encryptedData)
      ..writeByte(2)
      ..write(obj.tripStatusValue)
      ..writeByte(3)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflinePacketAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
