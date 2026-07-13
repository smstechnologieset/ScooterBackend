import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/widgets/isoko_logo.dart';

const _green = AppTheme.primaryGreen;
const _panel = AppTheme.panelBackground;
const _surface = AppTheme.surfaceElevated;
const _muted = AppTheme.textSecondary;
const _subtle = AppTheme.textMuted;

const _softShadow = [
  BoxShadow(
    color: Color(0x66000000),
    blurRadius: 26,
    offset: Offset(0, 16),
  ),
];

class MockScooter {
  final String id;
  final String distance;
  final String range;

  const MockScooter(this.id, this.distance, this.range);
}

const _scooters = [
  MockScooter('BK2113', '3.2 km', '30-35km'),
  MockScooter('BK3113', '3.2 km', '20-25km'),
  MockScooter('BK2103', '1.8 km', '25-30km'),
];

class MockAuthScreen extends StatefulWidget {
  final bool signUp;

  const MockAuthScreen({super.key, this.signUp = false});

  @override
  State<MockAuthScreen> createState() => _MockAuthScreenState();
}

class _MockAuthScreenState extends State<MockAuthScreen> {
  final phone = TextEditingController(text: '912345678');
  final name = TextEditingController(text: 'John Doe');
  final email = TextEditingController(text: 'Example@gmail.com');

  @override
  void dispose() {
    phone.dispose();
    name.dispose();
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.signUp) {
      return _PlainScreen(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BackButton(),
            const SizedBox(height: 28),
            const _Title('Sign Up Now'),
            const SizedBox(height: 8),
            const _BodyText('Looks like you\'re not registered yet.'),
            const SizedBox(height: 36),
            _Field(label: 'Phone Number', controller: phone),
            _Field(label: 'Full name', controller: name),
            _Field(label: 'Email', controller: email),
            const SizedBox(height: 28),
            _PrimaryButton(
              label: 'Continue',
              onPressed: () => context.go('/enable-location'),
            ),
            const Spacer(),
            const Center(
              child: Text.rich(
                TextSpan(
                  text: 'By continuing you agree to our\n',
                  children: [
                    TextSpan(
                      text: 'Terms and Conditions.',
                      style: TextStyle(color: _green),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(36, 42, 36, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 96,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const IsokoLogo(height: 68),
                      Positioned(
                        right: -100,
                        top: -18,
                        child:
                            Image.asset('assets/images/bike.png', width: 230),
                      ),
                    ],
                  ),
                  const SizedBox(height: 92),
                  const _BodyText('Hello,'),
                  const SizedBox(height: 8),
                  const _Title('Sign in Now'),
                  const SizedBox(height: 60),
                  _Field(label: 'Enter Phone Number', controller: phone),
                  const SizedBox(height: 16),
                  _PrimaryButton(
                    label: 'Continue',
                    onPressed: () => context.go('/enable-location'),
                  ),
                  const SizedBox(height: 42),
                  const Center(child: _BodyText('Or Continue with')),
                  const SizedBox(height: 18),
                  _SocialButton(
                    icon: Icons.g_mobiledata,
                    label: 'Continue with Google',
                    onPressed: () => context.go('/enable-location'),
                  ),
                  const SizedBox(height: 14),
                  _SocialButton(
                    icon: Icons.apple,
                    label: 'Continue with Apple',
                    onPressed: () => context.go('/enable-location'),
                  ),
                  const Spacer(),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/sign-up'),
                      child: const Text(
                        'Dont have an account?',
                        style: TextStyle(
                            color: _muted, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PermissionScreen extends StatelessWidget {
  final bool camera;

  const PermissionScreen({super.key, this.camera = false});

  @override
  Widget build(BuildContext context) {
    return _MapScaffold(
      showMarkers: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: _BottomPanel(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -70,
                top: -88,
                child: Image.asset('assets/images/bike.png', width: 180),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Title(camera
                      ? 'Scan Isoko\nscooter'
                      : 'Get Isoko\nAnywhere.....'),
                  const SizedBox(height: 24),
                  _BodyText(
                    camera
                        ? 'Please allow us to use your camera to\nscan scooters available.'
                        : 'Please allow us to use your location to\nshow nearby scooters available',
                  ),
                  const SizedBox(height: 26),
                  _PrimaryButton(
                    label: camera ? 'Enable Camera' : 'Enable Location',
                    onPressed: () =>
                        context.go(camera ? '/scan-qr' : '/find-scooter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FindScooterScreen extends StatelessWidget {
  final bool listOpen;

  const FindScooterScreen({super.key, this.listOpen = false});

  @override
  Widget build(BuildContext context) {
    return _MapScaffold(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: _BottomPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LocationHeader(distance: listOpen ? '3.2km' : '3.2km'),
              if (listOpen) ...[
                const SizedBox(height: 18),
                SizedBox(
                  height: 126,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) =>
                        _ScooterMiniCard(_scooters[index]),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: _scooters.length,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _ScanButton(
                onPressed: () =>
                    context.go(listOpen ? '/enable-camera' : '/scooter-list'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QrScanScreen extends StatelessWidget {
  const QrScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PhotoLikeScreen(
      title: 'Scan to unlock',
      subtitle: 'Scan qr code found on the scooter',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pedal_bike, color: Colors.white, size: 72),
          const SizedBox(height: 22),
          Container(
            width: 164,
            height: 164,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: CustomPaint(painter: _QrPainter()),
          ),
          const SizedBox(height: 58),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CircleAction(
                label: 'Bike Num',
                icon: Icons.dialpad,
                onTap: () => context.go('/unlock-number'),
              ),
              _CircleAction(
                  label: 'Torch', icon: Icons.flashlight_on, onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class UnlockNumberScreen extends StatelessWidget {
  const UnlockNumberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlainScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BackButton(),
          const SizedBox(height: 34),
          const Center(child: Icon(Icons.edit, color: Colors.white, size: 48)),
          const SizedBox(height: 22),
          const Center(child: _Title('Unlock Using bike number')),
          const SizedBox(height: 78),
          const Text('Enter bike number',
              style: TextStyle(color: _muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          const TextField(
            controller: null,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(hintText: 'BK-2134'),
          ),
          const SizedBox(height: 28),
          Center(
            child: SizedBox(
              width: 160,
              child: _PrimaryButton(
                label: 'Unlock',
                onPressed: () => context.go('/unlocking'),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class UnlockingScreen extends StatelessWidget {
  const UnlockingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlainScreen(
      child: Column(
        children: [
          const Spacer(),
          const IsokoLogo(height: 48),
          const SizedBox(height: 44),
          const _Title('Unlocking...'),
          const SizedBox(height: 12),
          const _BodyText('Get ready to ride'),
          const Spacer(),
          _ParkingRules(
            button: _PrimaryButton(
              label: 'Unlocked',
              onPressed: () => context.go('/unlocked'),
            ),
          ),
        ],
      ),
    );
  }
}

class BikeUnlockedScreen extends StatelessWidget {
  const BikeUnlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _MapScaffold(
      showMarkers: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: _BottomPanel(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -70,
                top: -80,
                child: Image.asset('assets/images/bike.png', width: 170),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Title('Isoko BK2113'),
                  const SizedBox(height: 24),
                  const Text(
                    'Bike has been unlocked',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 58),
                  Center(
                    child: SizedBox(
                      width: 170,
                      child: _PrimaryButton(
                        label: 'Start Ride',
                        onPressed: () => context.go('/start-ride'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StartRideScreen extends StatelessWidget {
  const StartRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlainScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Title('Isoko BK2130'),
                  SizedBox(height: 10),
                  _BodyText('Ready to go'),
                  SizedBox(height: 30),
                  _Metric(
                      label: 'Battery Level',
                      value: '90%',
                      icon: Icons.battery_full),
                  SizedBox(height: 26),
                  _Metric(
                      label: 'Range up to', value: '30-35km', icon: Icons.bolt),
                ],
              ),
              Positioned(
                right: -110,
                top: 42,
                child: Image.asset('assets/images/bike.png', width: 250),
              ),
            ],
          ),
          const SizedBox(height: 38),
          const Divider(color: Colors.white),
          const SizedBox(height: 26),
          const Text('Fare will be',
              style: TextStyle(color: _muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Fare(label: 'Fixed Rent', value: '\$5.00'),
              _Fare(label: 'Per km', value: '\$0.50'),
              _Fare(label: 'Pause /min', value: '\$0.10'),
            ],
          ),
          const Spacer(),
          _ParkingRules(
            button: _PrimaryButton(
              label: 'Start Ride',
              onPressed: () => context.go('/ride-active'),
            ),
          ),
        ],
      ),
    );
  }
}

class RideStatusScreen extends StatelessWidget {
  final bool paused;

  const RideStatusScreen({super.key, this.paused = false});

  @override
  Widget build(BuildContext context) {
    return _MapScaffold(
      showMarkers: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: _BottomPanel(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -64,
                top: -70,
                child: Image.asset('assets/images/bike.png', width: 165),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Title('Isoko BK2113'),
                  const SizedBox(height: 30),
                  const Row(
                    children: [
                      Expanded(
                          child: _Metric(
                              label: 'Battery level',
                              value: '90%',
                              icon: Icons.battery_full)),
                      Expanded(
                          child: _Metric(
                              label: 'Range Up to',
                              value: '30-35 km',
                              icon: Icons.bolt)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: paused ? 'Time used' : 'Time used',
                          value: paused ? '02:15 min' : '02:00 min',
                          icon: Icons.schedule,
                        ),
                      ),
                      const Expanded(
                          child: _Metric(
                              label: 'Traveled',
                              value: '3.2 km',
                              icon: Icons.navigation)),
                    ],
                  ),
                  if (paused) ...[
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                              child: _Metric(
                                  label: 'Paused time',
                                  value: '01:15 min',
                                  icon: Icons.schedule)),
                          Expanded(
                              child: _Fare(
                                  label: 'Cost of Pause', value: '\$0.10')),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: _PrimaryButton(
                          label: paused ? 'Resume' : 'Pause',
                          icon: paused ? Icons.play_arrow : Icons.pause,
                          onPressed: () => context
                              .go(paused ? '/ride-active' : '/ride-paused'),
                        ),
                      ),
                      const SizedBox(width: 26),
                      Expanded(
                        child: _PrimaryButton(
                          label: 'End Ride',
                          icon: Icons.stop,
                          color: const Color(0xFFCA1F3C),
                          onPressed: () => context.go('/end-ride'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EndRideScreen extends StatelessWidget {
  const EndRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _MapScaffold(
      showMarkers: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(color: _panel),
              child: const _LocationHeader(
                  distance: '1.8km',
                  title: 'Drop at nearest point\n23rd Avenue Street'),
            ),
            _BottomPanel(
              marginTop: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/bike.png', width: 140),
                  const _Title('Confirm End Ride?'),
                  const SizedBox(height: 16),
                  const _BodyText('Make sure you park at Electra zone only.'),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: _PrimaryButton(
                          label: 'Back',
                          color: Colors.white,
                          foreground: _green,
                          onPressed: () => context.go('/ride-active'),
                        ),
                      ),
                      const SizedBox(width: 36),
                      Expanded(
                        child: _PrimaryButton(
                          label: 'confirm',
                          color: const Color(0xFFCA1F3C),
                          onPressed: () => context.go('/payment-due'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentDueScreen extends StatelessWidget {
  const PaymentDueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlainScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BackButton(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 28),
                  _Title('BK2103'),
                  SizedBox(height: 12),
                  _BodyText('12 Aug 2025, 06:53 pm'),
                  SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                          child: _Metric(
                              label: 'You Traveled',
                              value: '9.5km',
                              icon: Icons.navigation)),
                      Expanded(
                          child: _Metric(
                              label: 'Carbon saved',
                              value: '1890 gm',
                              icon: Icons.eco)),
                    ],
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: _Metric(
                              label: 'Ride Time',
                              value: '29:13 min',
                              icon: Icons.schedule)),
                      Expanded(
                          child: _Metric(
                              label: 'Pause Time',
                              value: '1:12 min',
                              icon: Icons.schedule)),
                    ],
                  ),
                ],
              ),
              Positioned(
                right: -108,
                top: -24,
                child: Image.asset('assets/images/bike.png', width: 230),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white),
          const SizedBox(height: 20),
          const _TripStop(
              icon: Icons.location_on,
              title: 'Pickup from',
              place: '23rd Avenue Street',
              time: '06:32 pm'),
          const _TripStop(
              icon: Icons.navigation,
              title: 'Drop at',
              place: 'Parker point tower',
              time: '07:02 pm'),
          const Spacer(),
          _PaymentBreakdown(onPressed: () => context.go('/payment-options')),
        ],
      ),
    );
  }
}

class PaymentOptionsScreen extends StatelessWidget {
  const PaymentOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlainScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BackButton(),
          const SizedBox(height: 24),
          const Center(child: _Title('Ride Completed')),
          const SizedBox(height: 54),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total to pay',
                    style:
                        TextStyle(color: _muted, fontWeight: FontWeight.w700)),
                Text('\$11.10',
                    style:
                        TextStyle(color: _green, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 54),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Text('Select payment method',
                style: TextStyle(
                    color: _muted, fontSize: 18, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 26),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
                color: _panel, borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                const _PaymentOption(
                    label: 'MTN Mobile money', color: Colors.amber),
                const _PaymentOption(
                    label: 'Airtel Money', color: Colors.white),
                const _PaymentOption(
                    label: 'Card Payment', color: Color(0xFFFFECEC)),
                const _PaymentOption(
                    label: 'Bank Transfer', color: Colors.white),
                const SizedBox(height: 22),
                _PrimaryButton(
                    label: 'Pay now',
                    onPressed: () => context.go('/payment-success')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlainScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BackButton(),
          const Spacer(),
          const Center(
            child: CircleAvatar(
              radius: 82,
              backgroundColor: _green,
              child: Icon(Icons.check, color: Colors.white, size: 118),
            ),
          ),
          const SizedBox(height: 70),
          const Center(child: _Title('Payment successful')),
          const SizedBox(height: 28),
          const Center(
            child: Text(
              'Your payment of  \$11.10 is has\nbeen processed',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _muted, fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          const Spacer(),
          _PrimaryButton(
              label: 'Rate your ride',
              onPressed: () => context.go('/rate-ride')),
        ],
      ),
    );
  }
}

class RateRideScreen extends StatefulWidget {
  const RateRideScreen({super.key});

  @override
  State<RateRideScreen> createState() => _RateRideScreenState();
}

class _RateRideScreenState extends State<RateRideScreen> {
  int rating = 4;

  @override
  Widget build(BuildContext context) {
    return _PlainScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BackButton(),
          Stack(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 42),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Title('Rate your ride'),
                    SizedBox(height: 30),
                    Text('9.5km  - 29:13 min  -  Parker point tower',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Positioned(
                  right: 8,
                  child: Image.asset('assets/images/bike.png', width: 120)),
            ],
          ),
          const SizedBox(height: 38),
          const Divider(color: Colors.white),
          const SizedBox(height: 18),
          const _Title('How Was Your Journey?'),
          const SizedBox(height: 18),
          Row(
            children: List.generate(
              5,
              (index) => IconButton(
                onPressed: () => setState(() => rating = index + 1),
                icon: Icon(
                  index < rating ? Icons.star : Icons.star,
                  color:
                      index < rating ? const Color(0xFFFFC93C) : Colors.white70,
                  size: 38,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const _CapsLabel('WHAT STOOD OUT?'),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              _ChoicePill('SCOOTER\nCONDITION', active: true),
              _ChoicePill('SMOOTH RIDE'),
              _ChoicePill('SAFE PARKING'),
              _ChoicePill('BATTERY LEVEL'),
            ],
          ),
          const SizedBox(height: 18),
          const _CapsLabel('ADD A COMMENT'),
          const SizedBox(height: 12),
          const TextField(
            minLines: 4,
            maxLines: 4,
            decoration: InputDecoration(
                hintText: 'Tell us more about your experience...'),
          ),
          const Spacer(),
          _PrimaryButton(
              label: 'Submit Rating',
              onPressed: () => context.go('/find-scooter')),
        ],
      ),
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _MapScaffold(
      showLogo: false,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.78,
          height: double.infinity,
          padding: const EdgeInsets.fromLTRB(34, 38, 30, 28),
          color: _panel,
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                          radius: 34,
                          backgroundColor: _green,
                          child: Icon(Icons.person, size: 42)),
                      const SizedBox(width: 18),
                      const Expanded(child: _Title('John Doe')),
                      IconButton(
                          onPressed: () => context.go('/find-scooter'),
                          icon: const Icon(Icons.chevron_right,
                              color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 42),
                  const _MenuItem(
                      Icons.electric_bike, 'Ride History', '/ride-history'),
                  const _MenuItem(Icons.account_balance_wallet,
                      'Recent Transactions', '/transactions'),
                  const _MenuItem(Icons.share, 'Refer & Earn', '/referral'),
                  const _MenuItem(Icons.question_mark, 'FAQs', '/faq'),
                  const _MenuItem(Icons.settings, 'Settings', '/settings'),
                  const _MenuItem(Icons.play_circle, 'Tutorials', '/tutorial'),
                  const SizedBox(height: 24),
                  Center(
                      child: Image.asset('assets/images/bike.png', width: 150)),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Expanded(
                          child: _Metric(
                              label: 'Rides taken',
                              value: '39 Rides',
                              icon: Icons.electric_bike)),
                      Expanded(
                          child: _Metric(
                              label: 'Ride Times',
                              value: '3:12 hrs',
                              icon: Icons.schedule)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Expanded(
                          child: _Metric(
                              label: 'Distance Traveled',
                              value: '90.5km',
                              icon: Icons.navigation)),
                      Expanded(
                          child: _Metric(
                              label: 'Carbon',
                              value: '6554gms',
                              icon: Icons.local_fire_department)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rides = ['BK2113', 'BK2001', 'BK0921', 'BK9002', 'BK213', 'BK4563'];
    return _ListPage(
      title: 'Ride History',
      children: rides
          .map(
            (id) => _HistoryCard(
              title: 'Isoko ride $id',
              subtitle: id == 'BK2001'
                  ? '01 Sep 2025,06:53 pm'
                  : '12 Aug 2025,06:53 pm',
            ),
          )
          .toList(),
    );
  }
}

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ListPage(
      title: 'Recent transactions',
      inPanel: true,
      children: List.generate(
        4,
        (index) => const ListTile(
          leading: CircleAvatar(
              backgroundColor: Colors.black,
              child: Icon(Icons.electric_bike, color: _green)),
          title: Text('Paid for ride',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          subtitle: Text('12 Aug 2025,06:53 pm',
              style: TextStyle(color: _muted, fontWeight: FontWeight.w700)),
          trailing: Text('-\$10.14',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlainScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BackButton(),
          const SizedBox(height: 24),
          const Center(child: _Title('Settings')),
          const SizedBox(height: 12),
          const Center(child: _BodyText('Your Questions got answered')),
          const SizedBox(height: 38),
          const _SettingsRow('Select Language', 'English'),
          const _SettingsRow('App Mode', 'Dark Mode'),
          const _SettingsRow('Distance Unit', 'Km (Kilometer)'),
          const Divider(color: Colors.white),
          const SizedBox(height: 20),
          const _Title('Terms And Conditions'),
          const SizedBox(height: 20),
          const _Title('Privact Policy'),
          const SizedBox(height: 34),
          TextButton(
            onPressed: () => context.go('/sign-in'),
            child: const Text('Logout',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlainScreen(
      padding: const EdgeInsets.all(22),
      child: ListView(
        children: const [
          Row(
            children: [
              _BackButton(),
              SizedBox(width: 12),
              Text('FAQ',
                  style: TextStyle(color: _green, fontWeight: FontWeight.w900)),
              Spacer(),
              Icon(Icons.help_outline, color: _green, size: 18),
            ],
          ),
          SizedBox(height: 26),
          _BodyText(
              'Everything you need to know about\nnavigating the city with Kinetic. Fast,\nfluid, and always on.'),
          SizedBox(height: 28),
          TextField(
              decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search questions...')),
          SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                  child: _FaqCategory(
                      icon: Icons.electric_scooter,
                      title: 'Starting &\nRiding')),
              SizedBox(width: 14),
              Expanded(
                  child: _FaqCategory(
                      icon: Icons.payments, title: 'Pricing &\nBilling')),
            ],
          ),
          SizedBox(height: 28),
          _QuestionTile('How do I start a ride?'),
          _QuestionTile('How much does it cost?'),
          _QuestionTile('Where can I park?'),
          _QuestionTile('What if my scooter is damaged?'),
          SizedBox(height: 34),
          _HelpCard(),
        ],
      ),
    );
  }
}

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlainScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BackButton(),
          const SizedBox(height: 28),
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(4)),
            child: const Icon(Icons.campaign, color: _green, size: 130),
          ),
          const SizedBox(height: 52),
          const _Title('Refer App to friends and get up to\n\$30'),
          const SizedBox(height: 28),
          const _BodyText('When they sign up using your link you will get'),
          const SizedBox(height: 18),
          const _Bullet('\$10 in wallet when they sign up'),
          const _Bullet('\$20 when they book first ride'),
          const Spacer(),
          _PrimaryButton(
              label: 'Share on WhatsApp', icon: Icons.chat, onPressed: () {}),
          const SizedBox(height: 16),
          _PrimaryButton(
              label: 'Share link',
              icon: Icons.share,
              color: Colors.white,
              foreground: _green,
              onPressed: () {}),
        ],
      ),
    );
  }
}

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlainScreen(
      child: Column(
        children: [
          const Row(children: [
            _BackButton(),
            Spacer(),
            IsokoLogo(height: 34),
            Spacer(),
            SizedBox(width: 48)
          ]),
          const SizedBox(height: 22),
          const _Title('Tutorials'),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  color: const Color(0xFF07151C),
                  borderRadius: BorderRadius.circular(2)),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _SpeedLinesPainter()),
                  ),
                  const Positioned(
                    left: 38,
                    bottom: 110,
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: _green,
                      child:
                          Icon(Icons.play_arrow, color: Colors.black, size: 38),
                    ),
                  ),
                  const Positioned(
                    left: 104,
                    bottom: 74,
                    right: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MASTER THE\nFLOW',
                            style: TextStyle(
                                color: Color(0xFFFFFFB9),
                                fontSize: 28,
                                fontWeight: FontWeight.w900)),
                        SizedBox(height: 8),
                        Text('1:24 Tutorial • Essential\nSkills',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const Positioned(
                      left: 34,
                      right: 34,
                      bottom: 52,
                      child: LinearProgressIndicator(
                          value: .34,
                          color: _green,
                          backgroundColor: Colors.white24)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TakePictureScreen extends StatelessWidget {
  const TakePictureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PhotoLikeScreen(
      title: 'Take Picture',
      subtitle: 'Take a picture of the bike parked in the station',
      child: Column(
        children: [
          const SizedBox(height: 120),
          Image.asset('assets/images/bike.png', width: 330),
          const Spacer(),
          _CircleAction(
            label: 'Take picture',
            icon: Icons.camera_alt_outlined,
            onTap: () => context.go('/payment-due'),
          ),
          const SizedBox(height: 38),
        ],
      ),
    );
  }
}

class InvalidParkingZoneScreen extends StatelessWidget {
  const InvalidParkingZoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _MapScaffold(
      showMarkers: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: _BottomPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 78),
              const SizedBox(height: 20),
              const _Title('Invalid Parking Zone'),
              const SizedBox(height: 14),
              const _BodyText(
                  'Move to an Electra zone before ending your ride.'),
              const SizedBox(height: 28),
              _PrimaryButton(
                  label: 'Back to ride',
                  onPressed: () => context.go('/ride-active')),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlainScreen extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _PlainScreen({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(36, 48, 36, 28),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF080B0A),
                AppTheme.backgroundColor,
              ],
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _MapScaffold extends StatelessWidget {
  final Widget child;
  final bool showMarkers;
  final bool showLogo;

  const _MapScaffold({
    required this.child,
    this.showMarkers = true,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MapPainter())),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(52),
                      Colors.transparent,
                      Colors.black.withAlpha(120),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showMarkers) ...const [
            Positioned(top: 118, left: 120, child: _ScooterDot()),
            Positioned(top: 265, right: 112, child: _ScooterDot()),
            Positioned(bottom: 325, left: 104, child: _ScooterDot()),
            Positioned(bottom: 285, right: 82, child: _ScooterDot()),
          ],
          const Positioned(
            bottom: 250,
            left: 0,
            right: 0,
            child: Center(child: _UserMarker()),
          ),
          if (showLogo)
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => context.go('/menu'),
                      icon:
                          const Icon(Icons.menu, color: Colors.white, size: 34),
                    ),
                    const IsokoLogo(height: 34),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final Widget child;
  final double marginTop;

  const _BottomPanel({required this.child, this.marginTop = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(22, marginTop, 22, 22),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusPanel),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: _softShadow,
      ),
      child: child,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color color;
  final Color foreground;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = _green,
    this.foreground = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild = icon == null
        ? ElevatedButton(
            onPressed: onPressed,
            style: _buttonStyle(),
            child: Text(label),
          )
        : ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, color: foreground, size: 19),
            label: Text(label),
            style: _buttonStyle(),
          );

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: buttonChild,
    );
  }

  ButtonStyle _buttonStyle() {
    final shadow = color == _green
        ? AppTheme.primaryGreenDark.withAlpha(145)
        : color.withAlpha(90);

    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: foreground,
      elevation: 10,
      shadowColor: shadow,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      textStyle: AppTheme.bodyStrongStyle.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton(
      {required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 26),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.surface,
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppTheme.cardBorder),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
          textStyle:
              AppTheme.bodyStrongStyle.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ScanButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 176,
        child: _PrimaryButton(
          label: 'Scan Now',
          icon: Icons.qr_code_2,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _Field({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.bodyMutedStyle.copyWith(
              color: _subtle,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.text,
            cursorColor: _green,
            style: AppTheme.bodyStrongStyle.copyWith(fontSize: 15),
            decoration: InputDecoration(
              hintText: controller.text.isEmpty ? label : null,
              prefixIcon: const Icon(Icons.circle, color: _green, size: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;

  const _Title(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.headingStyle,
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;

  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.bodyMutedStyle,
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: IconButton(
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/find-scooter'),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }
}

class _LocationHeader extends StatelessWidget {
  final String distance;
  final String title;

  const _LocationHeader({
    required this.distance,
    this.title = '23rd Avenue Street',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFF303433),
          child: Icon(Icons.electric_bike, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTheme.headingStyle
                      .copyWith(fontSize: 18, height: 1.22)),
              const SizedBox(height: 8),
              Text('3 Scooters available',
                  style: AppTheme.bodyMutedStyle.copyWith(fontSize: 13)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF12382C),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: _green.withAlpha(42)),
          ),
          child: Column(
            children: [
              const Icon(Icons.navigation, color: _green, size: 28),
              Text(
                distance,
                style: AppTheme.bodyStrongStyle.copyWith(
                  color: _green,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScooterMiniCard extends StatelessWidget {
  final MockScooter scooter;

  const _ScooterMiniCard(this.scooter);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(scooter.id,
                  style: AppTheme.bodyStrongStyle
                      .copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(scooter.distance,
                  style: AppTheme.bodyMutedStyle.copyWith(fontSize: 11)),
              const Spacer(),
              Text('Range',
                  style: AppTheme.bodyMutedStyle.copyWith(fontSize: 10)),
              Row(
                children: [
                  const Icon(Icons.bolt, color: _green, size: 15),
                  Text(
                    scooter.range,
                    style: AppTheme.bodyStrongStyle
                        .copyWith(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
              right: -36,
              top: 0,
              child: Image.asset('assets/images/bike.png', width: 94)),
        ],
      ),
    );
  }
}

class _ScooterDot extends StatelessWidget {
  const _ScooterDot();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 19,
      backgroundColor: _green,
      child: Icon(Icons.electric_bike, color: Colors.white, size: 20),
    );
  }
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration:
          BoxDecoration(color: _green.withAlpha(38), shape: BoxShape.circle),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
            color: Color(0xFFEFF7F1), shape: BoxShape.circle),
        child: const Icon(Icons.navigation, color: _green, size: 30),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _Metric({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTheme.bodyMutedStyle
                .copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, color: _green, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                style: AppTheme.headingStyle
                    .copyWith(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Fare extends StatelessWidget {
  final String label;
  final String value;

  const _Fare({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTheme.bodyMutedStyle
                .copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Text(value,
            style: AppTheme.headingStyle
                .copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _ParkingRules extends StatelessWidget {
  final Widget button;

  const _ParkingRules({required this.button});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusPanel),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: _softShadow,
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                  child:
                      _RuleBike(active: true, label: 'Park in\nElectra Zone')),
              Expanded(
                  child: _RuleBike(
                      active: false, label: 'Do not Park in\nPrivate Area')),
            ],
          ),
          const SizedBox(height: 28),
          button,
        ],
      ),
    );
  }
}

class _RuleBike extends StatelessWidget {
  final bool active;
  final String label;

  const _RuleBike({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.electric_bike,
            color: active ? _green : Colors.white70, size: 68),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.bodyStrongStyle
              .copyWith(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _TripStop extends StatelessWidget {
  final IconData icon;
  final String title;
  final String place;
  final String time;

  const _TripStop(
      {required this.icon,
      required this.title,
      required this.place,
      required this.time});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
          backgroundColor: AppTheme.surface, child: Icon(icon, color: _green)),
      title: Text(title, style: AppTheme.bodyMutedStyle.copyWith(fontSize: 12)),
      subtitle: Text(place,
          style:
              AppTheme.bodyStrongStyle.copyWith(fontWeight: FontWeight.w800)),
      trailing:
          Text(time, style: AppTheme.bodyMutedStyle.copyWith(fontSize: 12)),
    );
  }
}

class _PaymentBreakdown extends StatelessWidget {
  final VoidCallback onPressed;

  const _PaymentBreakdown({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusPanel),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: _softShadow,
      ),
      child: Column(
        children: [
          const Align(
              alignment: Alignment.centerLeft,
              child: _BodyText('Fare Breakdown')),
          const SizedBox(height: 20),
          const _AmountRow('Fixed Rent', '\$6.00'),
          const _AmountRow('Km Ride fare', '\$4.00'),
          const _AmountRow('Pause fare', '\$1.10'),
          const _AmountRow('Amount due', '\$11.10', highlight: true),
          const Divider(color: Colors.white54),
          const SizedBox(height: 18),
          _PrimaryButton(label: 'Continue to payment', onPressed: onPressed),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _AmountRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: highlight ? Colors.white : _muted,
                  fontWeight: FontWeight.w900)),
          Text(
            value,
            style: AppTheme.bodyStrongStyle.copyWith(
              color: highlight ? _green : Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final Color color;

  const _PaymentOption({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: [
                BoxShadow(
                    color: color.withAlpha(70),
                    blurRadius: 18,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: const Icon(Icons.payments, color: Colors.black),
          ),
          const SizedBox(width: 38),
          Text(label,
              style: AppTheme.bodyStrongStyle
                  .copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _CapsLabel extends StatelessWidget {
  final String text;

  const _CapsLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.bodyMutedStyle.copyWith(
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final String label;
  final bool active;

  const _ChoicePill(this.label, {this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? _green : AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: active ? _green.withAlpha(120) : AppTheme.cardBorder),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTheme.bodyStrongStyle
            .copyWith(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _MenuItem(this.icon, this.label, this.route);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: _green),
      title: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900)),
      onTap: () => context.go(route),
    );
  }
}

class _ListPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool inPanel;

  const _ListPage(
      {required this.title, required this.children, this.inPanel = false});

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      children: [
        const _BackButton(),
        const SizedBox(height: 16),
        Center(child: _Title(title)),
        const SizedBox(height: 28),
        ...children,
      ],
    );
    return _PlainScreen(
      child: inPanel
          ? Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(AppTheme.radiusPanel),
                border: Border.all(color: AppTheme.cardBorder),
                boxShadow: _softShadow,
              ),
              child: content,
            )
          : content,
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HistoryCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTheme.bodyStrongStyle
                      .copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(subtitle,
                  style: AppTheme.bodyMutedStyle.copyWith(fontSize: 12)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('6.1 km',
                      style: AppTheme.bodyStrongStyle.copyWith(fontSize: 12)),
                  Text('02:15 min',
                      style: AppTheme.bodyStrongStyle.copyWith(fontSize: 12)),
                  Text('\$3.10',
                      style: AppTheme.bodyStrongStyle.copyWith(fontSize: 12)),
                ],
              ),
            ],
          ),
          Positioned(
              right: -42,
              top: -26,
              child: Image.asset('assets/images/bike.png', width: 112)),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String title;
  final String value;

  const _SettingsRow(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Title(title),
                const SizedBox(height: 12),
                Text(value,
                    style: AppTheme.bodyMutedStyle
                        .copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _muted),
        ],
      ),
    );
  }
}

class _FaqCategory extends StatelessWidget {
  final IconData icon;
  final String title;

  const _FaqCategory({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _green),
          const Spacer(),
          Text(title,
              style: AppTheme.bodyStrongStyle
                  .copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final String question;

  const _QuestionTile(this.question);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        title: Text(question,
            style: AppTheme.bodyStrongStyle
                .copyWith(fontSize: 12, fontWeight: FontWeight.w800)),
        trailing: const Icon(Icons.keyboard_arrow_down, color: _muted),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF25D47E), Color(0xFF10985B)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusPanel),
        boxShadow: _softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Still stuck?',
              style: AppTheme.headingStyle.copyWith(fontSize: 18)),
          const SizedBox(height: 10),
          Text(
            'Our urban experts are online 24/7 to\nhelp you get back on the road.',
            style: AppTheme.bodyStrongStyle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 18),
          const Chip(label: Text('CONTACT US')),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration:
                const BoxDecoration(color: _green, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: AppTheme.bodyStrongStyle
                      .copyWith(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class _PhotoLikeScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _PhotoLikeScreen(
      {required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF151A18), AppTheme.backgroundColor],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 26),
              child: Column(
                children: [
                  Row(
                    children: [
                      const _BackButton(),
                      const Spacer(),
                      _Title(title),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: _BodyText(subtitle)),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CircleAction(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.cardBorder),
              boxShadow: _softShadow,
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 22),
        Text(label,
            style:
                AppTheme.bodyMutedStyle.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFF050606), BlendMode.src);

    final blockPaint = Paint()..color = const Color(0xFF0C0D0D);
    for (var i = 0; i < 8; i++) {
      final left = (i * 73) % size.width;
      final top = (i * 127) % size.height;
      canvas.save();
      canvas.translate(left, top);
      canvas.rotate(i.isEven ? .28 : -.22);
      canvas.drawRect(const Rect.fromLTWH(-20, -10, 160, 80), blockPaint);
      canvas.restore();
    }

    final street = Paint()
      ..color = const Color(0xFF5A5D5E)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final glow = Paint()
      ..color = const Color(0xFF222526)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;

    final paths = <Path>[
      Path()
        ..moveTo(0, size.height * .12)
        ..lineTo(size.width * .38, size.height * .2)
        ..lineTo(size.width * .32, size.height * .36)
        ..lineTo(size.width * .68, size.height * .42)
        ..lineTo(size.width, size.height * .34),
      Path()
        ..moveTo(size.width * .24, 0)
        ..lineTo(size.width * .12, size.height * .34)
        ..lineTo(size.width * .28, size.height * .64)
        ..lineTo(size.width * .18, size.height),
      Path()
        ..moveTo(size.width * .75, 0)
        ..lineTo(size.width * .58, size.height * .3)
        ..lineTo(size.width * .72, size.height * .62)
        ..lineTo(size.width * .44, size.height),
      Path()
        ..moveTo(0, size.height * .72)
        ..lineTo(size.width * .36, size.height * .82)
        ..lineTo(size.width, size.height * .7),
    ];

    for (final path in paths) {
      canvas.drawPath(path, glow);
      canvas.drawPath(path, street);
    }

    final route = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .52, size.height * .53)
        ..lineTo(size.width * .64, size.height * .58)
        ..lineTo(size.width * .72, size.height * .52),
      route,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final black = Paint()..color = Colors.black;
    final cells = [
      const Rect.fromLTWH(10, 10, 36, 36),
      const Rect.fromLTWH(104, 10, 36, 36),
      const Rect.fromLTWH(10, 104, 36, 36),
      const Rect.fromLTWH(62, 16, 12, 12),
      const Rect.fromLTWH(82, 34, 14, 14),
      const Rect.fromLTWH(54, 62, 16, 16),
      const Rect.fromLTWH(92, 78, 12, 12),
      const Rect.fromLTWH(116, 104, 18, 18),
      const Rect.fromLTWH(70, 116, 14, 14),
      const Rect.fromLTWH(38, 76, 16, 16),
    ];
    for (final cell in cells) {
      canvas.drawRect(cell, black);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpeedLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(40)
      ..strokeWidth = 2;
    for (var i = 0; i < 18; i++) {
      final y = size.height * (i / 18);
      canvas.drawLine(Offset(size.width * .5, size.height * .55),
          Offset(i.isEven ? 0 : size.width, y), paint);
    }
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * .45, size.width, size.height * .55),
        Paint()..color = Colors.black.withAlpha(80));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
