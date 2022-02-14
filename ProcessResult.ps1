Param (
    [Parameter()]
    [String]
    $Include,

    [Parameter()]
    [String]
    $Exclude,

    [Parameter()]
    [String]
    $RegEx
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$MasterList = Invoke-RestMethod -Uri https://raw.githubusercontent.com/PoeCoh/Wordle/main/Data.json

$Output = [PSCustomObject]@{
    WordList = $MasterList
    Recommend = $Null
    Characters = $Null
    Feedback = [System.Collections.Generic.List[String]]::New()
}

# Filter wordlist
If ($Include) {ForEach ($Char In [Char[]]$Include) {$Output.WordList = $Output.WordList.Where({$_ -Match $Char})}}
If ($Exclude) {$Output.WordList = $Output.WordList.Where({$_ -NotMatch "[$Exclude]"})}
If ($RegEx) {$Output.WordList = $Output.WordList.Where({$_ -Match $RegEx})}

# If no words
If ($Output.WordList.Count -Eq 0) {
    $Output.Feedback.Add('Your filters eliminated every possible word from the list.')

# If one word left
} ElseIf ($Output.WordList.Count -Eq 1) {
    $Output.Recommend = $Output.WordList[0].ToUpper()
    $Output.Feedback.Add("$($Output.Recommend) is the only valid word left.")
    $Output.Characters = [Char[]]$Output.Recommend

# Find next possible word
} Else {
    $Output.Feedback.Add("$($Output.WordList.Count) possible words remaining.")

    # Remove duplicate characters from words
    $Characters = ForEach ($Word In $Output.WordList) {
        $Chars = [Linq.Enumerable]::Distinct([Char[]]$Word)
        ForEach ($Char In $Chars) {$Char}
    }

    # Sort characters by most common
    $Characters = $Characters |
        Group-Object |
        Sort-Object -Property Count -Descending |
        Select-Object -ExpandProperty Name
    $Output.Characters = $Characters

    # Cycle through most common letters until list doesn't reduce.
    $Words = $Output.WordList
    While ($True) {
        $Starting = $Words.Count
        ForEach ($Char In $Characters) {
            $Temp = $Words.Where({$_ -Match $Char})
            If ($Temp) {$Words = $Temp}
        }
        If ($Starting -Eq $Words.Count) {Break}
    }
    
    # Any words left will all have the same characters
    $Output.Recommend = $Words[0].ToUpper()
    $Output.Feedback.Add("Try $($Output.Recommend) next.")
}

$Output
