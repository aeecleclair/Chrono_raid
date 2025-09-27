import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chrono_raid/login/ui/app_sign_in.dart' deferred as app_sign_in;
import 'package:chrono_raid/tools/middlewares/deferred_middleware.dart';
import 'package:qlevar_router/qlevar_router.dart';

class LoginRouter {
  final Ref ref;
  static const String root = '/login';
  LoginRouter(this.ref);

  QRoute route() => QRoute(
        path: LoginRouter.root,
        builder: () => app_sign_in.AppSignIn(),
        pageType: const QMaterialPage(),
        middleware: [
          DeferredLoadingMiddleware(
            app_sign_in.loadLibrary,
          ),
        ],
      );
}
