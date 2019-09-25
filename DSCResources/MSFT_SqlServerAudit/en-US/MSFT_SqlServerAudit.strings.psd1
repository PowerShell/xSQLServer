ConvertFrom-StringData @'
    RetrievingAuditInfo = Retrieving information about Audit '{0}' from the server '{1}'. (SSA0001)
    EvaluateAudit = Determining if the audit '{0}' on server '{1}' instance '{2}' is in the desired state. (SSA0002)
    AuditExist = The audit '{0}' exist in on server '{1}'. (SSA0003)
    InDesiredState = The audit is in desired state. (SSA0004)
    NotInDesiredState = The audit is not in desired state. (SSA0005)
    CreateAudit = Creating the audit '{0}' on server '{1}' instance '{2}'. (SSA0006)
    FailedCreateAudit = Failed creating audit '{0}' on server '{1}' instance '{2}'. (SSA0007)
    DropAudit = Removing the audit '{0}' from server '{1}' instance '{2}'. (SSA0008)
    FailedDropAudit = Failed removing the audit '{0}' from server '{1}' instance '{2}'. (SSA0009)
    SetAudit = Setting the audit '{0}' on server '{1}' instance '{2}' to the desired state. (SSA0010)
    FailedUpdateAudit = Failed updating audit '{0}' on server '{1}' instance '{2}'. (SSA0011)
    ChangingAuditDestinationType = The audit '{0}' currently has destination type '{1}', but expected it to be '{2}'. Re-creating audit '{0}' on server {3} instance '{4}'. (SSA0012)
    CreateFolder = Creating folder {0}. (SSA0013)
    ImposibleFileCombination = Both MaximumFiles and MaximumRolloverFiles have been defined. This is not a supported configuration. (SSA0014)
    ForceNotEnabled = Unable to re-create the server audit. The server audit needs to be re-created but the configuration has not opt-in to re-create the audit. To opt-in set the parameter Force to $true.
'@
