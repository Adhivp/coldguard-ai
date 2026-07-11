import 'package:dartz/dartz.dart';
import 'package:code_card_ai/core/error/failures.dart';

abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

class NoParams {}
