param([string]$JMeter = 'D:\Tools\apache-jmeter-5.6.3\bin\jmeter.bat', [string]$ReuseCsv)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$source = Join-Path $root 'task1\plans\23120184_Load_20261120.jmx'
if (!(Test-Path -LiteralPath $source -PathType Leaf)) { throw "Missing plan: $source" }
if (!(Test-Path -LiteralPath $JMeter -PathType Leaf)) { throw "Missing JMeter: $JMeter" }
$python = Get-Command py -ErrorAction SilentlyContinue
if (!$python) { $python = Get-Command python }
$run = Join-Path $root ('agent\runs\' + [guid]::NewGuid().ToString('N'))
New-Item -Type Directory -Path "$run\plans","$run\data" | Out-Null
[xml]$plan = Get-Content -Raw -Encoding UTF8 -LiteralPath $source
$group = $plan.SelectSingleNode('//ThreadGroup')
$group.SelectSingleNode("*[@name='ThreadGroup.num_threads']").InnerText = '1'
$group.SelectSingleNode("*[@name='ThreadGroup.ramp_time']").InnerText = '1'
$group.SelectSingleNode(".//*[@name='LoopController.loops']").InnerText = '1'
$csvPath = Join-Path $run 'data\orders.csv'
if ($ReuseCsv) {
    Copy-Item -LiteralPath $ReuseCsv -Destination $csvPath
} else {
    $account = Get-Credential -UserName 'test@eshop.com' -Message 'EShop customer account'
    if (!$account) { throw 'Login cancelled.' }
    $api = 'http://localhost:3000/api'
    $loginBody = @{email=$account.UserName; password=$account.GetNetworkCredential().Password} | ConvertTo-Json
    $login = Invoke-RestMethod -Method Post -Uri "$api/login" -ContentType 'application/json' -Body $loginBody
    if (!$login.token) { throw 'Customer token missing.' }
    $order = Invoke-RestMethod -Method Post -Uri "$api/checkout" -Headers @{Authorization="Bearer $($login.token)"} -ContentType 'application/json' -Body (@{total_amount=100000;shipping_address="HW05-Agent-$(Split-Path $run -Leaf)"} | ConvertTo-Json)
    if (!$order.orderId) { throw 'Missing order ID.' }
    @('orderId,initialStatus,targetStatus',"$($order.orderId),pending,confirmed") | Set-Content "$run\data\orders.csv" -Encoding ascii
}
$records = @(Import-Csv -LiteralPath $csvPath)
if ($records.Count -ne 1 -or $records[0].orderId -notmatch '^[1-9][0-9]*$' -or
    $records[0].initialStatus -ne 'pending' -or $records[0].targetStatus -ne 'confirmed') {
    throw 'Expected one CSV row: numeric orderId,pending,confirmed.'
}
# The demo has one iteration: bind its single CSV row before JMeter compiles assertions.
$row = $records[0]
foreach ($prop in $plan.SelectNodes('//stringProp')) {
    $value = $prop.InnerText.Replace('${orderId}', $row.orderId).Replace('${initialStatus}', $row.initialStatus).Replace('${targetStatus}', $row.targetStatus)
    if ($value -cne $prop.InnerText) { $prop.InnerText = $value }
}
$plan.SelectSingleNode('//CSVDataSet').SetAttribute('enabled', 'false')
$plan.Save("$run\plans\demo.jmx")
Write-Host "Demo order ID: $($row.orderId)"
& $JMeter -n -t "$run\plans\demo.jmx" -l "$run\demo.jtl" -j "$run\jmeter.log" -e -o "$run\html"
if ($LASTEXITCODE -ne 0) { throw "JMeter failed. See $run\jmeter.log" }
& $python.Source "$PSScriptRoot\analyze.py" "$run\demo.jtl" --out "$run\summary.md"
if ($LASTEXITCODE -ne 0) { throw 'JTL analysis failed.' }
$rows = @(Import-Csv "$run\demo.jtl")
if ($rows.Count -ne 4 -or @($rows | Where-Object success -ne 'true').Count -gt 0 -or (($rows | ForEach-Object { $_.label.Substring(0,2) }) -join ',') -ne '01,02,03,04') { throw "Incomplete or failed workflow. Inspect $run\demo.jtl" }
Write-Host "Completed all four steps. Results: $run"
