function Upgrade-NAVContainerAppOnDockerHost {
    param(
        [Parameter(Mandatory = $true)]
        [String] $DockerHost,
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $DockerHostCredentials,
        [Parameter(Mandatory = $false)]
        [Switch] $DockerHostUseSSL,
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.Remoting.PSSessionOption] $DockerHostSessionOption,
        [Parameter(Mandatory = $true)]
        [String] $ContainerName,
        [Parameter(Mandatory = $true)]
        [String] $AppFileName
    )

    $LocalAppPath = 
        Copy-NAVAppToDockerHost `
            -DockerHost $DockerHost `
            -DockerHostCredentials $DockerHostCredentials `
            -DockerHostUseSSL:$DockerHostUseSSL `
            -DockerHostSessionOption $DockerHostSessionOption `
            -ContainerName $ContainerName `
            -AppFileName $AppFileName

    Invoke-Command -ComputerName $DockerHost -UseSSL:$DockerHostUseSSL -Credential $DockerHostCredentials -SessionOption $DockerHostSessionOption -ScriptBlock {
        param(
            $ContainerName, $LocalAppPath
        )
        
        $Session = Get-NavContainerSession -containerName $ContainerName
        Invoke-Command -Session $Session -ScriptBlock {
            param(
                $LocalAppPath
            )
        
            $App = Get-NAVAppInfo -Path $LocalAppPath

            Get-NAVAppInfo -ServerInstance NAV -Name $App.Name -Publisher $App.Publisher -Version $App.Version |
                Uninstall-NAVApp

            Get-NAVAppInfo -ServerInstance NAV -Name $App.Name -Publisher $App.Publisher -Version $App.Version |
                Unpublish-NAVApp
            
            Publish-NAVApp `
                -ServerInstance NAV `
                -Path $LocalAppPath `
                -SkipVerification

            Sync-NAVApp `
                -ServerInstance NAV `
                -Name $App.Name `
                -Publisher $App.Publisher `
                -Version $App.Version

            Start-NAVAppDataUpgrade `
                -ServerInstance NAV `
                -Name $App.Name `
                -Publisher $App.Publisher `
                -Version $App.Version                

        }   -ArgumentList $LocalAppPath
    }   -ArgumentList $ContainerName, $LocalAppPath

}