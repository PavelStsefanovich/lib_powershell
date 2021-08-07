
$lb = "["
$rb = "]"
$pre = " "
$prf = "#"
#$prf = ([char]1000).tostring()

write-host "`n Downloading packages ..."

$saveY = [console]::CursorTop

$prog1 = 0
$prog2 = 0
$prog3 = 0
$prog4 = 0

while (!($prog1 -ge 100 -and $prog2 -ge 100 -and $prog3 -ge 100 -and $prog4 -ge 100)) {
  $name = "first.pkg"
  [console]::CursorLeft = 0
  [console]::CursorTop = $saveY + 1
  if ($prog1 -lt 96) {
      $tmpStr1 = $prf * [System.Math]::Floor($prog1/2)
      $tmpStr2 = $pre * (50 - [System.Math]::Floor($prog1/2))
      $prog1string = $lb + $tmpStr1 + $tmpStr2 + $rb + "`t$name"
      $prog1string
  } else {
      $prog1string = $lb + ($prf * 50) + $rb + "`t$name"
      write-host $prog1string -NoNewline
      Write-Host ("`t" + [char]8730 + "   done") -ForegroundColor Green
  }

  $name = "second.pkg"
  [console]::CursorLeft = 0
  [console]::CursorTop = $saveY + 2
  if ($prog2 -lt 96) {
      $tmpStr1 = $prf * [System.Math]::Floor($prog2/2)
      $tmpStr2 = $pre * (50 - [System.Math]::Floor($prog2/2))
      $prog2string = $lb + $tmpStr1 + $tmpStr2 + $rb + "`t$name"
      $prog2string
  } else {
      $prog2string = $lb + ($prf * 50) + $rb + "`t$name"
      write-host $prog2string -NoNewline
      Write-Host ("`t" + [char]8730 + "   done") -ForegroundColor Green
  }

  $name = "third.pkg"
  [console]::CursorLeft = 0
  [console]::CursorTop = $saveY + 3
  if ($prog3 -lt 96) {
      $tmpStr1 = $prf * [System.Math]::Floor($prog3/2)
      $tmpStr2 = $pre * (50 - [System.Math]::Floor($prog3/2))
      $prog3string = $lb + $tmpStr1 + $tmpStr2 + $rb + "`t$name"
      $prog3string
  } else {
      $prog3string = $lb + ($prf * 50) + $rb + "`t$name"
      write-host $prog3string -NoNewline
      Write-Host ("`t" + [char]8730 + "   done") -ForegroundColor Green
  }

  $name = "someOther.pkg"
  [console]::CursorLeft = 0
  [console]::CursorTop = $saveY + 4
  if ($prog4 -lt 96) {
      $tmpStr1 = $prf * [System.Math]::Floor($prog4/2)
      $tmpStr2 = $pre * (50 - [System.Math]::Floor($prog4/2))
      $prog4string = $lb + $tmpStr1 + $tmpStr2 + $rb + "`t$name"
      $prog4string
  } else {
      $prog4string = $lb + ($prf * 50) + $rb + "`t$name"
      write-host $prog4string -NoNewline
      Write-Host ("`t" + [char]8730 + "   done") -ForegroundColor Green
  }

  sleep -Milliseconds 50

  $prog1+=2
  $prog2+=4
  $prog3++
  $prog4+=3
}

write-host " Success"
