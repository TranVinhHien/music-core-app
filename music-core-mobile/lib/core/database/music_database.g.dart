// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_database.dart';

// ignore_for_file: type=lint
class $LocalTracksTable extends LocalTracks
    with TableInfo<$LocalTracksTable, LocalTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistNameMeta = const VerificationMeta(
    'artistName',
  );
  @override
  late final GeneratedColumn<String> artistName = GeneratedColumn<String>(
    'artist_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumTitleMeta = const VerificationMeta(
    'albumTitle',
  );
  @override
  late final GeneratedColumn<String> albumTitle = GeneratedColumn<String>(
    'album_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverImageUrlMeta = const VerificationMeta(
    'coverImageUrl',
  );
  @override
  late final GeneratedColumn<String> coverImageUrl = GeneratedColumn<String>(
    'cover_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileUrlMeta = const VerificationMeta(
    'fileUrl',
  );
  @override
  late final GeneratedColumn<String> fileUrl = GeneratedColumn<String>(
    'file_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDownloadedMeta = const VerificationMeta(
    'isDownloaded',
  );
  @override
  late final GeneratedColumn<bool> isDownloaded = GeneratedColumn<bool>(
    'is_downloaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_downloaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _localFilePathMeta = const VerificationMeta(
    'localFilePath',
  );
  @override
  late final GeneratedColumn<String> localFilePath = GeneratedColumn<String>(
    'local_file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta(
    'fileSizeBytes',
  );
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    artistName,
    albumTitle,
    durationMs,
    coverImageUrl,
    fileUrl,
    isDownloaded,
    localFilePath,
    fileSizeBytes,
    downloadedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTrack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist_name')) {
      context.handle(
        _artistNameMeta,
        artistName.isAcceptableOrUnknown(data['artist_name']!, _artistNameMeta),
      );
    } else if (isInserting) {
      context.missing(_artistNameMeta);
    }
    if (data.containsKey('album_title')) {
      context.handle(
        _albumTitleMeta,
        albumTitle.isAcceptableOrUnknown(data['album_title']!, _albumTitleMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('cover_image_url')) {
      context.handle(
        _coverImageUrlMeta,
        coverImageUrl.isAcceptableOrUnknown(
          data['cover_image_url']!,
          _coverImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('file_url')) {
      context.handle(
        _fileUrlMeta,
        fileUrl.isAcceptableOrUnknown(data['file_url']!, _fileUrlMeta),
      );
    }
    if (data.containsKey('is_downloaded')) {
      context.handle(
        _isDownloadedMeta,
        isDownloaded.isAcceptableOrUnknown(
          data['is_downloaded']!,
          _isDownloadedMeta,
        ),
      );
    }
    if (data.containsKey('local_file_path')) {
      context.handle(
        _localFilePathMeta,
        localFilePath.isAcceptableOrUnknown(
          data['local_file_path']!,
          _localFilePathMeta,
        ),
      );
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(
          data['file_size_bytes']!,
          _fileSizeBytesMeta,
        ),
      );
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTrack(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artistName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_name'],
      )!,
      albumTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_title'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      coverImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_image_url'],
      ),
      fileUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_url'],
      ),
      isDownloaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_downloaded'],
      )!,
      localFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_file_path'],
      ),
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size_bytes'],
      ),
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalTracksTable createAlias(String alias) {
    return $LocalTracksTable(attachedDatabase, alias);
  }
}

class LocalTrack extends DataClass implements Insertable<LocalTrack> {
  final String id;
  final String title;
  final String artistName;
  final String? albumTitle;
  final int? durationMs;
  final String? coverImageUrl;
  final String? fileUrl;
  final bool isDownloaded;
  final String? localFilePath;
  final int? fileSizeBytes;
  final DateTime? downloadedAt;
  final DateTime updatedAt;
  const LocalTrack({
    required this.id,
    required this.title,
    required this.artistName,
    this.albumTitle,
    this.durationMs,
    this.coverImageUrl,
    this.fileUrl,
    required this.isDownloaded,
    this.localFilePath,
    this.fileSizeBytes,
    this.downloadedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['artist_name'] = Variable<String>(artistName);
    if (!nullToAbsent || albumTitle != null) {
      map['album_title'] = Variable<String>(albumTitle);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || coverImageUrl != null) {
      map['cover_image_url'] = Variable<String>(coverImageUrl);
    }
    if (!nullToAbsent || fileUrl != null) {
      map['file_url'] = Variable<String>(fileUrl);
    }
    map['is_downloaded'] = Variable<bool>(isDownloaded);
    if (!nullToAbsent || localFilePath != null) {
      map['local_file_path'] = Variable<String>(localFilePath);
    }
    if (!nullToAbsent || fileSizeBytes != null) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    }
    if (!nullToAbsent || downloadedAt != null) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  factory LocalTrack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTrack(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      artistName: serializer.fromJson<String>(json['artistName']),
      albumTitle: serializer.fromJson<String?>(json['albumTitle']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      coverImageUrl: serializer.fromJson<String?>(json['coverImageUrl']),
      fileUrl: serializer.fromJson<String?>(json['fileUrl']),
      isDownloaded: serializer.fromJson<bool>(json['isDownloaded']),
      localFilePath: serializer.fromJson<String?>(json['localFilePath']),
      fileSizeBytes: serializer.fromJson<int?>(json['fileSizeBytes']),
      downloadedAt: serializer.fromJson<DateTime?>(json['downloadedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'artistName': serializer.toJson<String>(artistName),
      'albumTitle': serializer.toJson<String?>(albumTitle),
      'durationMs': serializer.toJson<int?>(durationMs),
      'coverImageUrl': serializer.toJson<String?>(coverImageUrl),
      'fileUrl': serializer.toJson<String?>(fileUrl),
      'isDownloaded': serializer.toJson<bool>(isDownloaded),
      'localFilePath': serializer.toJson<String?>(localFilePath),
      'fileSizeBytes': serializer.toJson<int?>(fileSizeBytes),
      'downloadedAt': serializer.toJson<DateTime?>(downloadedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalTrack copyWith({
    String? id,
    String? title,
    String? artistName,
    Value<String?> albumTitle = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    Value<String?> coverImageUrl = const Value.absent(),
    Value<String?> fileUrl = const Value.absent(),
    bool? isDownloaded,
    Value<String?> localFilePath = const Value.absent(),
    Value<int?> fileSizeBytes = const Value.absent(),
    Value<DateTime?> downloadedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => LocalTrack(
    id: id ?? this.id,
    title: title ?? this.title,
    artistName: artistName ?? this.artistName,
    albumTitle: albumTitle.present ? albumTitle.value : this.albumTitle,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    coverImageUrl: coverImageUrl.present
        ? coverImageUrl.value
        : this.coverImageUrl,
    fileUrl: fileUrl.present ? fileUrl.value : this.fileUrl,
    isDownloaded: isDownloaded ?? this.isDownloaded,
    localFilePath: localFilePath.present
        ? localFilePath.value
        : this.localFilePath,
    fileSizeBytes: fileSizeBytes.present
        ? fileSizeBytes.value
        : this.fileSizeBytes,
    downloadedAt: downloadedAt.present ? downloadedAt.value : this.downloadedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalTrack copyWithCompanion(LocalTracksCompanion data) {
    return LocalTrack(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      artistName: data.artistName.present
          ? data.artistName.value
          : this.artistName,
      albumTitle: data.albumTitle.present
          ? data.albumTitle.value
          : this.albumTitle,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      coverImageUrl: data.coverImageUrl.present
          ? data.coverImageUrl.value
          : this.coverImageUrl,
      fileUrl: data.fileUrl.present ? data.fileUrl.value : this.fileUrl,
      isDownloaded: data.isDownloaded.present
          ? data.isDownloaded.value
          : this.isDownloaded,
      localFilePath: data.localFilePath.present
          ? data.localFilePath.value
          : this.localFilePath,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTrack(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artistName: $artistName, ')
          ..write('albumTitle: $albumTitle, ')
          ..write('durationMs: $durationMs, ')
          ..write('coverImageUrl: $coverImageUrl, ')
          ..write('fileUrl: $fileUrl, ')
          ..write('isDownloaded: $isDownloaded, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    artistName,
    albumTitle,
    durationMs,
    coverImageUrl,
    fileUrl,
    isDownloaded,
    localFilePath,
    fileSizeBytes,
    downloadedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTrack &&
          other.id == this.id &&
          other.title == this.title &&
          other.artistName == this.artistName &&
          other.albumTitle == this.albumTitle &&
          other.durationMs == this.durationMs &&
          other.coverImageUrl == this.coverImageUrl &&
          other.fileUrl == this.fileUrl &&
          other.isDownloaded == this.isDownloaded &&
          other.localFilePath == this.localFilePath &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.downloadedAt == this.downloadedAt &&
          other.updatedAt == this.updatedAt);
}

class LocalTracksCompanion extends UpdateCompanion<LocalTrack> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> artistName;
  final Value<String?> albumTitle;
  final Value<int?> durationMs;
  final Value<String?> coverImageUrl;
  final Value<String?> fileUrl;
  final Value<bool> isDownloaded;
  final Value<String?> localFilePath;
  final Value<int?> fileSizeBytes;
  final Value<DateTime?> downloadedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalTracksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.artistName = const Value.absent(),
    this.albumTitle = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.coverImageUrl = const Value.absent(),
    this.fileUrl = const Value.absent(),
    this.isDownloaded = const Value.absent(),
    this.localFilePath = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTracksCompanion.insert({
    required String id,
    required String title,
    required String artistName,
    this.albumTitle = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.coverImageUrl = const Value.absent(),
    this.fileUrl = const Value.absent(),
    this.isDownloaded = const Value.absent(),
    this.localFilePath = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       artistName = Value(artistName);
  static Insertable<LocalTrack> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? artistName,
    Expression<String>? albumTitle,
    Expression<int>? durationMs,
    Expression<String>? coverImageUrl,
    Expression<String>? fileUrl,
    Expression<bool>? isDownloaded,
    Expression<String>? localFilePath,
    Expression<int>? fileSizeBytes,
    Expression<DateTime>? downloadedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (artistName != null) 'artist_name': artistName,
      if (albumTitle != null) 'album_title': albumTitle,
      if (durationMs != null) 'duration_ms': durationMs,
      if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
      if (fileUrl != null) 'file_url': fileUrl,
      if (isDownloaded != null) 'is_downloaded': isDownloaded,
      if (localFilePath != null) 'local_file_path': localFilePath,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTracksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? artistName,
    Value<String?>? albumTitle,
    Value<int?>? durationMs,
    Value<String?>? coverImageUrl,
    Value<String?>? fileUrl,
    Value<bool>? isDownloaded,
    Value<String?>? localFilePath,
    Value<int?>? fileSizeBytes,
    Value<DateTime?>? downloadedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalTracksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      albumTitle: albumTitle ?? this.albumTitle,
      durationMs: durationMs ?? this.durationMs,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localFilePath: localFilePath ?? this.localFilePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artistName.present) {
      map['artist_name'] = Variable<String>(artistName.value);
    }
    if (albumTitle.present) {
      map['album_title'] = Variable<String>(albumTitle.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (coverImageUrl.present) {
      map['cover_image_url'] = Variable<String>(coverImageUrl.value);
    }
    if (fileUrl.present) {
      map['file_url'] = Variable<String>(fileUrl.value);
    }
    if (isDownloaded.present) {
      map['is_downloaded'] = Variable<bool>(isDownloaded.value);
    }
    if (localFilePath.present) {
      map['local_file_path'] = Variable<String>(localFilePath.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTracksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artistName: $artistName, ')
          ..write('albumTitle: $albumTitle, ')
          ..write('durationMs: $durationMs, ')
          ..write('coverImageUrl: $coverImageUrl, ')
          ..write('fileUrl: $fileUrl, ')
          ..write('isDownloaded: $isDownloaded, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPlaylistsTable extends LocalPlaylists
    with TableInfo<$LocalPlaylistsTable, LocalPlaylist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverImageUrlMeta = const VerificationMeta(
    'coverImageUrl',
  );
  @override
  late final GeneratedColumn<String> coverImageUrl = GeneratedColumn<String>(
    'cover_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visibilityMeta = const VerificationMeta(
    'visibility',
  );
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
    'visibility',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PRIVATE'),
  );
  static const VerificationMeta _tracksCountMeta = const VerificationMeta(
    'tracksCount',
  );
  @override
  late final GeneratedColumn<int> tracksCount = GeneratedColumn<int>(
    'tracks_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    description,
    coverImageUrl,
    visibility,
    tracksCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPlaylist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('cover_image_url')) {
      context.handle(
        _coverImageUrlMeta,
        coverImageUrl.isAcceptableOrUnknown(
          data['cover_image_url']!,
          _coverImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('visibility')) {
      context.handle(
        _visibilityMeta,
        visibility.isAcceptableOrUnknown(data['visibility']!, _visibilityMeta),
      );
    }
    if (data.containsKey('tracks_count')) {
      context.handle(
        _tracksCountMeta,
        tracksCount.isAcceptableOrUnknown(
          data['tracks_count']!,
          _tracksCountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPlaylist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPlaylist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      coverImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_image_url'],
      ),
      visibility: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visibility'],
      )!,
      tracksCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tracks_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalPlaylistsTable createAlias(String alias) {
    return $LocalPlaylistsTable(attachedDatabase, alias);
  }
}

class LocalPlaylist extends DataClass implements Insertable<LocalPlaylist> {
  final String id;
  final String? userId;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final String visibility;
  final int tracksCount;
  final DateTime? createdAt;
  final DateTime updatedAt;
  const LocalPlaylist({
    required this.id,
    this.userId,
    required this.name,
    this.description,
    this.coverImageUrl,
    required this.visibility,
    required this.tracksCount,
    this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || coverImageUrl != null) {
      map['cover_image_url'] = Variable<String>(coverImageUrl);
    }
    map['visibility'] = Variable<String>(visibility);
    map['tracks_count'] = Variable<int>(tracksCount);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  factory LocalPlaylist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPlaylist(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      coverImageUrl: serializer.fromJson<String?>(json['coverImageUrl']),
      visibility: serializer.fromJson<String>(json['visibility']),
      tracksCount: serializer.fromJson<int>(json['tracksCount']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'coverImageUrl': serializer.toJson<String?>(coverImageUrl),
      'visibility': serializer.toJson<String>(visibility),
      'tracksCount': serializer.toJson<int>(tracksCount),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalPlaylist copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> coverImageUrl = const Value.absent(),
    String? visibility,
    int? tracksCount,
    Value<DateTime?> createdAt = const Value.absent(),
    DateTime? updatedAt,
  }) => LocalPlaylist(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    coverImageUrl: coverImageUrl.present
        ? coverImageUrl.value
        : this.coverImageUrl,
    visibility: visibility ?? this.visibility,
    tracksCount: tracksCount ?? this.tracksCount,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalPlaylist copyWithCompanion(LocalPlaylistsCompanion data) {
    return LocalPlaylist(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      coverImageUrl: data.coverImageUrl.present
          ? data.coverImageUrl.value
          : this.coverImageUrl,
      visibility: data.visibility.present
          ? data.visibility.value
          : this.visibility,
      tracksCount: data.tracksCount.present
          ? data.tracksCount.value
          : this.tracksCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylist(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('coverImageUrl: $coverImageUrl, ')
          ..write('visibility: $visibility, ')
          ..write('tracksCount: $tracksCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    description,
    coverImageUrl,
    visibility,
    tracksCount,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlaylist &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.description == this.description &&
          other.coverImageUrl == this.coverImageUrl &&
          other.visibility == this.visibility &&
          other.tracksCount == this.tracksCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalPlaylistsCompanion extends UpdateCompanion<LocalPlaylist> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> coverImageUrl;
  final Value<String> visibility;
  final Value<int> tracksCount;
  final Value<DateTime?> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalPlaylistsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.coverImageUrl = const Value.absent(),
    this.visibility = const Value.absent(),
    this.tracksCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPlaylistsCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.coverImageUrl = const Value.absent(),
    this.visibility = const Value.absent(),
    this.tracksCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<LocalPlaylist> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? coverImageUrl,
    Expression<String>? visibility,
    Expression<int>? tracksCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
      if (visibility != null) 'visibility': visibility,
      if (tracksCount != null) 'tracks_count': tracksCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPlaylistsCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? coverImageUrl,
    Value<String>? visibility,
    Value<int>? tracksCount,
    Value<DateTime?>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalPlaylistsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      visibility: visibility ?? this.visibility,
      tracksCount: tracksCount ?? this.tracksCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (coverImageUrl.present) {
      map['cover_image_url'] = Variable<String>(coverImageUrl.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (tracksCount.present) {
      map['tracks_count'] = Variable<int>(tracksCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('coverImageUrl: $coverImageUrl, ')
          ..write('visibility: $visibility, ')
          ..write('tracksCount: $tracksCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPlaylistTracksTable extends LocalPlaylistTracks
    with TableInfo<$LocalPlaylistTracksTable, LocalPlaylistTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPlaylistTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [playlistId, trackId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_playlist_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPlaylistTrack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId, trackId};
  @override
  LocalPlaylistTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPlaylistTrack(
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $LocalPlaylistTracksTable createAlias(String alias) {
    return $LocalPlaylistTracksTable(attachedDatabase, alias);
  }
}

class LocalPlaylistTrack extends DataClass
    implements Insertable<LocalPlaylistTrack> {
  final String playlistId;
  final String trackId;
  final int position;
  const LocalPlaylistTrack({
    required this.playlistId,
    required this.trackId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<String>(playlistId);
    map['track_id'] = Variable<String>(trackId);
    map['position'] = Variable<int>(position);
    return map;
  }

  factory LocalPlaylistTrack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPlaylistTrack(
      playlistId: serializer.fromJson<String>(json['playlistId']),
      trackId: serializer.fromJson<String>(json['trackId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<String>(playlistId),
      'trackId': serializer.toJson<String>(trackId),
      'position': serializer.toJson<int>(position),
    };
  }

  LocalPlaylistTrack copyWith({
    String? playlistId,
    String? trackId,
    int? position,
  }) => LocalPlaylistTrack(
    playlistId: playlistId ?? this.playlistId,
    trackId: trackId ?? this.trackId,
    position: position ?? this.position,
  );
  LocalPlaylistTrack copyWithCompanion(LocalPlaylistTracksCompanion data) {
    return LocalPlaylistTrack(
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylistTrack(')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistId, trackId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlaylistTrack &&
          other.playlistId == this.playlistId &&
          other.trackId == this.trackId &&
          other.position == this.position);
}

class LocalPlaylistTracksCompanion extends UpdateCompanion<LocalPlaylistTrack> {
  final Value<String> playlistId;
  final Value<String> trackId;
  final Value<int> position;
  final Value<int> rowid;
  const LocalPlaylistTracksCompanion({
    this.playlistId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPlaylistTracksCompanion.insert({
    required String playlistId,
    required String trackId,
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       trackId = Value(trackId);
  static Insertable<LocalPlaylistTrack> custom({
    Expression<String>? playlistId,
    Expression<String>? trackId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (trackId != null) 'track_id': trackId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPlaylistTracksCompanion copyWith({
    Value<String>? playlistId,
    Value<String>? trackId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return LocalPlaylistTracksCompanion(
      playlistId: playlistId ?? this.playlistId,
      trackId: trackId ?? this.trackId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylistTracksCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalFavoritesTable extends LocalFavorites
    with TableInfo<$LocalFavoritesTable, LocalFavorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalFavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [trackId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalFavorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId};
  @override
  LocalFavorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalFavorite(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $LocalFavoritesTable createAlias(String alias) {
    return $LocalFavoritesTable(attachedDatabase, alias);
  }
}

class LocalFavorite extends DataClass implements Insertable<LocalFavorite> {
  final String trackId;
  final DateTime addedAt;
  const LocalFavorite({required this.trackId, required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<String>(trackId);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  factory LocalFavorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalFavorite(
      trackId: serializer.fromJson<String>(json['trackId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<String>(trackId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  LocalFavorite copyWith({String? trackId, DateTime? addedAt}) => LocalFavorite(
    trackId: trackId ?? this.trackId,
    addedAt: addedAt ?? this.addedAt,
  );
  LocalFavorite copyWithCompanion(LocalFavoritesCompanion data) {
    return LocalFavorite(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalFavorite(')
          ..write('trackId: $trackId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(trackId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalFavorite &&
          other.trackId == this.trackId &&
          other.addedAt == this.addedAt);
}

class LocalFavoritesCompanion extends UpdateCompanion<LocalFavorite> {
  final Value<String> trackId;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const LocalFavoritesCompanion({
    this.trackId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalFavoritesCompanion.insert({
    required String trackId,
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : trackId = Value(trackId);
  static Insertable<LocalFavorite> custom({
    Expression<String>? trackId,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalFavoritesCompanion copyWith({
    Value<String>? trackId,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return LocalFavoritesCompanion(
      trackId: trackId ?? this.trackId,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalFavoritesCompanion(')
          ..write('trackId: $trackId, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingEventsTable extends PendingEvents
    with TableInfo<$PendingEventsTable, PendingEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceJsonMeta = const VerificationMeta(
    'sourceJson',
  );
  @override
  late final GeneratedColumn<String> sourceJson = GeneratedColumn<String>(
    'source_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _propertiesJsonMeta = const VerificationMeta(
    'propertiesJson',
  );
  @override
  late final GeneratedColumn<String> propertiesJson = GeneratedColumn<String>(
    'properties_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    eventId,
    eventType,
    occurredAt,
    sessionId,
    trackId,
    sourceJson,
    propertiesJson,
    schemaVersion,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    }
    if (data.containsKey('source_json')) {
      context.handle(
        _sourceJsonMeta,
        sourceJson.isAcceptableOrUnknown(data['source_json']!, _sourceJsonMeta),
      );
    }
    if (data.containsKey('properties_json')) {
      context.handle(
        _propertiesJsonMeta,
        propertiesJson.isAcceptableOrUnknown(
          data['properties_json']!,
          _propertiesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_propertiesJsonMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  PendingEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingEvent(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      ),
      sourceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_json'],
      ),
      propertiesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}properties_json'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingEventsTable createAlias(String alias) {
    return $PendingEventsTable(attachedDatabase, alias);
  }
}

class PendingEvent extends DataClass implements Insertable<PendingEvent> {
  final String eventId;
  final String eventType;
  final DateTime occurredAt;
  final String? sessionId;
  final String? trackId;
  final String? sourceJson;
  final String propertiesJson;
  final int schemaVersion;
  final DateTime createdAt;
  const PendingEvent({
    required this.eventId,
    required this.eventType,
    required this.occurredAt,
    this.sessionId,
    this.trackId,
    this.sourceJson,
    required this.propertiesJson,
    required this.schemaVersion,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['event_type'] = Variable<String>(eventType);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    if (!nullToAbsent || trackId != null) {
      map['track_id'] = Variable<String>(trackId);
    }
    if (!nullToAbsent || sourceJson != null) {
      map['source_json'] = Variable<String>(sourceJson);
    }
    map['properties_json'] = Variable<String>(propertiesJson);
    map['schema_version'] = Variable<int>(schemaVersion);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  factory PendingEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingEvent(
      eventId: serializer.fromJson<String>(json['eventId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      trackId: serializer.fromJson<String?>(json['trackId']),
      sourceJson: serializer.fromJson<String?>(json['sourceJson']),
      propertiesJson: serializer.fromJson<String>(json['propertiesJson']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'eventType': serializer.toJson<String>(eventType),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'sessionId': serializer.toJson<String?>(sessionId),
      'trackId': serializer.toJson<String?>(trackId),
      'sourceJson': serializer.toJson<String?>(sourceJson),
      'propertiesJson': serializer.toJson<String>(propertiesJson),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingEvent copyWith({
    String? eventId,
    String? eventType,
    DateTime? occurredAt,
    Value<String?> sessionId = const Value.absent(),
    Value<String?> trackId = const Value.absent(),
    Value<String?> sourceJson = const Value.absent(),
    String? propertiesJson,
    int? schemaVersion,
    DateTime? createdAt,
  }) => PendingEvent(
    eventId: eventId ?? this.eventId,
    eventType: eventType ?? this.eventType,
    occurredAt: occurredAt ?? this.occurredAt,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    trackId: trackId.present ? trackId.value : this.trackId,
    sourceJson: sourceJson.present ? sourceJson.value : this.sourceJson,
    propertiesJson: propertiesJson ?? this.propertiesJson,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingEvent copyWithCompanion(PendingEventsCompanion data) {
    return PendingEvent(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      sourceJson: data.sourceJson.present
          ? data.sourceJson.value
          : this.sourceJson,
      propertiesJson: data.propertiesJson.present
          ? data.propertiesJson.value
          : this.propertiesJson,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingEvent(')
          ..write('eventId: $eventId, ')
          ..write('eventType: $eventType, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('sessionId: $sessionId, ')
          ..write('trackId: $trackId, ')
          ..write('sourceJson: $sourceJson, ')
          ..write('propertiesJson: $propertiesJson, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    eventId,
    eventType,
    occurredAt,
    sessionId,
    trackId,
    sourceJson,
    propertiesJson,
    schemaVersion,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingEvent &&
          other.eventId == this.eventId &&
          other.eventType == this.eventType &&
          other.occurredAt == this.occurredAt &&
          other.sessionId == this.sessionId &&
          other.trackId == this.trackId &&
          other.sourceJson == this.sourceJson &&
          other.propertiesJson == this.propertiesJson &&
          other.schemaVersion == this.schemaVersion &&
          other.createdAt == this.createdAt);
}

class PendingEventsCompanion extends UpdateCompanion<PendingEvent> {
  final Value<String> eventId;
  final Value<String> eventType;
  final Value<DateTime> occurredAt;
  final Value<String?> sessionId;
  final Value<String?> trackId;
  final Value<String?> sourceJson;
  final Value<String> propertiesJson;
  final Value<int> schemaVersion;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PendingEventsCompanion({
    this.eventId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.sourceJson = const Value.absent(),
    this.propertiesJson = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingEventsCompanion.insert({
    required String eventId,
    required String eventType,
    required DateTime occurredAt,
    this.sessionId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.sourceJson = const Value.absent(),
    required String propertiesJson,
    this.schemaVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       eventType = Value(eventType),
       occurredAt = Value(occurredAt),
       propertiesJson = Value(propertiesJson);
  static Insertable<PendingEvent> custom({
    Expression<String>? eventId,
    Expression<String>? eventType,
    Expression<DateTime>? occurredAt,
    Expression<String>? sessionId,
    Expression<String>? trackId,
    Expression<String>? sourceJson,
    Expression<String>? propertiesJson,
    Expression<int>? schemaVersion,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (eventType != null) 'event_type': eventType,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (sessionId != null) 'session_id': sessionId,
      if (trackId != null) 'track_id': trackId,
      if (sourceJson != null) 'source_json': sourceJson,
      if (propertiesJson != null) 'properties_json': propertiesJson,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingEventsCompanion copyWith({
    Value<String>? eventId,
    Value<String>? eventType,
    Value<DateTime>? occurredAt,
    Value<String?>? sessionId,
    Value<String?>? trackId,
    Value<String?>? sourceJson,
    Value<String>? propertiesJson,
    Value<int>? schemaVersion,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PendingEventsCompanion(
      eventId: eventId ?? this.eventId,
      eventType: eventType ?? this.eventType,
      occurredAt: occurredAt ?? this.occurredAt,
      sessionId: sessionId ?? this.sessionId,
      trackId: trackId ?? this.trackId,
      sourceJson: sourceJson ?? this.sourceJson,
      propertiesJson: propertiesJson ?? this.propertiesJson,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (sourceJson.present) {
      map['source_json'] = Variable<String>(sourceJson.value);
    }
    if (propertiesJson.present) {
      map['properties_json'] = Variable<String>(propertiesJson.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingEventsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('eventType: $eventType, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('sessionId: $sessionId, ')
          ..write('trackId: $trackId, ')
          ..write('sourceJson: $sourceJson, ')
          ..write('propertiesJson: $propertiesJson, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MusicDatabase extends GeneratedDatabase {
  _$MusicDatabase(QueryExecutor e) : super(e);
  $MusicDatabaseManager get managers => $MusicDatabaseManager(this);
  late final $LocalTracksTable localTracks = $LocalTracksTable(this);
  late final $LocalPlaylistsTable localPlaylists = $LocalPlaylistsTable(this);
  late final $LocalPlaylistTracksTable localPlaylistTracks =
      $LocalPlaylistTracksTable(this);
  late final $LocalFavoritesTable localFavorites = $LocalFavoritesTable(this);
  late final $PendingEventsTable pendingEvents = $PendingEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localTracks,
    localPlaylists,
    localPlaylistTracks,
    localFavorites,
    pendingEvents,
  ];
}

typedef $$LocalTracksTableCreateCompanionBuilder =
    LocalTracksCompanion Function({
      required String id,
      required String title,
      required String artistName,
      Value<String?> albumTitle,
      Value<int?> durationMs,
      Value<String?> coverImageUrl,
      Value<String?> fileUrl,
      Value<bool> isDownloaded,
      Value<String?> localFilePath,
      Value<int?> fileSizeBytes,
      Value<DateTime?> downloadedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalTracksTableUpdateCompanionBuilder =
    LocalTracksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> artistName,
      Value<String?> albumTitle,
      Value<int?> durationMs,
      Value<String?> coverImageUrl,
      Value<String?> fileUrl,
      Value<bool> isDownloaded,
      Value<String?> localFilePath,
      Value<int?> fileSizeBytes,
      Value<DateTime?> downloadedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalTracksTableFilterComposer
    extends Composer<_$MusicDatabase, $LocalTracksTable> {
  $$LocalTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistName => $composableBuilder(
    column: $table.artistName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumTitle => $composableBuilder(
    column: $table.albumTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverImageUrl => $composableBuilder(
    column: $table.coverImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileUrl => $composableBuilder(
    column: $table.fileUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTracksTableOrderingComposer
    extends Composer<_$MusicDatabase, $LocalTracksTable> {
  $$LocalTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistName => $composableBuilder(
    column: $table.artistName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumTitle => $composableBuilder(
    column: $table.albumTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverImageUrl => $composableBuilder(
    column: $table.coverImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileUrl => $composableBuilder(
    column: $table.fileUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTracksTableAnnotationComposer
    extends Composer<_$MusicDatabase, $LocalTracksTable> {
  $$LocalTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artistName => $composableBuilder(
    column: $table.artistName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get albumTitle => $composableBuilder(
    column: $table.albumTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverImageUrl => $composableBuilder(
    column: $table.coverImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileUrl =>
      $composableBuilder(column: $table.fileUrl, builder: (column) => column);

  GeneratedColumn<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalTracksTableTableManager
    extends
        RootTableManager<
          _$MusicDatabase,
          $LocalTracksTable,
          LocalTrack,
          $$LocalTracksTableFilterComposer,
          $$LocalTracksTableOrderingComposer,
          $$LocalTracksTableAnnotationComposer,
          $$LocalTracksTableCreateCompanionBuilder,
          $$LocalTracksTableUpdateCompanionBuilder,
          (
            LocalTrack,
            BaseReferences<_$MusicDatabase, $LocalTracksTable, LocalTrack>,
          ),
          LocalTrack,
          PrefetchHooks Function()
        > {
  $$LocalTracksTableTableManager(_$MusicDatabase db, $LocalTracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artistName = const Value.absent(),
                Value<String?> albumTitle = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String?> coverImageUrl = const Value.absent(),
                Value<String?> fileUrl = const Value.absent(),
                Value<bool> isDownloaded = const Value.absent(),
                Value<String?> localFilePath = const Value.absent(),
                Value<int?> fileSizeBytes = const Value.absent(),
                Value<DateTime?> downloadedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTracksCompanion(
                id: id,
                title: title,
                artistName: artistName,
                albumTitle: albumTitle,
                durationMs: durationMs,
                coverImageUrl: coverImageUrl,
                fileUrl: fileUrl,
                isDownloaded: isDownloaded,
                localFilePath: localFilePath,
                fileSizeBytes: fileSizeBytes,
                downloadedAt: downloadedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String artistName,
                Value<String?> albumTitle = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String?> coverImageUrl = const Value.absent(),
                Value<String?> fileUrl = const Value.absent(),
                Value<bool> isDownloaded = const Value.absent(),
                Value<String?> localFilePath = const Value.absent(),
                Value<int?> fileSizeBytes = const Value.absent(),
                Value<DateTime?> downloadedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTracksCompanion.insert(
                id: id,
                title: title,
                artistName: artistName,
                albumTitle: albumTitle,
                durationMs: durationMs,
                coverImageUrl: coverImageUrl,
                fileUrl: fileUrl,
                isDownloaded: isDownloaded,
                localFilePath: localFilePath,
                fileSizeBytes: fileSizeBytes,
                downloadedAt: downloadedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalTracksTable, LocalTrack>(table),
                  BaseReferences<
                    _$MusicDatabase,
                    $LocalTracksTable,
                    LocalTrack
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$MusicDatabase,
      $LocalTracksTable,
      LocalTrack,
      $$LocalTracksTableFilterComposer,
      $$LocalTracksTableOrderingComposer,
      $$LocalTracksTableAnnotationComposer,
      $$LocalTracksTableCreateCompanionBuilder,
      $$LocalTracksTableUpdateCompanionBuilder,
      (
        LocalTrack,
        BaseReferences<_$MusicDatabase, $LocalTracksTable, LocalTrack>,
      ),
      LocalTrack,
      PrefetchHooks Function()
    >;
typedef $$LocalPlaylistsTableCreateCompanionBuilder =
    LocalPlaylistsCompanion Function({
      required String id,
      Value<String?> userId,
      required String name,
      Value<String?> description,
      Value<String?> coverImageUrl,
      Value<String> visibility,
      Value<int> tracksCount,
      Value<DateTime?> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalPlaylistsTableUpdateCompanionBuilder =
    LocalPlaylistsCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String> name,
      Value<String?> description,
      Value<String?> coverImageUrl,
      Value<String> visibility,
      Value<int> tracksCount,
      Value<DateTime?> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalPlaylistsTableFilterComposer
    extends Composer<_$MusicDatabase, $LocalPlaylistsTable> {
  $$LocalPlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverImageUrl => $composableBuilder(
    column: $table.coverImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tracksCount => $composableBuilder(
    column: $table.tracksCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPlaylistsTableOrderingComposer
    extends Composer<_$MusicDatabase, $LocalPlaylistsTable> {
  $$LocalPlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverImageUrl => $composableBuilder(
    column: $table.coverImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tracksCount => $composableBuilder(
    column: $table.tracksCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPlaylistsTableAnnotationComposer
    extends Composer<_$MusicDatabase, $LocalPlaylistsTable> {
  $$LocalPlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverImageUrl => $composableBuilder(
    column: $table.coverImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tracksCount => $composableBuilder(
    column: $table.tracksCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalPlaylistsTableTableManager
    extends
        RootTableManager<
          _$MusicDatabase,
          $LocalPlaylistsTable,
          LocalPlaylist,
          $$LocalPlaylistsTableFilterComposer,
          $$LocalPlaylistsTableOrderingComposer,
          $$LocalPlaylistsTableAnnotationComposer,
          $$LocalPlaylistsTableCreateCompanionBuilder,
          $$LocalPlaylistsTableUpdateCompanionBuilder,
          (
            LocalPlaylist,
            BaseReferences<
              _$MusicDatabase,
              $LocalPlaylistsTable,
              LocalPlaylist
            >,
          ),
          LocalPlaylist,
          PrefetchHooks Function()
        > {
  $$LocalPlaylistsTableTableManager(
    _$MusicDatabase db,
    $LocalPlaylistsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> coverImageUrl = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                Value<int> tracksCount = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPlaylistsCompanion(
                id: id,
                userId: userId,
                name: name,
                description: description,
                coverImageUrl: coverImageUrl,
                visibility: visibility,
                tracksCount: tracksCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> userId = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> coverImageUrl = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                Value<int> tracksCount = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPlaylistsCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                description: description,
                coverImageUrl: coverImageUrl,
                visibility: visibility,
                tracksCount: tracksCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalPlaylistsTable, LocalPlaylist>(table),
                  BaseReferences<
                    _$MusicDatabase,
                    $LocalPlaylistsTable,
                    LocalPlaylist
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$MusicDatabase,
      $LocalPlaylistsTable,
      LocalPlaylist,
      $$LocalPlaylistsTableFilterComposer,
      $$LocalPlaylistsTableOrderingComposer,
      $$LocalPlaylistsTableAnnotationComposer,
      $$LocalPlaylistsTableCreateCompanionBuilder,
      $$LocalPlaylistsTableUpdateCompanionBuilder,
      (
        LocalPlaylist,
        BaseReferences<_$MusicDatabase, $LocalPlaylistsTable, LocalPlaylist>,
      ),
      LocalPlaylist,
      PrefetchHooks Function()
    >;
typedef $$LocalPlaylistTracksTableCreateCompanionBuilder =
    LocalPlaylistTracksCompanion Function({
      required String playlistId,
      required String trackId,
      Value<int> position,
      Value<int> rowid,
    });
typedef $$LocalPlaylistTracksTableUpdateCompanionBuilder =
    LocalPlaylistTracksCompanion Function({
      Value<String> playlistId,
      Value<String> trackId,
      Value<int> position,
      Value<int> rowid,
    });

class $$LocalPlaylistTracksTableFilterComposer
    extends Composer<_$MusicDatabase, $LocalPlaylistTracksTable> {
  $$LocalPlaylistTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPlaylistTracksTableOrderingComposer
    extends Composer<_$MusicDatabase, $LocalPlaylistTracksTable> {
  $$LocalPlaylistTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPlaylistTracksTableAnnotationComposer
    extends Composer<_$MusicDatabase, $LocalPlaylistTracksTable> {
  $$LocalPlaylistTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$LocalPlaylistTracksTableTableManager
    extends
        RootTableManager<
          _$MusicDatabase,
          $LocalPlaylistTracksTable,
          LocalPlaylistTrack,
          $$LocalPlaylistTracksTableFilterComposer,
          $$LocalPlaylistTracksTableOrderingComposer,
          $$LocalPlaylistTracksTableAnnotationComposer,
          $$LocalPlaylistTracksTableCreateCompanionBuilder,
          $$LocalPlaylistTracksTableUpdateCompanionBuilder,
          (
            LocalPlaylistTrack,
            BaseReferences<
              _$MusicDatabase,
              $LocalPlaylistTracksTable,
              LocalPlaylistTrack
            >,
          ),
          LocalPlaylistTrack,
          PrefetchHooks Function()
        > {
  $$LocalPlaylistTracksTableTableManager(
    _$MusicDatabase db,
    $LocalPlaylistTracksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPlaylistTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPlaylistTracksTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalPlaylistTracksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> playlistId = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPlaylistTracksCompanion(
                playlistId: playlistId,
                trackId: trackId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playlistId,
                required String trackId,
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPlaylistTracksCompanion.insert(
                playlistId: playlistId,
                trackId: trackId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalPlaylistTracksTable, LocalPlaylistTrack>(
                    table,
                  ),
                  BaseReferences<
                    _$MusicDatabase,
                    $LocalPlaylistTracksTable,
                    LocalPlaylistTrack
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPlaylistTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$MusicDatabase,
      $LocalPlaylistTracksTable,
      LocalPlaylistTrack,
      $$LocalPlaylistTracksTableFilterComposer,
      $$LocalPlaylistTracksTableOrderingComposer,
      $$LocalPlaylistTracksTableAnnotationComposer,
      $$LocalPlaylistTracksTableCreateCompanionBuilder,
      $$LocalPlaylistTracksTableUpdateCompanionBuilder,
      (
        LocalPlaylistTrack,
        BaseReferences<
          _$MusicDatabase,
          $LocalPlaylistTracksTable,
          LocalPlaylistTrack
        >,
      ),
      LocalPlaylistTrack,
      PrefetchHooks Function()
    >;
typedef $$LocalFavoritesTableCreateCompanionBuilder =
    LocalFavoritesCompanion Function({
      required String trackId,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });
typedef $$LocalFavoritesTableUpdateCompanionBuilder =
    LocalFavoritesCompanion Function({
      Value<String> trackId,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });

class $$LocalFavoritesTableFilterComposer
    extends Composer<_$MusicDatabase, $LocalFavoritesTable> {
  $$LocalFavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalFavoritesTableOrderingComposer
    extends Composer<_$MusicDatabase, $LocalFavoritesTable> {
  $$LocalFavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalFavoritesTableAnnotationComposer
    extends Composer<_$MusicDatabase, $LocalFavoritesTable> {
  $$LocalFavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$LocalFavoritesTableTableManager
    extends
        RootTableManager<
          _$MusicDatabase,
          $LocalFavoritesTable,
          LocalFavorite,
          $$LocalFavoritesTableFilterComposer,
          $$LocalFavoritesTableOrderingComposer,
          $$LocalFavoritesTableAnnotationComposer,
          $$LocalFavoritesTableCreateCompanionBuilder,
          $$LocalFavoritesTableUpdateCompanionBuilder,
          (
            LocalFavorite,
            BaseReferences<
              _$MusicDatabase,
              $LocalFavoritesTable,
              LocalFavorite
            >,
          ),
          LocalFavorite,
          PrefetchHooks Function()
        > {
  $$LocalFavoritesTableTableManager(
    _$MusicDatabase db,
    $LocalFavoritesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalFavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalFavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalFavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> trackId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalFavoritesCompanion(
                trackId: trackId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String trackId,
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalFavoritesCompanion.insert(
                trackId: trackId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalFavoritesTable, LocalFavorite>(table),
                  BaseReferences<
                    _$MusicDatabase,
                    $LocalFavoritesTable,
                    LocalFavorite
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalFavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$MusicDatabase,
      $LocalFavoritesTable,
      LocalFavorite,
      $$LocalFavoritesTableFilterComposer,
      $$LocalFavoritesTableOrderingComposer,
      $$LocalFavoritesTableAnnotationComposer,
      $$LocalFavoritesTableCreateCompanionBuilder,
      $$LocalFavoritesTableUpdateCompanionBuilder,
      (
        LocalFavorite,
        BaseReferences<_$MusicDatabase, $LocalFavoritesTable, LocalFavorite>,
      ),
      LocalFavorite,
      PrefetchHooks Function()
    >;
typedef $$PendingEventsTableCreateCompanionBuilder =
    PendingEventsCompanion Function({
      required String eventId,
      required String eventType,
      required DateTime occurredAt,
      Value<String?> sessionId,
      Value<String?> trackId,
      Value<String?> sourceJson,
      required String propertiesJson,
      Value<int> schemaVersion,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$PendingEventsTableUpdateCompanionBuilder =
    PendingEventsCompanion Function({
      Value<String> eventId,
      Value<String> eventType,
      Value<DateTime> occurredAt,
      Value<String?> sessionId,
      Value<String?> trackId,
      Value<String?> sourceJson,
      Value<String> propertiesJson,
      Value<int> schemaVersion,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PendingEventsTableFilterComposer
    extends Composer<_$MusicDatabase, $PendingEventsTable> {
  $$PendingEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceJson => $composableBuilder(
    column: $table.sourceJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get propertiesJson => $composableBuilder(
    column: $table.propertiesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingEventsTableOrderingComposer
    extends Composer<_$MusicDatabase, $PendingEventsTable> {
  $$PendingEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceJson => $composableBuilder(
    column: $table.sourceJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get propertiesJson => $composableBuilder(
    column: $table.propertiesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingEventsTableAnnotationComposer
    extends Composer<_$MusicDatabase, $PendingEventsTable> {
  $$PendingEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get sourceJson => $composableBuilder(
    column: $table.sourceJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get propertiesJson => $composableBuilder(
    column: $table.propertiesJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingEventsTableTableManager
    extends
        RootTableManager<
          _$MusicDatabase,
          $PendingEventsTable,
          PendingEvent,
          $$PendingEventsTableFilterComposer,
          $$PendingEventsTableOrderingComposer,
          $$PendingEventsTableAnnotationComposer,
          $$PendingEventsTableCreateCompanionBuilder,
          $$PendingEventsTableUpdateCompanionBuilder,
          (
            PendingEvent,
            BaseReferences<_$MusicDatabase, $PendingEventsTable, PendingEvent>,
          ),
          PendingEvent,
          PrefetchHooks Function()
        > {
  $$PendingEventsTableTableManager(
    _$MusicDatabase db,
    $PendingEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String?> trackId = const Value.absent(),
                Value<String?> sourceJson = const Value.absent(),
                Value<String> propertiesJson = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingEventsCompanion(
                eventId: eventId,
                eventType: eventType,
                occurredAt: occurredAt,
                sessionId: sessionId,
                trackId: trackId,
                sourceJson: sourceJson,
                propertiesJson: propertiesJson,
                schemaVersion: schemaVersion,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String eventType,
                required DateTime occurredAt,
                Value<String?> sessionId = const Value.absent(),
                Value<String?> trackId = const Value.absent(),
                Value<String?> sourceJson = const Value.absent(),
                required String propertiesJson,
                Value<int> schemaVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingEventsCompanion.insert(
                eventId: eventId,
                eventType: eventType,
                occurredAt: occurredAt,
                sessionId: sessionId,
                trackId: trackId,
                sourceJson: sourceJson,
                propertiesJson: propertiesJson,
                schemaVersion: schemaVersion,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingEventsTable, PendingEvent>(table),
                  BaseReferences<
                    _$MusicDatabase,
                    $PendingEventsTable,
                    PendingEvent
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$MusicDatabase,
      $PendingEventsTable,
      PendingEvent,
      $$PendingEventsTableFilterComposer,
      $$PendingEventsTableOrderingComposer,
      $$PendingEventsTableAnnotationComposer,
      $$PendingEventsTableCreateCompanionBuilder,
      $$PendingEventsTableUpdateCompanionBuilder,
      (
        PendingEvent,
        BaseReferences<_$MusicDatabase, $PendingEventsTable, PendingEvent>,
      ),
      PendingEvent,
      PrefetchHooks Function()
    >;

class $MusicDatabaseManager {
  final _$MusicDatabase _db;
  $MusicDatabaseManager(this._db);
  $$LocalTracksTableTableManager get localTracks =>
      $$LocalTracksTableTableManager(_db, _db.localTracks);
  $$LocalPlaylistsTableTableManager get localPlaylists =>
      $$LocalPlaylistsTableTableManager(_db, _db.localPlaylists);
  $$LocalPlaylistTracksTableTableManager get localPlaylistTracks =>
      $$LocalPlaylistTracksTableTableManager(_db, _db.localPlaylistTracks);
  $$LocalFavoritesTableTableManager get localFavorites =>
      $$LocalFavoritesTableTableManager(_db, _db.localFavorites);
  $$PendingEventsTableTableManager get pendingEvents =>
      $$PendingEventsTableTableManager(_db, _db.pendingEvents);
}
