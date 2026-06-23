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

/// Stable bare [`plan_id`] shared across author and received devices on
/// entitlement and relay (module=`housing` elsewhere).
///
/// See [entitlementPlanIdForLocalPlan] in `housing_plan_id.dart`.
