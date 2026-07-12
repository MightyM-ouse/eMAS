@{
    Severity = @(
        'Error'
        'Warning'
    )

    # eMAS uses explicit console progress and completion messages.
    ExcludeRules = @(
        'PSAvoidUsingWriteHost'
    )
}
