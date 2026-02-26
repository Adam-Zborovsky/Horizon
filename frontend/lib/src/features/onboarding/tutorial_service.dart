import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../core/theme/app_theme.dart';
import 'tutorial_keys.dart';

class TutorialService {
  static TutorialCoachMark createTutorial({
    required BuildContext context,
    required List<TargetFocus> targets,
    Function()? onFinish,
    bool Function()? onSkip,
  }) {
    return TutorialCoachMark(
      targets: targets,
      colorShadow: AppTheme.obsidian,
      textSkip: "SKIP TUTORIAL",
      paddingFocus: 10,
      opacityShadow: 0.6,
      onFinish: onFinish,
      onSkip: onSkip,
      onClickTarget: (target) {},
      onClickTargetWithTapPosition: (target, tapDetails) {},
      onClickOverlay: (target) {},
    );
  }

  static List<TargetFocus> getNavigationTargets() {
    return [
      _buildTarget(
        identify: "nav_dash",
        key: TutorialKeys.navDash,
        title: "Intelligence Hub",
        content: "Access your primary War Room dashboard for real-time strategic overviews.",
        align: ContentAlign.top,
      ),
      _buildTarget(
        identify: "nav_vault",
        key: TutorialKeys.navVault,
        title: "Intelligence Vault",
        content: "Deep-dive into categorical reports and historical intelligence data.",
        align: ContentAlign.top,
      ),
      _buildTarget(
        identify: "nav_nexus",
        key: TutorialKeys.navNexus,
        title: "Market Nexus",
        content: "Monitor live asset performance and identify strategic divergences.",
        align: ContentAlign.top,
      ),
      _buildTarget(
        identify: "nav_scan",
        key: TutorialKeys.navScan,
        title: "Alpha Scanner",
        content: "Utilize advanced scanning protocols to identify emerging market patterns.",
        align: ContentAlign.top,
      ),
    ];
  }

  static List<TargetFocus> getDashboardTargets() {
    return [
      _buildTarget(
        identify: "dash_briefing",
        key: TutorialKeys.dashBriefing,
        title: "Daily Briefing",
        content: "Your synthesized intelligence protocol for the current cycle. Review critical sentiment scores and core summaries.",
      ),
      _buildTarget(
        identify: "dash_pillars",
        key: TutorialKeys.dashPillars,
        title: "Intelligence Pillars",
        content: "Navigate through core sectors of interest. Each pillar tracks sector-specific sentiment and strategic health.",
      ),
      _buildTarget(
        identify: "nav_profile",
        key: TutorialKeys.navProfile,
        title: "Operator Profile",
        content: "Access secure configurations and manual protocol refreshes.",
        align: ContentAlign.bottom,
      ),
    ];
  }

  static List<TargetFocus> getVaultTargets() {
    return [
      _buildTarget(
        identify: "vault_filter",
        key: TutorialKeys.vaultFilter,
        title: "Sector Filtering",
        content: "Filter incoming intelligence by tactical categories to focus your analysis.",
      ),
      _buildTarget(
        identify: "vault_reports",
        key: TutorialKeys.vaultReports,
        title: "Tactical Reports",
        content: "Comprehensive intelligence logs including sentiment analysis, catalysts, and risk assessments.",
      ),
    ];
  }

  static List<TargetFocus> getNexusTargets() {
    return [
      _buildTarget(
        identify: "nexus_manage",
        key: TutorialKeys.nexusManage,
        title: "Nexus Linkage",
        content: "Initialize new asset tracking protocols and manage your primary watchlist.",
      ),
    ];
  }

  static List<TargetFocus> getProfileTargets() {
    return [
      _buildTarget(
        identify: "profile_refresh",
        key: TutorialKeys.profileRefresh,
        title: "Manual Refresh",
        content: "Force-trigger an intelligence gathering cycle to synchronize with the latest market data.",
      ),
      _buildTarget(
        identify: "profile_logout",
        key: TutorialKeys.profileLogout,
        title: "Protocol Termination",
        content: "Securely terminate your current session and exit the Alpha Horizon network.",
      ),
    ];
  }

  static TargetFocus _buildTarget({
    required String identify,
    required GlobalKey key,
    required String title,
    required String content,
    ContentAlign align = ContentAlign.bottom,
  }) {
    return TargetFocus(
      identify: identify,
      keyTarget: key,
      alignSkip: Alignment.topRight,
      contents: [
        TargetContent(
          align: align,
          builder: (context, controller) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldAmber,
                    fontSize: 20,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  content,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            );
          },
        ),
      ],
      shape: ShapeLightFocus.RRect,
      radius: 15,
    );
  }
}
