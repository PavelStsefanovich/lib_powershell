$to_natural = { [regex]::Replace($_, '\d+', { $args[0].Value.PadLeft(20) }) }
dir | Sort-Object $to_natural
