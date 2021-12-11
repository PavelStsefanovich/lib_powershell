function RunGroovyScriptOnJenkinsServer ($jenkinsUrl, $groovyScript, $wc) {
    $url = $jenkinsUrl + "/scriptText"
    $nvc = New-Object System.Collections.Specialized.NameValueCollection
    $nvc.Add("script", $groovyScript);
    try {
        $byteRes = $wc.UploadValues($url, "POST", $nvc)
    }
    catch {
        throw $_
    }
    $res = [System.Text.Encoding]::UTF8.GetString($byteRes)
    return $res
}
