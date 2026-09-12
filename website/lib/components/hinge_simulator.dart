import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

@client
class HingeSimulator extends StatefulComponent {
  const HingeSimulator({super.key});

  @override
  State<HingeSimulator> createState() => _HingeSimulatorState();
}

class _HingeSimulatorState extends State<HingeSimulator> {
  double angle = 110;

  String get posture => switch (angle) {
    <= 2 => 'closed',
    >= 178 => 'flat',
    _ => 'halfOpened',
  };

  @override
  Component build(BuildContext context) => Component.fragment(<Component>[
    Document.head(children: <Component>[Style(styles: _styles)]),
    section(
      classes: 'hinge-simulator',
      attributes: const {'aria-label': 'Interactive hinge-angle simulator'},
      <Component>[
        div(classes: 'sim-stage', <Component>[
          div(
            classes: 'sim-panel sim-left',
            styles: Styles(raw: {'transform': 'perspective(700px) rotateY(${(180 - angle) / 2}deg)'}),
            <Component>[const Component.text('Flutter')],
          ),
          div(classes: 'sim-hinge', <Component>[]),
          div(
            classes: 'sim-panel sim-right',
            styles: Styles(raw: {'transform': 'perspective(700px) rotateY(-${(180 - angle) / 2}deg)'}),
            <Component>[const Component.text('Native')],
          ),
        ]),
        label(htmlFor: 'hinge-angle', <Component>[
          Component.text('${angle.round()}° · $posture'),
        ]),
        input<double>(
          id: 'hinge-angle',
          type: InputType.range,
          value: angle.toString(),
          attributes: const {'min': '0', 'max': '180', 'step': '1'},
          onInput: (value) => setState(() => angle = value),
        ),
        pre(<Component>[
          code(<Component>[
            Component.text('{ "hingeAngle": ${angle.round()}, "posture": "$posture" }'),
          ]),
        ]),
      ],
    ),
  ]);

  static final List<StyleRule> _styles = <StyleRule>[
    css('.hinge-simulator').styles(
      padding: Padding.all(1.4.rem),
      margin: Margin.symmetric(vertical: 1.5.rem),
      radius: BorderRadius.circular(1.rem),
      border: Border.all(color: const Color('#0d94884f'), width: 1.px),
      backgroundColor: const Color('#0d948810'),
    ),
    css('.sim-stage').styles(
      display: Display.flex,
      height: 12.rem,
      alignItems: AlignItems.center,
      justifyContent: JustifyContent.center,
      padding: Padding.all(1.rem),
    ),
    css('.sim-panel').styles(
      display: Display.flex,
      width: 9.rem,
      height: 10.rem,
      alignItems: AlignItems.center,
      justifyContent: JustifyContent.center,
      fontWeight: FontWeight.w700,
      color: const Color('#ffffff'),
      backgroundColor: const Color('#008c88'),
      border: Border.all(color: const Color('#5eead4'), width: 1.px),
      raw: const {
        'background-image': 'linear-gradient(135deg, #006e6b, #00b8b2)',
        'transition': 'transform 80ms linear',
        'transform-origin': 'center center',
      },
    ),
    css('.sim-left').styles(raw: const {'border-radius': '.8rem 0 0 .8rem', 'transform-origin': 'right center'}),
    css('.sim-right').styles(raw: const {'border-radius': '0 .8rem .8rem 0', 'transform-origin': 'left center'}),
    css('.sim-hinge').styles(
      width: .55.rem,
      height: 10.2.rem,
      radius: BorderRadius.circular(.4.rem),
      backgroundColor: const Color('#22d3ee'),
      raw: const {'box-shadow': '0 0 1rem #22d3ee88'},
    ),
    css('.hinge-simulator label').styles(display: Display.block, fontWeight: FontWeight.w700, textAlign: TextAlign.center),
    css('.hinge-simulator input').styles(width: 100.percent, margin: Margin.symmetric(vertical: .8.rem)),
    css('.hinge-simulator pre').styles(margin: Margin.zero),
  ];
}
