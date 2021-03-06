function Get-PerfCounterDesc{
    [cmdletbinding()]
    param(
        [switch]$show
    )

    $Categories = [System.Diagnostics.PerformanceCounterCategory]::GetCategories()
    $SingleInstanceCategories = $Categories | Where-Object {$_.CategoryType -eq "SingleInstance"} 
    $MultiInstanceCategories =  $Categories| Where-Object {$_.CategoryType -eq "MultiInstance"} 
 
    $SingleInstanceCounters = $SingleInstanceCategories | ForEach-Object {
        (new-object System.Diagnostics.PerformanceCounterCategory($_.CategoryName)).GetCounters() 
    }
    $MultiInstanceCounters = $MultiInstanceCategories | ForEach-Object {
        $category=new-object System.Diagnostics.PerformanceCounterCategory($_.CategoryName)
        if($category.InstanceExists('_Total')){
            $category.GetCounters('_Total') 
        }elseif($category.InstanceExists('Total')){
            $category.GetCounters('Total')
        }else{
            $instanceNames=$category.GetInstanceNames()
            if($instanceNames.count -gt 0){
                $category.GetCounters($instanceNames[0])
            }
        }
    }
 
    $AllCounters = $MultiInstanceCounters + $SingleInstanceCounters 
    $key="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib\009"

    $counters=Get-ItemPropertyValue -Path $key -Name "counter"
    $Dict=@{}

    for ($i=0;$i -lt $counters.count;$i=$i+2){
        if($counters[$i+1] -and -not $Dict.ContainsKey($counters[$i+1])){
            $Dict.add($counters[$i+1],$counters[$i])
        }
    }
    Write-Debug $dict.keys.count
    $result=$AllCounters | Sort-Object Categoryname,Countername|
            Select-Object CategoryName,
            Countername,
            @{n="zabbixPerfCounter";e={'perf_counter["\{0}({{#ReplaceThis}})\{1}"]' -f $dict[$_.CategoryName],$dict[$_.Countername]}},
            @{n="categoryNum";e={$Dict[$_.CategoryName]}},
            @{n="CounterNum";e={$Dict[$_.Countername]}},
            CategoryHelp,
            CounterHelp

    if($show){
        $result|Out-GridView
    }else{
        $result
    }
}

Get-PerfCounterDesc -show