package entitlement

// Gated envelope kinds (housing proposal / ledger sync).
const (
	KindHousingProposal                 = 5
	KindHousingProposalResponse         = 6
	KindHousingRealizedExpensePropose   = 7
	KindHousingRealizedExpenseAccept    = 8
	KindHousingRealizedExpenseReject    = 9
)

// Gate is minimal metadata the relay forwards to the entitlement service.
type Gate struct {
	Module                    string `json:"module"`
	ParticipantInstallationID string `json:"participant_installation_id"`
	PlanID                    string `json:"plan_id"`
	Operation                 string `json:"operation,omitempty"`
	ExpenseID                 string `json:"expense_id,omitempty"`
	RevisionID                string `json:"revision_id,omitempty"`
	DecisionKind              string `json:"decision_kind,omitempty"`
}

// IsGatedKind reports whether the envelope kind requires entitlement_gate
// when entitlement integration is enabled.
func IsGatedKind(kind int) bool {
	switch kind {
	case KindHousingProposal, KindHousingProposalResponse,
		KindHousingRealizedExpensePropose, KindHousingRealizedExpenseAccept,
		KindHousingRealizedExpenseReject:
		return true
	default:
		return false
	}
}

func OperationForKind(kind int) string {
	switch kind {
	case KindHousingProposal:
		return "housing_proposal"
	case KindHousingProposalResponse:
		return "housing_proposal_response"
	case KindHousingRealizedExpensePropose:
		return "housing_realized_expense_propose"
	case KindHousingRealizedExpenseAccept:
		return "housing_realized_expense_accept"
	case KindHousingRealizedExpenseReject:
		return "housing_realized_expense_reject"
	default:
		return ""
	}
}

// ValidateGate checks required fields for gated submissions.
func ValidateGate(kind int, g *Gate) (code string, ok bool) {
	if g == nil {
		return "entitlement_gate_required", false
	}
	if g.Module != "housing" {
		return "entitlement_module_unsupported", false
	}
	if g.ParticipantInstallationID == "" || g.PlanID == "" {
		return "entitlement_gate_required", false
	}
	if g.Operation == "" {
		g.Operation = OperationForKind(kind)
	}
	if g.Operation == "" {
		return "entitlement_gate_required", false
	}
	return "", true
}
