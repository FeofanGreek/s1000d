import 'package:go_router/go_router.dart';
import 'package:xml/xml.dart';

import 'ui/start_screen.dart';
import 'ui/project_settings_screen.dart';
import 'ui/viewers/crew_viewer.dart';
import 'ui/viewers/description_viewer.dart';
import 'ui/viewers/pm_viewer.dart';
import 'ui/xml_viewer_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const StartScreen(),
    ),
    GoRoute(
      path: '/project_settings',
      builder: (context, state) => const ProjectSettingsScreen(),
    ),
    GoRoute(
      path: '/crew_viewer',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return CrewViewer(
          document: extra['document'] as XmlDocument,
          fileName: extra['fileName'] as String,
          filePath: extra['filePath'] as String?,
          fileTitle: extra['fileTitle'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/description_viewer',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return DescriptionViewer(
          document: extra['document'] as XmlDocument,
          fileName: extra['fileName'] as String,
          filePath: extra['filePath'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/pm_viewer',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return PmViewer(
          document: extra['document'] as XmlDocument,
          fileName: extra['fileName'] as String,
          filePath: extra['filePath'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/xml_viewer',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return XmlViewerScreen(
          xmlContent: extra['xmlContent'] as String,
          fileName: extra['fileName'] as String,
          filePath: extra['filePath'] as String?,
          fileTitle: extra['fileTitle'] as String?,
        );
      },
    ),
  ],
);
