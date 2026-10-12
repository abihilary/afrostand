/// The seam a real payment provider drops into.
///
/// Everything around payment is built for real — orders, payment rows, status
/// transitions — and only the provider itself is faked. That ordering is
/// deliberate: the parts that are hard to change later (what an order is, what
/// a payment row records, who is allowed to see either) get settled now, while
/// the part that is genuinely swappable stays behind one interface.
///
/// Replacing the stub with Campay or MTN MoMo is a new `PaymentGateway` plus a
/// webhook that moves the payment row. No screen and no table changes.
///
/// What a real gateway will need that the stub does not: provider credentials,
/// which cannot live in this app. A Flutter binary is readable, so the secret
/// belongs in an Edge Function that the app calls and the provider calls back.
library;

import 'dart:async';
import 'dart:math';

enum PaymentOutcome { succeeded, failed, cancelled }

class PaymentResult {
  final PaymentOutcome outcome;

  /// The provider's own reference, kept so a payment can be reconciled against
  /// their dashboard later. Meaningless for the stub, present so the shape is
  /// right when it stops being a stub.
  final String? reference;
  final String? message;

  const PaymentResult(this.outcome, {this.reference, this.message});

  bool get isSuccess => outcome == PaymentOutcome.succeeded;
}

abstract class PaymentGateway {
  /// Charge for an order that already exists. The amount is passed for the
  /// provider's benefit only — the authoritative figure is the one
  /// `place_order()` wrote, and nothing here can change it.
  Future<PaymentResult> charge({
    required String orderId,
    required int amountXaf,
    required String methodLabel,
  });
}

/// Pretends to take money.
///
/// Delays, then succeeds. It does NOT randomly fail: a stub that fails
/// sometimes makes every other bug in the checkout flow unreproducible. Force
/// a failure deliberately with [failNext] when testing the unhappy path.
class StubPaymentGateway implements PaymentGateway {
  StubPaymentGateway({this.delay = const Duration(seconds: 2)});

  final Duration delay;

  /// Set to make the next charge fail, for exercising the error path on a
  /// screen. Cleared once used.
  PaymentOutcome? failNext;

  @override
  Future<PaymentResult> charge({
    required String orderId,
    required int amountXaf,
    required String methodLabel,
  }) async {
    await Future<void>.delayed(delay);

    final forced = failNext;
    if (forced != null) {
      failNext = null;
      return PaymentResult(forced, message: 'Simulated $forced');
    }

    final ref = 'STUB-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}'
        '-${Random().nextInt(900) + 100}';
    return PaymentResult(PaymentOutcome.succeeded, reference: ref);
  }
}
