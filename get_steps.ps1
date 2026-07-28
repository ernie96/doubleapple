$response = Invoke-RestMethod -Uri 'https://api.github.com/repos/ernie96/doubleapple/actions/runs/30357158419/jobs'
$response.jobs[0].steps | Select-Object name, conclusion
