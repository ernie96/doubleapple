$runId = (Invoke-RestMethod 'https://api.github.com/repos/ernie96/doubleapple/actions/runs?per_page=1').workflow_runs[0].id
(Invoke-RestMethod "https://api.github.com/repos/ernie96/doubleapple/actions/runs/$runId/jobs").jobs[0].steps | Select-Object name, status, conclusion
