CI/CD Setup for .NET Framework with Bitbucket Pipelines on Windows Self-Hosted Runner
--------------------------------------------------------------------------------------

This guide explains how to set up CI/CD for a .NET Framework project using Bitbucket Pipelines
on a Windows self-hosted runner.

Step 1: Install the Bitbucket Runner on Windows
-----------------------------------------------

1. Run the Bitbucket installation commands on the Windows server to install the runner.
   Refer to Bitbucket documentation to get the correct commands for your repository.

2. To keep the runner running continuously, configure it as a Windows service using NSSM.

   a. Download and install NSSM.
   b. Open Command Prompt as Administrator.
   c. Run the following commands:

      nssm install bitbucket
      nssm edit bitbucket

   d. In the NSSM UI:
      - Application Path:
        C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe

      - Startup Directory:
        C:\Users\Administrator\runner\atlassian-bitbucket-pipelines-runner\bin

      - Arguments:
        .\start.ps1 -accountUuid '{9b3eeea4-9c7e-4583-8e9e-8c3a041779df}' -repositoryUuid '{}' -runnerUuid '{}' -OAuthClientId z8zGq4YL3GJKPnfeA2RK86jRQuPEIbLz -OAuthClientSecret "" -workingDirectory 'C:\runner'

   e. Start the service:

      nssm start bitbucket


Step 2: Bitbucket Pipeline Configuration
----------------------------------------

Create a `.bitbucket-pipelines.yml` file in the root of your repository with the following content:

pipelines:
  branches:
    dev-server:
      - step:
          name: Build CSharp_Rpas.sln on Windows Self-Hosted
          runs-on:
            - self.hosted
            - windows
          script:
            - echo "Setting Git to allow long paths..."
            - git config --system core.longpaths true

            - echo "Current directory:"
            - powershell -Command "pwd"

            - echo "Navigating into 'ashish' folder..."
            - cd ashish

            - echo "Now inside:"
            - powershell -Command "pwd"

            - echo "Contents of 'ashish' folder:"
            - dir

            - powershell -Command "Get-Item 'packages\\Microsoft.ApplicationInsights.WindowsServer.TelemetryChannel.2.8.1\\lib\\net45\\Microsoft.AI.ServerTelemetryChannel.dll'"
            - powershell -Command "Get-Item 'packages\\Microsoft.CodeDom.Providers.DotNetCompilerPlatform.2.0.1\\lib\\net45\\Microsoft.CodeDom.Providers.DotNetCompilerPlatform.dll'"

            - powershell -Command "& 'C:\\Users\\Administrator\\Downloads\\nuget.exe' restore 'CSharp_Rpas.sln' -PackagesDirectory './packages'"
            - 'C:\\Users\\Administrator\\Downloads\\nuget.exe restore -Force CSharp_Rpas.sln'

            - echo "Building the solution with MSBuild..."
            - '& "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\Community\\MSBuild\\Current\\Bin\\MSBuild.exe" "CSharp_Rpas.sln" /p:OutputPath=C:\\BuildOutput'

            - echo "Build complete. Output available in C:\\BuildOutput"

            - echo "Publishing the solution using publish profile..."
            - '& "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\Community\\MSBuild\\Current\\Bin\\MSBuild.exe" "CSharp_Rpas.sln" /p:DeployOnBuild=true /p:PublishProfile=FolderProfile6 /p:Configuration=Release'

            - echo "Publish complete. Copying 'Source' folder to C:\\Publish if it exists..."
            - powershell -Command "if (Test-Path 'C:\\temp\\Publish\\Source') { Copy-Item -Recurse -Force 'C:\\temp\\Publish\\Source' 'C:\\Publish\\' } else { Write-Host 'Source folder not found. Skipping copy.' }"


Notes:
------

- Ensure the `ashish` folder and `CSharp_Rpas.sln` exist in the repository structure.
- Update the Visual Studio and runner paths if different on your machine.
- Make sure the NuGet packages are correctly restored before the MSBuild step.
