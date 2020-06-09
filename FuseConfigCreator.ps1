# Created by Safwan Karim Arup BNE
# Starting point Master_Driver function,

###########################################
# Description
# This script 
#   - creates a Fuse config.json file by reading an index.html and using an existing fuse config file as a template.
#   - create a folder called apps and move urls that DONT start with "http" into the apps folder.
#
# Input Param: A csv file with heading, "ConfigTemplate,AbsIndexFile"
#   ConfigTemplate: Contains the absolute path to a template config.json file.
#   AbsIndexFile: Should contain abs path to the index.html file

###########################################


$inputCsv = ".\indexPath.csv"
$csvRows = Import-Csv $inputCsv


#Get Urls From Index File
Function GetUrlFromIndexFile($absIndexFile ){
    $urls = @()
    $matches = Select-String -Path $absIndexFile -Pattern 'trustAsResourceUrl\("(.*?)"\)'
    foreach($match in $matches){
        try{
            $urls+= $match.Matches.Groups[1].Value
            Write-Host "Found URL: "$match.Matches.Groups[1].Value -ForegroundColor DarkGray
        }catch {

        }
    }

    return $urls
}

#Create Config File
Function CreateConfigFile($urls, $configJson){
    $config = Get-Content $configJson | ConvertFrom-Json
    # do urls for navbars
    $navTabsCopy = $config.navbar.tabs[0]
    $navTabArr = @()
    foreach($url in $urls){
        $navTabArr += $navTabsCopy.PsObject.Copy()
        $navTabArr[$navTabArr.Count-1].url = $url
    }
    $config.navbar.tabs = $navTabArr

    # do urls for tiles
    $tileDataCopy = $config.tiles.data[0]
    $tileDataArr = @()
    foreach($url in $urls){
        $tileDataArr += $tileDataCopy.PsObject.Copy()
        $tileDataArr[$tileDataArr.Count-1].url = $url
    }
    $config.tiles.data = $tileDataArr

    # write output to same folder as the index.html
    $path = Split-Path $absIndexFile
    $outPath = $path+"\config.json"
    $config | ConvertTo-Json -Depth 100 | % { [System.Text.RegularExpressions.Regex]::Unescape($_) } | Out-File $outPath
    Write-Host "Writing config.json to: " $outPath -ForegroundColor Cyan
    #Get-Content .\Template.json | ConvertFrom-Json | ConvertTo-Json -Depth 100 | % { [System.Text.RegularExpressions.Regex]::Unescape($_) } | Out-File .\Out.json
}

#Create Fuse Folder Structure
Function CreateFuseFolderStructure($urls, $absIndexFile){
    $dir = Split-Path $absIndexFile
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    foreach($url in $urls){
        if( ($url).StartsWith("http") -eq $False){
            $parentDir = $url.split("/")[0] 
            $src = $dir+"\"+$parentDir
            $dst = $dir+"\apps\"+$parentDir
            If(test-path $src)
            {
                Move-Item -Path $src -Destination $dst
                Write-Host "Moving:" $src "to" $dst -ForegroundColor Cyan
            }
            
        }
    }
}


Function Master_Driver(){

    foreach($csvRow in $csvRows){
        $absIndexFile = ""
        
        if($csvRow.ConfigTemplate.Length -le 0){
            Write-Host "Need a template config json file."
            return
        }

        if($csvRow.AbsIndexFile.Length -gt 0 -and ($csvRow.AbsIndexFile.Contains(".html") -or $csvRow.AbsIndexFile.Contains(".aspx"))){
            Write-Host "Reading file:" $csvRow.AbsIndexFile -ForegroundColor Cyan
            $absIndexFile = $csvRow.AbsIndexFile
        } else{
            Write-Host "Row empty!"
            return
        }

        if($absIndexFile){
            # read urls
            $urls = GetUrlFromIndexFile -absIndexFile $absIndexFile 
            # create config
            CreateConfigFile -urls $urls -configJson $csvRow.ConfigTemplate
            # move folder
            CreateFuseFolderStructure -urls $urls -absIndexFile $absIndexFile 
        }
    }
}


clear
Master_Driver