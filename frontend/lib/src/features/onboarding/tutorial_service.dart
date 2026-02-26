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
  // Order: current nav tab → manage button → scanner guide
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
        identify: "nav_scan_guide",
        key: TutorialKeys.navScan,
        title: "Up Next: Alpha Scanner",
        content:
            "Tap here to visit the Alpha Scanner — your AI-powered signal feed for opportunities, divergences, and catalysts. Tutorial continues on arrival.",
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
        title: "Alpha Scanner",
        content:
            "The Scanner is your AI signal feed. It surfaces high-conviction opportunities, sentiment divergences, and strategic catalysts from your daily briefings. Empty on first launch until a briefing cycle runs.",
        align: ContentAlign.top,
      ),
      _buildTarget(
        identify: "scanner_pulse",
        key: TutorialKeys.scannerPulse,
        title: "Live Scan Status",
        content:
            "This indicator shows the scanner is active and monitoring signals. When a briefing cycle completes, results populate the sections below automatically.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "scanner_opportunities",
        key: TutorialKeys.scannerOpportunities,
        title: "Strategic Opportunities",
        content:
            "High-conviction trade ideas identified by the AI — each with a sentiment score, time horizon, and scout analysis. Empty until your first briefing runs.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "scanner_divergences",
        key: TutorialKeys.scannerDivergences,
        title: "High-Signal Divergences",
        content:
            "Assets where AI sentiment is strongly positive but price action remains flat or down — potential early entry signals sourced from your watchlist.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "scanner_catalysts",
        key: TutorialKeys.scannerCatalysts,
        title: "Strategic Catalysts",
        content:
            "Key market events and intelligence anchors extracted from briefings that may drive near-term price movement. Tap any card to view its full report in the Vault.",
        align: ContentAlign.bottom,
      ),
      _buildTarget(
        identify: "nav_dash_guide",
        key: TutorialKeys.navDash,
        title: "Up Next: Your Profile",
        content:
            "Return to the War Room and tap the profile icon in the top-right corner to complete your orientation and configure your intelligence settings.",
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
            return ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    // Frosted dark glass panel
                    color: const Color(0xFF0C0C1A).withOpacity(0.78),
                    borderRadius: BorderRadius.circular(18),
                    border: Border(
                      // Gold accent on top for brand alignment
                      top: const BorderSide(
                        color: AppTheme.goldAmber,
                        width: 1.5,
                      ),
                      left: BorderSide(
                        color: Colors.white.withOpacity(0.10),
                        width: 1,
                      ),
                      right: BorderSide(
                        color: Colors.white.withOpacity(0.10),
                        width: 1,
                      ),
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.10),
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
                          color: Colors.white.withOpacity(0.88),
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
