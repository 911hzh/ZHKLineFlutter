// ignore_for_file: file_names

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:k_line_flutter/GetItConfiguation.config.dart';

// import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();
