$response = Invoke-RestMethod -Uri 'https://api.github.com/repos/ernie96/doubleapple/actions/runs/30357458814/jobs'
$response.jobs[0].steps | Select-Object name, conclusion
