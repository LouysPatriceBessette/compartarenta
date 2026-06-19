export '../housing/housing_plan_id.dart'
    show
        authorPlanIdFromProposalPayload,
        entitlementPlanIdForLocalPlan,
        kHousingPlanIdPrefix,
        kReceivedPlanIdPrefix,
        looksLikeUuid,
        newHousingPlanId,
        newUuidV4,
        planIdPrefixFromParticipantId,
        receivedPlanIdForAuthorPlan;

/// Stable entitlement [`plan_id`] shared across author and received devices.
///
/// See [entitlementPlanIdForLocalPlan] in `housing_plan_id.dart`.
