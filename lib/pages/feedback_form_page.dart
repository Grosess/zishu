import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart' show DuotoneThemeExtension;

class FeedbackFormPage extends StatefulWidget {
  const FeedbackFormPage({super.key});

  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    
    // Show code dialog after closing form, not on entry
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      // Don't show dialog on entry - wait for user to close form
    });
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });
            
            // Inject viewport meta tag to prevent zoom
            await _controller.runJavaScript('''
              var viewport = document.querySelector('meta[name="viewport"]');
              if (!viewport) {
                viewport = document.createElement('meta');
                viewport.name = 'viewport';
                document.head.appendChild(viewport);
              }
              viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            ''');
            
            // Inject CSS to style the form
            await _injectCustomCSS();
          },
        ),
      )
      ..loadRequest(Uri.parse('https://docs.google.com/forms/d/e/1FAIpQLSdGjp1NhjeoLslMKkrN0RkfSuqy6_YCDUkt14rqy55Zf4ap3w/viewform?embedded=true'));
  }

  Future<void> _injectCustomCSS() async {
    // Check if we're in dark mode (either system dark mode or black/blue duotone)
    final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final duotoneExt = isDuotone ? Theme.of(context).extension<DuotoneThemeExtension>()! : null;
    final isBlackBackground = (isDuotone && duotoneExt?.duotoneColor1 == Colors.black) || (!isDuotone && isDarkMode);
    
    String primaryColor = '#2196F3'; // Always blue
    String backgroundColor = isBlackBackground ? '#000000' : '#FFFFFF';
    // In duotone mode, always use blue. In regular dark mode, use white
    String textColor = isDuotone ? '#2196F3' : (isBlackBackground ? '#FFFFFF' : '#2196F3');
    String surfaceColor = isBlackBackground ? '#1A1A1A' : '#F5F5F5'; // Slightly different for contrast
    String borderColor = isBlackBackground ? '#333333' : '#E0E0E0';
    
    final css = '''
      var style = document.createElement('style');
      style.innerHTML = `
        /* Override ALL blue colors with theme colors */
        :root {
          --mdc-theme-primary: $primaryColor !important;
          --mdc-theme-secondary: $primaryColor !important;
          --primary-color: $primaryColor !important;
          --goog-blue-500: $primaryColor !important;
          --goog-blue-600: $primaryColor !important;
          --goog-blue-700: $primaryColor !important;
        }
        
        /* Background colors */
        body, html {
          background-color: $backgroundColor !important;
          background: $backgroundColor !important;
        }
        
        .freebirdFormviewerViewFormContent,
        .freebirdFormviewerViewFormContentWrapper,
        .freebirdFormviewerViewCenteredContent,
        .freebirdFormviewerViewItemsItemItem,
        .freebirdFormviewerViewHeaderHeader,
        .freebirdFormviewerViewFormCard,
        .freebirdFormviewerComponentsQuestionBaseRoot,
        .freebirdBackground,
        .freebirdFormviewerViewItemsPagebreakDescriptionText,
        .freebirdFormviewerViewItemsPagebreakDescriptionText + div,
        .freebirdFormviewerViewFooterFooter,
        .freebirdFormviewerViewFooterDisclosure {
          background-color: $backgroundColor !important;
          background: $backgroundColor !important;
        }
        
        /* Question item backgrounds - comprehensive */
        .freebirdFormviewerViewNumberedItemContainer,
        .freebirdFormviewerComponentsQuestionBaseRoot,
        .freebirdFormviewerViewItemsItemItem,
        .freebirdFormviewerViewItemsItemItemContainer,
        .freebirdFormviewerComponentsQuestionBaseHeader {
          background-color: $surfaceColor !important;
          border: 1px solid $borderColor !important;
          border-radius: 8px !important;
        }
        
        /* Ensure question containers have proper padding */
        .freebirdFormviewerViewNumberedItemContainer {
          padding: 16px !important;
          margin-bottom: 16px !important;
        }
        
        /* Remove any white backgrounds */
        [style*="background-color: rgb(255, 255, 255)"],
        [style*="background-color: white"],
        [style*="background: white"],
        [style*="background: rgb(255, 255, 255)"] {
          background-color: $backgroundColor !important;
        }
        
        /* Text colors - be more specific */
        .freebirdFormviewerComponentsQuestionBaseTitle,
        .freebirdFormviewerComponentsQuestionBaseTitleDescTitle,
        .freebirdFormviewerComponentsQuestionBaseDescription,
        .freebirdFormviewerViewItemsItemItemTitle,
        .freebirdFormviewerViewItemsItemItemTitleDescTitle {
          color: $textColor !important;
        }
        
        /* Fix all blue elements */
        .quantumWizButtonPaperbuttonContent,
        .quantumWizButtonPaperbuttonLabel,
        .freebirdThemedText,
        .freebirdFormviewerViewNavigationClearButton,
        .freebirdFormviewerViewNavigationSubmitButton,
        .freebirdFormviewerViewNavigationPasswordWarning a,
        .freebirdFormviewerViewHeaderRequiredLegend,
        .freebirdFormviewerComponentsQuestionRadioChoice.isChecked .docssharedWizToggleLabeledContent,
        .freebirdFormviewerComponentsQuestionCheckboxChoice.isChecked .docssharedWizToggleLabeledContent,
        .freebirdFormviewerComponentsQuestionSelectSelect,
        .quantumWizMenuPaperselectOption.isSelected,
        .exportButtonArea,
        .freebirdFormviewerViewHeaderHeaderSubmitButton,
        a, a:visited, a:hover, a:active {
          color: $primaryColor !important;
        }
        
        /* Fix radio and checkbox colors */
        .appsMaterialWizToggleRadiogroupRadioButtonContainer.isChecked .appsMaterialWizToggleRadiogroupOffRadio,
        .appsMaterialWizToggleCheckboxCheckboxContainer.isChecked .appsMaterialWizToggleCheckboxCheckmark {
          color: $primaryColor !important;
          fill: $primaryColor !important;
        }
        
        .quantumWizTogglePaperradioRadioContainer.isChecked .quantumWizTogglePaperradioRadioOuterCircle,
        .quantumWizTogglePapercheckboxCheckboxContainer.isChecked .quantumWizTogglePapercheckboxCheckmark {
          border-color: $primaryColor !important;
          background-color: $primaryColor !important;
        }
        
        /* Progress indicators */
        .freebirdFormviewerViewNavigationProgress .freebirdFormviewerViewNavigationProgressIndicator {
          background-color: $primaryColor !important;
        }
        
        /* Focus states */
        .mdc-text-field--focused:not(.mdc-text-field--disabled) .mdc-floating-label,
        .mdc-text-field--focused .mdc-text-field__input {
          color: $primaryColor !important;
        }
        
        .mdc-text-field--focused:not(.mdc-text-field--disabled) .mdc-line-ripple::after {
          border-bottom-color: $primaryColor !important;
        }
        
        /* Clear form button */
        .freebirdFormviewerViewNavigationClearButton {
          color: $primaryColor !important;
        }
        
        /* Google sign in text */
        .freebirdFormviewerViewHeaderSignInButton,
        .freebirdFormviewerViewHeaderSignInText {
          color: $textColor !important;
        }
        
        /* Header text */
        .freebirdFormviewerViewHeaderTitleRow,
        .freebirdFormviewerViewHeaderTitle,
        .freebirdFormviewerViewHeaderDescription {
          color: $textColor !important;
        }
        
        /* Additional overrides for any remaining blue */
        .mdc-button:not(:disabled),
        .mdc-button--unelevated:not(:disabled),
        .quantumWizButtonEl:not(:disabled) {
          color: $primaryColor !important;
        }
        
        .mdc-button--unelevated:not(:disabled) {
          background-color: $primaryColor !important;
          color: $backgroundColor !important;
        }
        
        /* Submit button specific override */
        .freebirdFormviewerViewNavigationSubmitButton .appsMaterialWizButtonPaperbuttonContent,
        .freebirdFormviewerViewNavigationSubmitButton .appsMaterialWizButtonPaperbuttonLabel,
        .freebirdFormviewerViewNavigationSubmitButton,
        .quantumWizButtonPaperbuttonFilled,
        .quantumWizButtonPaperbuttonFilled .quantumWizButtonPaperbuttonContent {
          background-color: $primaryColor !important;
          color: $backgroundColor !important;
        }
        
        /* Header top bar */
        .freebirdFormviewerViewHeaderHeader::before,
        .freebirdHeaderMast {
          background-color: $primaryColor !important;
        }
        
        /* Text input fields */
        .quantumWizTextinputPaperinputInput,
        .quantumWizTextinputPapertextareaInput {
          caret-color: $primaryColor !important;
        }
        
        .quantumWizTextinputPaperinputUnderline::before,
        .quantumWizTextinputPapertextareaUnderline::before {
          background-color: $primaryColor !important;
        }
        
        .quantumWizTextinputPaperinputInput:focus ~ .quantumWizTextinputPaperinputUnderline::after,
        .quantumWizTextinputPapertextareaInput:focus ~ .quantumWizTextinputPapertextareaUnderline::after {
          background-color: $primaryColor !important;
        }
        
        /* Clear form button override */
        .freebirdFormviewerViewNavigationClearButton .appsMaterialWizButtonPaperbuttonContent {
          color: $primaryColor !important;
        }
        
        /* Override blue in ripple effects */
        .mdc-ripple-upgraded--foreground-activation,
        .mdc-ripple-upgraded--foreground-deactivation {
          background-color: $primaryColor !important;
        }
        
        /* Override blue in Material icons */
        .material-icons-extended {
          color: $primaryColor !important;
        }
        
        /* Fix selection highlights */
        ::selection {
          background-color: $primaryColor !important;
          color: $backgroundColor !important;
        }
        
        /* Input field labels */
        .quantumWizTextinputPaperinputFloatingLabel.quantumWizTextinputPaperinputFocused,
        .quantumWizTextinputPapertextareaFloatingLabel.quantumWizTextinputPapertextareaFocused {
          color: $primaryColor !important;
        }
        
        /* Fix white question containers */
        .freebirdFormviewerViewItemsItemItem > div:first-child,
        .freebirdFormviewerComponentsQuestionBaseRoot > div,
        .freebirdFormviewerViewItemsItemItem > div,
        .freebirdFormviewerViewItemsItemItemContainer > div {
          background-color: $surfaceColor !important;
        }
        
        /* Force question backgrounds in dark mode */
        ${isBlackBackground ? '''
          .freebirdFormviewerViewItemsItemItem {
            background-color: #1A1A1A !important;
            border-color: #333333 !important;
          }
        ''' : ''}
        
        /* Fix star rating colors - comprehensive */
        .quantumWizTogglePaperstarIcon,
        .quantumWizTogglePaperstarIcon svg,
        .quantumWizTogglePaperstarIcon path,
        .quantumWizTogglePaperstarIcon polygon,
        .appsMaterialWizToggleRatingstarIcon,
        .appsMaterialWizToggleRatingstarIcon svg,
        .appsMaterialWizToggleRatingstarIcon path,
        .appsMaterialWizToggleRatingstarEl.isStarFilled svg path,
        .appsMaterialWizToggleRatingstarEl svg path {
          color: $primaryColor !important;
          fill: $primaryColor !important;
          stroke: $primaryColor !important;
        }
        
        /* Override star SVG paths specifically */
        svg[viewBox="0 0 24 24"] path[fill="#fbbc04"],
        svg[viewBox="0 0 24 24"] path[d*="M12"],
        path[fill="#fbbc04"],
        path[fill="#FBBC04"],
        .isStarFilled svg path,
        .isStarFilled path,
        .appsMaterialWizToggleRatingstarEl.isStarFilled path {
          fill: $primaryColor !important;
        }
        
        /* Force all star paths to blue */
        .appsMaterialWizToggleRatingstarEl path {
          fill: $primaryColor !important;
          stroke: $primaryColor !important;
        }
        
        /* Override inline styles for stars */
        [style*="fill: rgb(251, 188, 4)"],
        [style*="fill:#fbbc04"] {
          fill: $primaryColor !important;
        }
        
        /* Fix all icons to be blue */
        .material-icons,
        .material-icons-extended {
          color: $primaryColor !important;
        }
        
        /* Fix checkbox and radio button selections */
        .quantumWizTogglePapercheckboxInk,
        .quantumWizTogglePaperradioInk,
        .quantumWizTogglePapercheckboxInnerBox.quantumWizTogglePapercheckboxChecked,
        .quantumWizTogglePaperradioOnRadio.quantumWizTogglePaperradioOn {
          background-color: ${isBlackBackground ? '#000000' : primaryColor} !important;
          border-color: $primaryColor !important;
        }
        
        /* Checkbox inner box */
        .quantumWizTogglePapercheckboxInnerBox {
          background-color: ${isBlackBackground ? '#000000' : '#FFFFFF'} !important;
        }
        
        /* Fix selection backgrounds */
        .isChecked .quantumWizTogglePapercheckboxCheckmark,
        .isChecked .quantumWizTogglePaperradioRadio {
          color: $primaryColor !important;
        }
        
        /* Footer background */
        .freebirdFormviewerViewFooterFooter,
        .freebirdFormviewerViewFooterFooterContent,
        .freebirdFormviewerViewFooterDisclosure,
        .freebirdFormviewerViewFooterEmbeddedFooter {
          background-color: $backgroundColor !important;
        }
        
        /* Google disclaimer section */
        .freebirdFormviewerViewFooterFooter > div,
        .freebirdFormviewerViewFooterDisclosure > div {
          background-color: $backgroundColor !important;
        }
        
        /* Hide footer in light mode, style in dark mode */
        ${!isBlackBackground ? '''
          .freebirdFormviewerViewFooterFooter,
          .freebirdFormviewerViewFooterDisclosure {
            display: none !important;
          }
        ''' : '''
          /* "Forms" text and menu */
          .freebirdFormviewerViewFooterFooterText,
          .freebirdFormviewerViewFooterFooterMenu {
            color: #000000 !important;
          }
          
          /* Three dots menu icon */
          .freebirdFormviewerViewFooterFooterMenu svg,
          .freebirdFormviewerViewFooterFooterMenu path {
            fill: #000000 !important;
          }
        '''}
        
        /* Ensure all text is visible */
        input, textarea, select, option {
          color: $textColor !important;
        }
        
        /* Fix dropdown backgrounds */
        .quantumWizMenuPaperselectPopup,
        .quantumWizMenuPaperselectOption {
          background-color: $surfaceColor !important;
          color: $textColor !important;
        }
        
        /* Fix header decorative bar */
        .freebirdFormviewerViewHeaderHeaderDecorative {
          background-color: $primaryColor !important;
          height: 10px !important;
        }
        
        /* Override any blue hex colors directly */
        [style*="#1a73e8"],
        [style*="#1976d2"],
        [style*="#4285f4"] {
          color: $primaryColor !important;
        }
        
        /* Prevent zoom on input focus */
        input[type="text"],
        input[type="email"],
        input[type="number"],
        input[type="tel"],
        textarea {
          font-size: 16px !important;
        }
        
        /* Dark mode specific fixes */
        ${isBlackBackground ? '''
          /* Force dark backgrounds everywhere */
          * {
            background-color: transparent !important;
          }
          
          body,
          .freebirdFormviewerViewFormContent,
          .freebirdFormviewerViewCenteredContent {
            background-color: #000000 !important;
          }
          
          /* Make sure text is visible - white in dark mode, blue in duotone */
          .freebirdFormviewerComponentsQuestionBaseTitle,
          .freebirdFormviewerComponentsQuestionBaseTitleDescTitle,
          .freebirdFormviewerComponentsQuestionBaseDescription,
          .freebirdFormviewerComponentsQuestionBaseTitle span,
          .freebirdFormviewerComponentsQuestionBaseTitleDescTitle span,
          .freebirdFormviewerComponentsQuestionBaseDescription span {
            color: ${isDuotone ? '#2196F3' : '#FFFFFF'} !important;
          }
          
          /* Force all question containers to dark background */
          .freebirdFormviewerViewNumberedItemContainer > div,
          .freebirdFormviewerViewItemsItemItem > div {
            background-color: #1A1A1A !important;
          }
          
          /* Ensure footer is dark */
          .freebirdFormviewerViewFooterFooter,
          .freebirdFormviewerViewFooterDisclosure,
          .freebirdFormviewerViewFooterFooter > div {
            background-color: #000000 !important;
          }
        ''' : ''}
      `;
      document.head.appendChild(style);
    ''';
    
    await _controller.runJavaScript(css);
  }

  @override
  Widget build(BuildContext context) {
    final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
    
    return Scaffold(
      backgroundColor: isDuotone
          ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1
          : Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: isDuotone
                    ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1
                    : Theme.of(context).scaffoldBackgroundColor,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            // Exit button in top left
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: IconButton(
                  icon: Container(
                    decoration: BoxDecoration(
                      color: isDuotone
                          ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor1!.withValues(alpha: 0.9)
                          : Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: isDuotone
                          ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  onPressed: () async {
                    // Mark that user has completed the form
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('has_completed_feedback_form', true);
                    
                    // Just close the form, no code prompt
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}