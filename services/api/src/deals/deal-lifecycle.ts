import { DealLifecycleStatus } from '../common/foundation.types';

export const dealLifecycle: Record<DealLifecycleStatus, string[]> = {
  draft: ['negotiation', 'pending_approval', 'cancelled'],
  negotiation: ['pending_approval', 'changes_requested', 'cancelled'],
  pending_approval: ['approved', 'rejected', 'changes_requested'],
  approved: ['locked'],
  locked: ['negotiation', 'archived'],
  changes_requested: ['negotiation', 'cancelled'],
  rejected: ['negotiation', 'archived'],
  cancelled: ['archived'],
  archived: [],
};

export function canTransitionDeal(
  from: DealLifecycleStatus,
  to: DealLifecycleStatus,
): boolean {
  return dealLifecycle[from].includes(to);
}
