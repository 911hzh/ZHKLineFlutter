import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foundation_kit/flutter_foundation_kit.dart';

class LoggerState {
  const LoggerState({
    this.hasStarted = false,
    this.messages = const [],
    this.logFilePath,
  });

  final bool hasStarted;
  final List<String> messages;
  final String? logFilePath;

  LoggerState copyWith({
    bool? hasStarted,
    List<String>? messages,
    String? logFilePath,
  }) {
    return LoggerState(
      hasStarted: hasStarted ?? this.hasStarted,
      messages: messages ?? this.messages,
      logFilePath: logFilePath ?? this.logFilePath,
    );
  }
}

class LoggerCubit extends Cubit<LoggerState> {
  LoggerCubit() : super(const LoggerState());

  void writeLogs() {
    final logger = LoggerFactory.current.getLogger(["console"]);
    logger.info("Logger demo info");
    logger.debug("Logger demo debug");
    logger.error("Logger demo error");
    emit(
      state.copyWith(
        hasStarted: true,
        messages: const [
          "LoggerFactory.current.getLogger(['console'])",
          "info/debug/error 已输出到控制台",
          "LoggerConfiguration 可配置 console/file/advancedFile 输出",
        ],
      ),
    );
  }

  void configurePathLogOutput() {
    final logFilePath = '${Directory.systemTemp.path}/foundation-kit-demo.log';
    LoggerFactoryDefaultImpl.configure(
      configs: [
        LoggerConfiguration.file(
          tag: 'pathFile',
          filePath: logFilePath,
          clearOutput: true,
        ),
      ],
    );

    final logger = LoggerFactory.current.getLogger(['pathFile']);
    logger.info('Logger path output demo');
    logger.warning('This log is written to $logFilePath');

    emit(
      state.copyWith(
        hasStarted: true,
        logFilePath: logFilePath,
        messages: [
          ...state.messages,
          'LoggerFactoryDefaultImpl.configure(configs: [LoggerConfiguration.file(...)])',
          "LoggerFactory.current.getLogger(['pathFile']).info(...)",
          '日志文件路径：$logFilePath',
        ],
      ),
    );
  }
}
