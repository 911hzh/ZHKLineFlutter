import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foundation_kit/flutter_foundation_kit.dart';

class CUtilState {
  const CUtilState({
    this.hasStarted = false,
    this.prettyJson = '',
    this.lazyValue = '',
    this.generatedId = 0,
    this.pollingValues = const [],
  });

  final bool hasStarted;
  final String prettyJson;
  final String lazyValue;
  final int generatedId;
  final List<int> pollingValues;

  CUtilState copyWith({
    bool? hasStarted,
    String? prettyJson,
    String? lazyValue,
    int? generatedId,
    List<int>? pollingValues,
  }) {
    return CUtilState(
      hasStarted: hasStarted ?? this.hasStarted,
      prettyJson: prettyJson ?? this.prettyJson,
      lazyValue: lazyValue ?? this.lazyValue,
      generatedId: generatedId ?? this.generatedId,
      pollingValues: pollingValues ?? this.pollingValues,
    );
  }
}

class CUtilCubit extends Cubit<CUtilState> {
  CUtilCubit() : super(const CUtilState());

  Polling<int>? _polling;

  Future<void> runDemo() async {
    _polling?.stop();
    emit(const CUtilState(hasStarted: true));
    final prettyJson = JsonUtil.pretty('{"module":"cutil","ok":true}');
    final lazyload = Lazyload<String>(() async => "lazy value loaded once");
    final lazyValue = await lazyload.get();
    final generatedId = DateTime.now().millisecondsSinceEpoch;
    emit(
      state.copyWith(
        prettyJson: prettyJson,
        lazyValue: lazyValue,
        generatedId: generatedId,
      ),
    );
    _startPolling();
  }

  void _startPolling() {
    var value = 0;
    _polling?.stop();
    _polling = Polling<int>(
      spaceTime: 300,
      pollingCount: 3,
      task: Lazyload<int>(() async => ++value),
      callBack: (result) {
        emit(state.copyWith(pollingValues: [...state.pollingValues, result]));
      },
    )..start();
  }

  @override
  Future<void> close() {
    _polling?.stop();
    return super.close();
  }
}
