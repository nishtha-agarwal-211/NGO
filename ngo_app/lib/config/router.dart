import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/members/member_list_screen.dart';
import '../screens/members/member_detail_screen.dart';
import '../screens/members/member_form_screen.dart';
import '../screens/donors/donor_list_screen.dart';
import '../screens/donors/donor_detail_screen.dart';
import '../screens/donors/donor_form_screen.dart';
import '../screens/projects/project_list_screen.dart';
import '../screens/projects/project_detail_screen.dart';
import '../screens/projects/project_form_screen.dart';
import '../screens/events/event_detail_screen.dart';
import '../screens/events/event_form_screen.dart';
import '../screens/events/calendar_screen.dart';
import '../screens/events/event_folder_screen.dart';
import '../screens/news/news_list_screen.dart';
import '../screens/news/news_detail_screen.dart';
import '../screens/news/news_form_screen.dart';
import '../screens/photos/photo_gallery_screen.dart';
import '../widgets/app_shell.dart';

/// Route names for type-safe navigation.
class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String members = '/members';
  static const String memberDetail = '/members/:id';
  static const String memberAdd = '/members/add';
  static const String memberEdit = '/members/:id/edit';
  static const String donors = '/donors';
  static const String donorDetail = '/donors/:id';
  static const String donorAdd = '/donors/add';
  static const String donorEdit = '/donors/:id/edit';
  static const String projects = '/projects';
  static const String projectDetail = '/projects/:id';
  static const String projectAdd = '/projects/add';
  static const String projectEdit = '/projects/:id/edit';
  static const String eventDetail = '/events/:id';
  static const String eventAdd = '/events/add';
  static const String eventEdit = '/events/:id/edit';
  static const String calendar = '/calendar';
  static const String news = '/news';
  static const String newsDetail = '/news/:id';
  static const String newsAdd = '/news/add';
  static const String newsEdit = '/news/:id/edit';
  static const String photoGallery = '/events/:id/photos';
  static const String eventFolder = '/projects/:id/events';
}

/// GoRouter configuration with auth redirect.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;
      final isNewsRoute = state.matchedLocation.startsWith('/news');

      // Allow unauthenticated access to news routes (public)
      if (isNewsRoute) return null;

      // Redirect to login if not authenticated
      if (!isLoggedIn && !isLoginRoute) return AppRoutes.login;

      // Redirect away from login if already authenticated
      if (isLoggedIn && isLoginRoute) return AppRoutes.dashboard;

      return null;
    },
    routes: [
      // Login (no shell)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Main app shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.members,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MemberListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.donors,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DonorListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.projects,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProjectListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.news,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NewsListScreen(),
            ),
          ),
        ],
      ),

      // Detail / Form routes (outside shell — full screen)
      GoRoute(
        path: AppRoutes.memberAdd,
        builder: (context, state) => const MemberFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.memberEdit,
        builder: (context, state) => MemberFormScreen(
          memberId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: AppRoutes.memberDetail,
        builder: (context, state) => MemberDetailScreen(
          memberId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.donorAdd,
        builder: (context, state) => const DonorFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.donorEdit,
        builder: (context, state) => DonorFormScreen(
          donorId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: AppRoutes.donorDetail,
        builder: (context, state) => DonorDetailScreen(
          donorId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.projectAdd,
        builder: (context, state) => const ProjectFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.projectEdit,
        builder: (context, state) => ProjectFormScreen(
          projectId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: AppRoutes.projectDetail,
        builder: (context, state) => ProjectDetailScreen(
          projectId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.eventFolder,
        builder: (context, state) => EventFolderScreen(
          projectId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.eventAdd,
        builder: (context, state) {
          final projectId = state.uri.queryParameters['projectId'];
          return EventFormScreen(projectId: projectId);
        },
      ),
      GoRoute(
        path: AppRoutes.eventEdit,
        builder: (context, state) => EventFormScreen(
          eventId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: AppRoutes.eventDetail,
        builder: (context, state) => EventDetailScreen(
          eventId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.calendar,
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.newsAdd,
        builder: (context, state) => const NewsFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.newsEdit,
        builder: (context, state) => NewsFormScreen(
          newsId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: AppRoutes.newsDetail,
        builder: (context, state) => NewsDetailScreen(
          newsId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.photoGallery,
        builder: (context, state) => PhotoGalleryScreen(
          eventId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
