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
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.6,
      onFinish: onFinish,
      onSkip: onSkip,
      onClickTarget: (target) {},
      onClickTargetWithTapPosition: (target, tapDetails) {},
      onClickOverlay: (target) {},
    );
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────
  // Order: current nav tab → screen components → profile icon → vault guide
  static List<TargetFocus> getDashboardTargets() {
    return [
      _buildTarget(
        identify: "nav_dash",
        key: TutorialKeys.navDash,
        title: "War Room",
        content:
            "This is your command center. The War Room gives you a live overview of intelligence briefings, sector sentiment, and your tracked assets — all in one place.",
        align: ContentAlign.top,
      ),
      _buildTarget(
        identify: "dash_briefing",
        key: TutorialKeys.dashBriefing,
        title: "Daily Briefing",
        content:
            "Your synthesized daily intelligence report appears here. It highlights the top sector, its sentiment score, and a strategic summary. Empty on first launch — trigger a briefing from your profile to populate it.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "dash_pillars",
        key: TutorialKeys.dashPillars,
        title: "Intelligence Pillars",
        content:
            "Each card represents a tracked intelligence sector with a live sentiment bar. Empty until your first briefing is generated. Once active, tap any pillar to drill into its full report.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "nav_profile",
        key: TutorialKeys.navProfile,
        title: "Operator Profile",
        content:
            "Tap here to access your settings — configure intelligence topics, manage your watchlist, trigger manual refreshes, and restart this tutorial at any time.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "nav_vault_guide",
        key: TutorialKeys.navVault,
        title: "Up Next: Intelligence Vault",
        content:
            "Tap here to visit the Intelligence Vault — your full archive of sector reports, article feeds, and risk assessments. The tutorial will continue when you arrive.",
        align: ContentAlign.top,
        isGuide: true,
      ),
    ];
  }

  // ── Vault ─────────────────────────────────────────────────────────────────
  // Order: current nav tab → filter → reports → nexus guide
  static List<TargetFocus> getVaultTargets() {
    return [
      _buildTarget(
        identify: "nav_vault",
        key: TutorialKeys.navVault,
        title: "Intelligence Vault",
        content:
            "The Vault is your deep-dive archive. Browse all generated intelligence reports, filter by sector, and read full analysis including sentiment scores, catalysts, and risk flags.",
        align: ContentAlign.top,
      ),
      _buildTarget(
        identify: "vault_filter",
        key: TutorialKeys.vaultFilter,
        title: "Sector Filter",
        content:
            "Use these pills to filter reports by intelligence category. Categories populate as briefings are generated — on a fresh account this row may show only 'All'.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "vault_reports",
        key: TutorialKeys.vaultReports,
        title: "Intelligence Reports",
        content:
            "Full reports appear here — each with a sentiment score, summary, source articles, and risk assessment. Empty on first launch until a briefing cycle has run.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "nav_nexus_guide",
        key: TutorialKeys.navNexus,
        title: "Up Next: Market Nexus",
        content:
            "Tap here to visit the Market Nexus — where you track live asset prices and manage your watchlist. The tutorial continues on arrival.",
        align: ContentAlign.top,
        isGuide: true,
      ),
    ];
  }

  // ── Nexus ─────────────────────────────────────────────────────────────────
  // Order: current nav tab → manage button → dash guide (profile lives there)
  static List<TargetFocus> getNexusTargets() {
    return [
      _buildTarget(
        identify: "nav_nexus",
        key: TutorialKeys.navNexus,
        title: "Market Nexus",
        content:
            "The Nexus tracks live price data and sentiment signals for every asset in your watchlist. Empty until you add stocks — tap the Manage button to get started.",
        align: ContentAlign.top,
      ),
      _buildTarget(
        identify: "nexus_manage",
        key: TutorialKeys.nexusManage,
        title: "Manage Watchlist",
        content:
            "Tap here to add stocks to your watchlist. Once added, each asset appears below with its current price, daily change, and a mini sparkline chart.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "nav_dash_guide",
        key: TutorialKeys.navDash,
        title: "Up Next: Your Profile",
        content:
            "Return to the War Room, then tap your profile icon in the top-right corner to complete your orientation and configure your intelligence settings.",
        align: ContentAlign.top,
        isGuide: true,
      ),
    ];
  }

  // ── Profile ───────────────────────────────────────────────────────────────
  // No nav tab — starts directly with the action items (screen scrolls first)
  static List<TargetFocus> getProfileTargets() {
    return [
      _buildTarget(
        identify: "profile_refresh",
        key: TutorialKeys.profileRefresh,
        title: "Manual Intelligence Refresh",
        content:
            "Triggers a full intelligence gathering cycle right now. Use this after adding new topics or watchlist items to immediately fetch fresh analysis.",
        align: ContentAlign.top,
      ),
      _buildTarget(
        identify: "profile_logout",
        key: TutorialKeys.profileLogout,
        title: "Session Logout",
        content:
            "Securely ends your current session. Your settings, watchlist, and topics are all preserved and will be waiting when you log back in.",
        align: ContentAlign.top,
        isGuide: true,
      ),
    ];
  }

  // ── Builder ───────────────────────────────────────────────────────────────

  static TargetFocus _buildTarget({
    required String identify,
    required GlobalKey key,
    required String title,
    required String content,
    ContentAlign align = ContentAlign.bottom,
    bool isGuide = false,
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
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: controller.next,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.goldAmber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isGuide ? 'GOT IT' : 'NEXT  →',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
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
