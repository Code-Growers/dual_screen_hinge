import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/components/sidebar.dart';
import 'package:jaspr_content/components/sidebar_toggle_button.dart';
import 'package:jaspr_content/components/theme_toggle.dart';
import 'package:jaspr_content/jaspr_content.dart';

class HingeDocsHeader extends StatelessComponent {
  const HingeDocsHeader({super.key});

  @override
  Component build(BuildContext context) => Component.fragment(<Component>[
    Document.head(children: <Component>[
      Style(styles: _styles),
      meta(name: 'theme-color', content: '#008c88'),
      meta(name: 'og:image', content: 'assets/social-preview.png'),
    ]),
    header(classes: 'hinge-header', <Component>[
      const SidebarToggleButton(),
      a(
        classes: 'hinge-brand',
        href: './',
        attributes: const {'aria-label': 'dual_screen_hinge home'},
        <Component>[
          img(src: 'assets/logo.png', alt: 'Abstract teal folding-device logo'),
          span(<Component>[const Component.text('dual_screen_hinge')]),
        ],
      ),
      nav(
        classes: 'hinge-links',
        attributes: const {'aria-label': 'Primary navigation'},
        <Component>[
          a(href: 'guides/getting-started', <Component>[const Component.text('Guides')]),
          a(
            href: 'https://pub.dev/packages/dual_screen_hinge',
            attributes: const {'target': '_blank', 'rel': 'noreferrer'},
            <Component>[const Component.text('pub.dev')],
          ),
          a(
            href: 'https://github.com/Code-Growers/dual_screen_hinge',
            attributes: const {'target': '_blank', 'rel': 'noreferrer'},
            <Component>[const Component.text('GitHub')],
          ),
          const ThemeToggle(),
        ],
      ),
    ]),
  ]);

  static final List<StyleRule> _styles = <StyleRule>[
    css('.hinge-header').styles(
      display: Display.flex,
      height: 4.rem,
      padding: Padding.symmetric(horizontal: 1.rem, vertical: .25.rem),
      alignItems: AlignItems.center,
      gap: Gap.column(1.rem),
      border: Border.only(bottom: BorderSide(color: const Color('#0f766e2a'), width: 1.px)),
      backgroundColor: const Color('color-mix(in srgb, var(--background) 90%, transparent)'),
    ),
    css('.hinge-brand').styles(
      display: Display.inlineFlex,
      alignItems: AlignItems.center,
      gap: Gap.column(.7.rem),
      flex: Flex(basis: 17.rem),
      fontWeight: FontWeight.w700,
      textDecoration: TextDecoration.none,
    ),
    css('.hinge-brand img').styles(width: 2.8.rem, height: 2.8.rem, raw: const {'object-fit': 'contain'}),
    css('.hinge-links').styles(
      display: Display.flex,
      alignItems: AlignItems.center,
      justifyContent: JustifyContent.end,
      gap: Gap.column(.4.rem),
      flex: const Flex(grow: 1),
    ),
    css('.hinge-links > a').styles(
      padding: Padding.symmetric(horizontal: .65.rem, vertical: .5.rem),
      radius: BorderRadius.circular(.45.rem),
      textDecoration: TextDecoration.none,
    ),
    css('.hinge-links > a:hover').styles(backgroundColor: const Color('#0d948818')),
    css.media(MediaQuery.all(maxWidth: 640.px), <StyleRule>[
      css('.hinge-links > a').styles(display: Display.none),
    ]),
  ];
}

class HingeDocsSidebar extends StatelessComponent {
  const HingeDocsSidebar({super.key});

  static const links = <({String title, String href})>[
    (title: 'Getting started', href: 'guides/getting-started'),
    (title: 'Animation recipes', href: 'guides/animation-recipes'),
    (title: 'MediaQuery responsibilities', href: 'guides/media-query'),
    (title: 'Android capabilities', href: 'guides/android'),
    (title: 'iPhone Duo', href: 'guides/iphone-duo'),
    (title: 'Display modes', href: 'guides/display-modes'),
    (title: 'Secondary entrypoints', href: 'guides/secondary-entrypoints'),
    (title: 'Testing', href: 'guides/testing'),
    (title: 'Troubleshooting', href: 'guides/troubleshooting'),
    (title: 'Migrate from dual_screen', href: 'guides/migration'),
    (title: 'Device matrix', href: 'guides/device-matrix'),
    (title: 'AI agents', href: 'guides/ai-agents'),
  ];

  @override
  Component build(BuildContext context) {
    final route = context.page.url.replaceFirst(RegExp(r'^/'), '');
    return Sidebar(
      currentRoute: route.isEmpty ? './' : route,
      groups: <SidebarGroup>[
        const SidebarGroup(links: <SidebarLink>[SidebarLink(text: 'Overview', href: './')]),
        SidebarGroup(
          title: 'Guides',
          links: <SidebarLink>[
            for (final link in links) SidebarLink(text: link.title, href: link.href),
          ],
        ),
      ],
    );
  }
}

class HingeDocsFooter extends StatelessComponent {
  const HingeDocsFooter({super.key});

  @override
  Component build(BuildContext context) => footer(<Component>[
    p(<Component>[
      const Component.text('MIT licensed · Built by Code Growers · '),
      a(href: 'llms.txt', <Component>[const Component.text('llms.txt')]),
    ]),
  ]);
}
