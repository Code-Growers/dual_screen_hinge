library;

import 'package:jaspr/server.dart';
import 'package:jaspr_content/components/callout.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

import 'components/docs_chrome.dart';
import 'components/hinge_simulator.dart';
import 'main.server.options.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);
  runApp(
    ContentApp(
      templateEngine: MustacheTemplateEngine(),
      parsers: const <PageParser>[MarkdownParser()],
      extensions: const <PageExtension>[TableOfContentsExtension()],
      components: <CustomComponent>[
        Callout(),
        CustomComponent(
          pattern: 'HingeSimulator',
          builder: (_, _, _) => const HingeSimulator(),
        ),
      ],
      layouts: const <PageLayout>[
        DocsLayout(
          header: HingeDocsHeader(),
          sidebar: HingeDocsSidebar(),
          footer: HingeDocsFooter(),
        ),
      ],
      theme: ContentTheme(
        primary: ThemeColor(ThemeColors.teal.$600, dark: ThemeColors.teal.$300),
        background: ThemeColor(ThemeColors.slate.$50, dark: ThemeColors.slate.$950),
      ),
    ),
  );
}
