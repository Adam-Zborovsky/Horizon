import 'dart:ui';
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
      // Deep navy-black shadow so the highlighted element truly pops.
      colorShadow: const Color(0xFF060610),
      opacityShadow: 0.85,
      textSkip: "SKIP",
      paddingFocus: 12,
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
        title: "Home Screen",
        content:
            "This is your main screen. It shows your daily reports, how each topic is trending, and the stocks you are tracking — all in one place.",
        align: ContentAlign.top,
      ),
      _buildTarget(
        identify: "dash_briefing",
        key: TutorialKeys.dashBriefing,
        title: "Daily Report",
        content:
            "Your latest AI-generated report appears here. It shows the top topic, a score, and a short summary. It will be empty the first time — go to your profile and tap 'Refresh Now' to get your first report.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "dash_pillars",
        key: TutorialKeys.dashPillars,
        title: "Topic Cards",
        content:
            "Each card shows a topic you are tracking and how positive or negative the news is right now. Tap any card to read the full report for that topic.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "nav_profile",
        key: TutorialKeys.navProfile,
        title: "Your Profile",
        content:
            "Tap here to open your settings — change your topics, manage your watchlist, get a fresh report, and restart this tutorial.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "nav_vault_guide",
        key: TutorialKeys.navVault,
        title: "Up Next: Report Archive",
        content:
            "Tap here to go to the Report Archive — where you can read all your past reports and filter by topic. The tutorial will continue when you arrive.",
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
        title: "Report Archive",
        content:
            "This is where all your reports are saved. You can read every report, filter by topic, and see the score, summary, and risks for each one.",
        align: ContentAlign.top,
      ),
      _buildTarget(
        identify: "vault_filter",
        key: TutorialKeys.vaultFilter,
        title: "Filter by Topic",
        content:
            "Tap one of these buttons to show only reports from that topic. New topics appear here after your first report is generated.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "vault_reports",
        key: TutorialKeys.vaultReports,
        title: "Your Reports",
        content:
            "Each report has a score, a summary, and a list of key points and risks. This list will be empty until your first report has been generated.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "nav_nexus_guide",
        key: TutorialKeys.navNexus,
        title: "Up Next: Stock Tracker",
        content:
            "Tap here to go to the Stock Tracker — where you can see live prices for the stocks you follow. The tutorial continues when you arrive.",
        align: ContentAlign.top,
        isGuide: true,
      ),
    ];
  }

  // ── Nexus ─────────────────────────────────────────────────────────────────
  // Order: current nav tab → manage button → scanner guide
  static List<TargetFocus> getNexusTargets() {
    return [
      _buildTarget(
        identify: "nav_nexus",
        key: TutorialKeys.navNexus,
        title: "Stock Tracker",
        content:
            "This screen shows live prices for every stock in your watchlist. It will be empty until you add stocks — tap the search bar to get started.",
        align: ContentAlign.top,
      ),
      _buildTarget(
        identify: "nexus_manage",
        key: TutorialKeys.nexusManage,
        title: "Add Stocks",
        content:
            "Tap here to search for and add stocks to your watchlist. Each stock will then show its current price, today's change, and a small price chart.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "nav_scan_guide",
        key: TutorialKeys.navScan,
        title: "Up Next: Signal Feed",
        content:
            "Tap here to go to the Signal Feed — where the AI shows you trade ideas, unusual patterns, and important market events. Tutorial continues on arrival.",
        align: ContentAlign.top,
        isGuide: true,
      ),
    ];
  }

  // ── Scanner ───────────────────────────────────────────────────────────────
  // Order: current nav tab → pulse → opportunities → divergences → catalysts → dash guide
  static List<TargetFocus> getScannerTargets() {
    return [
      _buildTarget(
        identify: "nav_scan",
        key: TutorialKeys.navScan,
        title: "Signal Feed",
        content:
            "This screen shows the best trade ideas and key events found by the AI in your daily reports. It will be empty until your first report has been generated.",
        align: ContentAlign.top,
      ),
      _buildTarget(
        identify: "scanner_pulse",
        key: TutorialKeys.scannerPulse,
        title: "Scan Status",
        content:
            "This bar shows that the system is active and looking for signals. New results appear here automatically after each report is generated.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "scanner_opportunities",
        key: TutorialKeys.scannerOpportunities,
        title: "Trade Ideas",
        content:
            "The AI picks the best stock opportunities from your reports and shows them here — each with a score, a time frame, and a short explanation.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "scanner_divergences",
        key: TutorialKeys.scannerDivergences,
        title: "Price vs. Sentiment Gap",
        content:
            "These are stocks where the AI sees positive news, but the price has not moved up yet. This can sometimes be an early buying signal.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "scanner_catalysts",
        key: TutorialKeys.scannerCatalysts,
        title: "Key Market Events",
        content:
            "Important news events and announcements that could affect stock prices soon. Tap any card to read the full report.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "nav_dash_guide",
        key: TutorialKeys.navDash,
        title: "Up Next: Your Profile",
        content:
            "Go back to the home screen and tap the profile icon in the top-right corner to finish setup and configure your settings.",
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
        title: "Refresh Now",
        content:
            "Tap this to get a new report right away. Use it after adding new topics or stocks to see fresh results immediately.",
        align: ContentAlign.top,
      ),
      _buildTarget(
        identify: "profile_logout",
        key: TutorialKeys.profileLogout,
        title: "Log Out",
        content:
            "Tap here to log out. All your settings, topics, and watchlist will be saved and ready when you log back in.",
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
            return ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    // Frosted dark glass panel
                    color: const Color(0xFF0C0C1A).withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(18),
                    border: Border(
                      // Gold accent on top for brand alignment
                      top: const BorderSide(
                        color: AppTheme.goldAmber,
                        width: 1.5,
                      ),
                      left: BorderSide(
                        color: Colors.white.withValues(alpha: 0.10),
                        width: 1,
                      ),
                      right: BorderSide(
                        color: Colors.white.withValues(alpha: 0.10),
                        width: 1,
                      ),
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.10),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.goldAmber,
                          fontSize: 13,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        content,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: controller.next,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 9,
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
                              fontSize: 12,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
      shape: ShapeLightFocus.RRect,
      radius: 15,
    );
  }
}
