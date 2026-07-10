$SERVER = "https://web-production-f04e1.up.railway.app"

function Send-Command($action, $data = @{}) {
    $body = @{ action = $action; data = $data } | ConvertTo-Json -Depth 10
    $res = Invoke-RestMethod -Uri "$SERVER/api/command" -Method POST -Body $body -ContentType "application/json"
    return $res.commandId
}

function Get-Result($cmdId, $timeout = 30) {
    $start = Get-Date
    while ((Get-Date) - $start -lt [TimeSpan]::FromSeconds($timeout)) {
        try {
            $res = Invoke-RestMethod -Uri "$SERVER/api/result/$cmdId" -Method GET
            if ($res.status -ne "pending") { return $res }
        } catch {
            $code = $_.Exception.Response.StatusCode.value__
            if ($code -eq 200) { return $_ }
        }
        Start-Sleep -Milliseconds 500
    }
    throw "Timeout"
}

$action = $args[0]
$dataArg = $args[1]

if ($action -eq "list_objects") {
    $cmdId = Send-Command "list_objects" @{ parentPath = $dataArg }
    $result = Get-Result $cmdId
    $result | ConvertTo-Json -Depth 10
} elseif ($action -eq "create_script") {
    $data = $dataArg | ConvertFrom-Json
    $cmdId = Send-Command "create_script" $data
    $result = Get-Result $cmdId
    $result | ConvertTo-Json -Depth 10
} elseif ($action -eq "create_object") {
    $data = $dataArg | ConvertFrom-Json
    $cmdId = Send-Command "create_object" $data
    $result = Get-Result $cmdId
    $result | ConvertTo-Json -Depth 10
} elseif ($action -eq "get_object_info") {
    $cmdId = Send-Command "get_object_info" @{ objectPath = $dataArg }
    $result = Get-Result $cmdId
    $result | ConvertTo-Json -Depth 10
} elseif ($action -eq "delete_object") {
    $cmdId = Send-Command "delete_object" @{ objectPath = $dataArg }
    $result = Get-Result $cmdId
    $result | ConvertTo-Json -Depth 10
} elseif ($action -eq "execute_luau") {
    $cmdId = Send-Command "execute_luau" @{ code = $dataArg }
    $result = Get-Result $cmdId
    $result | ConvertTo-Json -Depth 10
} else {
    Write-Host "Usage: .\studio.ps1 <action> [data]"
    Write-Host "Actions: list_objects, create_script, create_object, get_object_info, delete_object, execute_luau"
}