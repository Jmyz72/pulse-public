import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/settings.dart';

abstract class SettingsRepository {
  Future<Either<Failure, UserSettings>> getSettings(String userId);
  Future<Either<Failure, void>> updateSettings(String userId, UserSettings settings);
  Future<Either<Failure, void>> updatePrivacySetting(String userId, String key, bool value);
  Future<Either<Failure, void>> clearCache();
}
