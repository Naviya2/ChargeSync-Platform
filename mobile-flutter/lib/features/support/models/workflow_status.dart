class SupportWorkflowStatus {
  const SupportWorkflowStatus(this.label, this.description);
  final String label;
  final String description;

  static SupportWorkflowStatus fromRecords(
    Map<String, dynamic> ticket,
    Map<String, dynamic>? workflow,
  ) {
    if (ticket['status'] == 'Withdrawn') {
      return const SupportWorkflowStatus(
        'Withdrawn',
        'You withdrew this ticket.',
      );
    }
    if (['Resolved', 'Closed'].contains(ticket['status'])) {
      return const SupportWorkflowStatus(
        'Resolved',
        'Support has resolved this ticket.',
      );
    }
    if (workflow?['status'] == 'Failed') {
      return const SupportWorkflowStatus(
        'Failed',
        'Analysis needs staff attention. You can still send support a message.',
      );
    }
    if (workflow == null ||
        [
          'Running',
          'RevisionRequested',
          'Approved',
        ].contains(workflow['status'])) {
      return const SupportWorkflowStatus(
        'Processing',
        'Your ticket is being checked. This page refreshes automatically.',
      );
    }
    if (workflow['status'] == 'PendingApproval' ||
        ticket['refundStatus'] == 'PendingReview') {
      return const SupportWorkflowStatus(
        'Pending Approval',
        'A staff member must review the requested action.',
      );
    }
    if (workflow['status'] == 'Rejected' ||
        (workflow['status'] == 'Completed' && workflow['decision'] != null)) {
      return SupportWorkflowStatus(
        'Resolved',
        workflow['decision'] == 'Rejected'
            ? 'Staff rejected the requested action. You can contact support for details.'
            : 'Staff approved the requested action. Check the ticket messages for details.',
      );
    }
    if (workflow['status'] == 'Completed') {
      return const SupportWorkflowStatus(
        'Processing',
        'Analysis is complete. Support is reviewing your ticket.',
      );
    }
    return const SupportWorkflowStatus(
      'Processing',
      'Your ticket is being checked. This page refreshes automatically.',
    );
  }
}
