$jobs = (Invoke-RestMethod 'https://api.github.com/repos/ernie96/doubleapple/actions/runs/30372406139/jobs').jobs
foreach ($job in $jobs) {
    Invoke-RestMethod ("https://api.github.com/repos/ernie96/doubleapple/actions/jobs/" + $job.id + "/logs") -OutFile ("job_" + $job.id + ".log")
}
