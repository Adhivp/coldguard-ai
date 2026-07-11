import 'package:dartz/dartz.dart';
import 'package:code_card_ai/core/error/failures.dart';
import 'package:code_card_ai/core/usecase/usecase.dart';
import 'package:code_card_ai/features/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.logout();
  }
}
