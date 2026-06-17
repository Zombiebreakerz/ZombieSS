# ==============================================================================
# ZombieSS.ps1 – Minecraft-Themed Professional Tool Dashboard
# ==============================================================================
# GUI wrapper that organises forensic/analysis tools by category.
# CMD tools launch instantly; others download into ~\Downloads\ZombieSS.
#
# REQUIREMENTS: PowerShell 5.1+, Windows 10/11 (WPF support)
# USAGE: Just run the script (no admin required)
# ==============================================================================

# ------------------------------------------------------------------------------
# Load WPF assemblies
# ------------------------------------------------------------------------------
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml
Add-Type -AssemblyName System.Windows.Forms

# ------------------------------------------------------------------------------
# Enforce TLS 1.2
# ------------------------------------------------------------------------------
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
$script:installDir = "$env:USERPROFILE\Downloads\ZombieSS"

# ------------------------------------------------------------------------------
# Helper: timestamped log
# ------------------------------------------------------------------------------
function Write-Log {
    param([string]$msg)
    $time = Get-Date -Format "HH:mm:ss"
    if ($global:LogBox.Dispatcher.CheckAccess()) {
        $global:LogBox.AppendText("[$time] $msg`r`n")
        $global:LogBox.ScrollToEnd()
    } else {
        $global:LogBox.Dispatcher.Invoke([Action]{
            $global:LogBox.AppendText("[$time] $msg`r`n")
            $global:LogBox.ScrollToEnd()
        })
    }
}

# ------------------------------------------------------------------------------
# Helper: update status pane
# ------------------------------------------------------------------------------
function Set-Status {
    param($title, $sub, $badge = "BUSY")
    if ($global:StatusTitle.Dispatcher.CheckAccess()) {
        $global:StatusTitle.Text = $title
        $global:StatusSub.Text   = $sub
        $global:StatusBadge.Text = $badge
    } else {
        $global:StatusTitle.Dispatcher.Invoke([Action]{ $global:StatusTitle.Text = $title })
        $global:StatusSub.Dispatcher.Invoke([Action]{ $global:StatusSub.Text = $sub })
        $global:StatusBadge.Dispatcher.Invoke([Action]{ $global:StatusBadge.Text = $badge })
    }
}

# ------------------------------------------------------------------------------
# Helper: launch PowerShell command in new CMD window
# ------------------------------------------------------------------------------
function Start-CmdToolCommand {
    param([Parameter(Mandatory)][string]$Command)
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Command))
    Start-Process -FilePath "cmd.exe" -ArgumentList "/k", "powershell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded" -WindowStyle Normal
}

# ------------------------------------------------------------------------------
# Helper: atomic file download
# ------------------------------------------------------------------------------
function Save-UrlToFile {
    param([string]$Uri, [string]$OutFile)
    $temp = "$OutFile.download"
    Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "ZombieSS/1.0")
        $wc.DownloadFile($Uri, $temp)
        if (Test-Path -LiteralPath $OutFile) { Remove-Item -LiteralPath $OutFile -Force }
        Move-Item -LiteralPath $temp -Destination $OutFile -Force
    } finally {
        if ($wc) { $wc.Dispose() }
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
    }
}

# ==============================================================================
# TOOL DATA – Add / modify entries here
# ==============================================================================
$ToolData = @(
    # --- Orbdiff ---
    @{ Name="PrefetchView";          Category="Orbdiff";    Type="GitHub"; URL="https://github.com/Orbdiff/PrefetchView/releases/latest" },
    @{ Name="BAMReveal";             Category="Orbdiff";    Type="GitHub"; URL="https://github.com/Orbdiff/BAMReveal/releases/latest" },
    @{ Name="StringsParser";         Category="Orbdiff";    Type="GitHub"; URL="https://github.com/Orbdiff/StringsParser/releases/latest" },
    @{ Name="Fileless";              Category="Orbdiff";    Type="GitHub"; URL="https://github.com/Orbdiff/Fileless/releases/latest" },
    @{ Name="DPS-Analyzer";          Category="Orbdiff";    Type="GitHub"; URL="https://github.com/Orbdiff/DPS-Analyzer/releases/latest" },
    @{ Name="UserAssistView";        Category="Orbdiff";    Type="GitHub"; URL="https://github.com/Orbdiff/UserAssistView/releases/latest" },
    @{ Name="JournalParser";         Category="Orbdiff";    Type="GitHub"; URL="https://github.com/Orbdiff/JournalParser/releases/latest" },
    @{ Name="InjGen";                Category="Orbdiff";    Type="GitHub"; URL="https://github.com/Orbdiff/InjGen/releases/latest" },
    @{ Name="USBDetector";           Category="Orbdiff";    Type="GitHub"; URL="https://github.com/Orbdiff/USBDetector/releases/latest" },
    @{ Name="PFTrace";               Category="Orbdiff";    Type="GitHub"; URL="https://github.com/Orbdiff/PFTrace/releases/latest" },
    @{ Name="CheckDeletedUSN";       Category="Orbdiff";    Type="GitHub"; URL="https://github.com/Orbdiff/CheckDeletedUSN/releases/latest" },
    @{ Name="JARParser";             Category="Orbdiff";    Type="GitHub"; URL="https://github.com/Orbdiff/JARParser/releases/latest" },

    # --- Spokwn ---
    @{ Name="BAM-parser";            Category="Spokwn";     Type="GitHub"; URL="https://github.com/spokwn/BAM-parser/releases/latest" },
    @{ Name="PathsParser";           Category="Spokwn";     Type="GitHub"; URL="https://github.com/spokwn/PathsParser/releases/latest" },
    @{ Name="JournalTrace";          Category="Spokwn";     Type="GitHub"; URL="https://github.com/spokwn/JournalTrace/releases/latest" },
    @{ Name="KernelLiveDumpTool";    Category="Spokwn";     Type="GitHub"; URL="https://github.com/spokwn/KernelLiveDumpTool/releases/latest" },
    @{ Name="BamDeletedKeys";        Category="Spokwn";     Type="GitHub"; URL="https://github.com/spokwn/BamDeletedKeys/releases/latest" },
    @{ Name="Espouken Tool";         Category="Spokwn";     Type="GitHub"; URL="https://github.com/spokwn/Tool/releases/latest" },
    @{ Name="pcasvc-executed";       Category="Spokwn";     Type="GitHub"; URL="https://github.com/spokwn/pcasvc-executed/releases/latest" },
    @{ Name="process-parser";        Category="Spokwn";     Type="GitHub"; URL="https://github.com/spokwn/process-parser/releases/latest" },
    @{ Name="prefetch-parser";       Category="Spokwn";     Type="GitHub"; URL="https://github.com/spokwn/prefetch-parser/releases/latest" },
    @{ Name="ActivitiesCache";       Category="Spokwn";     Type="GitHub"; URL="https://github.com/spokwn/ActivitiesCache-execution/releases/latest" },

    # --- Tonynoh ---
    @{ Name="MeowDoomsdayFucker";    Category="Tonynoh";    Type="GitHub"; URL="https://github.com/MeowTonynoh/MeowDoomsdayFucker/releases/latest" },
    @{ Name="MeowModAnalyzer";       Category="Tonynoh";    Type="Cmd";    Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/MeowTonynoh/MeowModAnalyzer/main/MeowModAnalyzer.ps1')" },
    @{ Name="MeowResolver";          Category="Tonynoh";    Type="GitHub"; URL="https://github.com/MeowTonynoh/MeowResolver/releases/latest" },
    @{ Name="MeowNovowareFucker";    Category="Tonynoh";    Type="GitHub"; URL="https://github.com/MeowTonynoh/MeowNovowareFucker/releases/latest" },
    @{ Name="MeowImportsChecker";    Category="Tonynoh";    Type="GitHub"; URL="https://github.com/MeowTonynoh/MeowImportsChecker/releases/latest" },

    # --- Praiselily ---
    @{ Name="PSHunter";              Category="Praiselily"; Type="GitHub"; URL="https://github.com/praiselily/PSHunter/releases/latest" },
    @{ Name="AltDetector";           Category="Praiselily"; Type="GitHub"; URL="https://github.com/praiselily/AltDetector/releases/latest" },
    @{ Name="WeHateFakers";          Category="Praiselily"; Type="Cmd";    Command="iwr https://raw.githubusercontent.com/praiselily/WeHateFakers/refs/heads/main/HotspotLogs.ps1 | iex" },
    @{ Name="CommonDirectories";     Category="Praiselily"; Type="Cmd";    Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/CommonDirectories.ps1')" },
    @{ Name="HarddiskConverter";     Category="Praiselily"; Type="Cmd";    Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/HarddiskConverter.ps1')" },
    @{ Name="Services";              Category="Praiselily"; Type="Cmd";    Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Services.ps1')" },
    @{ Name="SignedScheduledTasks";  Category="Praiselily"; Type="Cmd";    Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Signed-Scheduled-Tasks.ps1')" },

    # --- RedLotus ---
    @{ Name="RL ModAnalyzer";        Category="RedLotus";   Type="GitHub"; URL="https://github.com/ItzIceHere/RedLotus-Mod-Analyzer/releases/latest" },
    @{ Name="RL TaskSentinel";       Category="RedLotus";   Type="GitHub"; URL="https://github.com/ItzIceHere/RedLotus-Task-Sentinel/releases/latest" },
    @{ Name="RL AltChecker";         Category="RedLotus";   Type="GitHub"; URL="https://github.com/ItzIceHere/RedLotusAltChecker/releases/latest" },

    # --- Zimmerman ---
    @{ Name="bstrings";              Category="Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/bstrings.zip" },
    @{ Name="JLECmd";                Category="Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/JLECmd.zip" },
    @{ Name="JumpListExplorer";      Category="Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/JumpListExplorer.zip" },
    @{ Name="MFTECmd";               Category="Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/MFTECmd.zip" },
    @{ Name="PECmd";                 Category="Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/PECmd.zip" },
    @{ Name="RecentFileCacheParser"; Category="Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/RecentFileCacheParser.zip" },
    @{ Name="RegistryExplorer";      Category="Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/RegistryExplorer.zip" },
    @{ Name="ShellBagsExplorer";     Category="Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/ShellBagsExplorer.zip" },
    @{ Name="SrumECmd";              Category="Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/SrumECmd.zip" },
    @{ Name="TimelineExplorer";      Category="Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/TimelineExplorer.zip" },

    # --- Dependencies ---
    @{ Name="NET 9.0 SDK";           Category="Dependencies"; Type="Web"; URL="https://download.visualstudio.microsoft.com/download/pr/92dba916-bc51-4e76-8b0e-d41d37ce5fa4/ab08f3e95bf7a3d3da336a7e8c8eca63/dotnet-sdk-9.0.203-win-x64.exe" },
    @{ Name="NET 10.0 Runtime";      Category="Dependencies"; Type="Web"; URL="https://download.visualstudio.microsoft.com/download/pr/b3f93f0e-9e5e-4b4c-a4c4-36db0c4b0e3e/dotnet-runtime-10.0.0-win-x64.exe" },
    @{ Name="VSRedist";              Category="Dependencies"; Type="Web"; URL="https://aka.ms/vs/17/release/vc_redist.x64.exe" },

    # --- Others ---
    @{ Name="WinPrefetchView";       Category="Others";     Type="Web";    URL="https://www.nirsoft.net/utils/win_prefetch_view.html" },
    @{ Name="ComputerActivityView";  Category="Others";     Type="Web";    URL="https://www.nirsoft.net/utils/computer_activity_view.html" },
    @{ Name="AmcacheParser";         Category="Others";     Type="Web";    URL="https://download.ericzimmermanstools.com/net9/AmcacheParser.zip" },
    @{ Name="SystemInformer";        Category="Others";     Type="Link";   URL="https://www.systeminformer.com/canary" },
    @{ Name="DIE-engine";            Category="Others";     Type="Web";    URL="https://github.com/horsicq/DIE-engine/releases" },
    @{ Name="DQRKIS-FUCKER";         Category="Others";     Type="Cmd";    Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/cheesecatlol/DQRKIS-FUCKER/refs/heads/main/DqrkisFucker.ps1')" },
    @{ Name="MacroDetector";         Category="Others";     Type="Cmd";    Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/Nickk196/MacroDetector/refs/heads/main/MacroDetector.ps1')" }
)

# ==============================================================================
# XAML UI – Minecraft Clean Theme (with centred sidebar text)
# ==============================================================================
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="ZombieSS"
    Width="1200" Height="760"
    MinWidth="1200" MinHeight="760"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent"
    FontFamily="Consolas">

    <Window.Resources>
        <!-- Minecraft colour palette -->
        <SolidColorBrush x:Key="MainBg"     Color="#2D2A26"/>
        <SolidColorBrush x:Key="SidebarBg"  Color="#3C3A36"/>
        <SolidColorBrush x:Key="CardBg"     Color="#4C4A46"/>
        <SolidColorBrush x:Key="Accent"     Color="#5D9C3F"/>
        <SolidColorBrush x:Key="AccentDim"  Color="#3B8526"/>
        <SolidColorBrush x:Key="TextMain"   Color="#E0E0E0"/>
        <SolidColorBrush x:Key="TextMuted"  Color="#A0A0A0"/>
        <SolidColorBrush x:Key="ConsoleBg"  Color="#1E1E1E"/>
        <SolidColorBrush x:Key="BorderCol"  Color="#5A5A5A"/>

              <Style x:Key="SideBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource TextMain}"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Height" Value="40"/>
            <Setter Property="Margin" Value="0,0,0,2"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="HorizontalContentAlignment" Value="Center"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                CornerRadius="4"
                                Margin="4,0">
                            <ContentPresenter HorizontalAlignment="Center"
                                              VerticalAlignment="Center"
                                              TextBlock.TextAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#5D9C3F"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Title bar button -->
        <Style x:Key="TitleBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource TextMuted}"/>
            <Setter Property="Width" Value="40"/>
            <Setter Property="Height" Value="36"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#5D9C3F"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Border Background="{StaticResource MainBg}"
            BorderBrush="{StaticResource BorderCol}"
            BorderThickness="2"
            CornerRadius="8">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="42"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <!-- Title Bar -->
            <Border Grid.Row="0"
                    Background="{StaticResource SidebarBg}"
                    CornerRadius="8,8,0,0">
                <Grid Margin="16,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                        <TextBlock Text="⛏️" FontSize="16" Foreground="{StaticResource Accent}" FontFamily="Segoe UI Emoji"/>
                        <TextBlock Text=" ZombieSS" FontSize="14" FontWeight="SemiBold" Foreground="{StaticResource TextMain}"/>
                        <TextBlock Text="  ·  ready" FontSize="11" Foreground="{StaticResource TextMuted}" VerticalAlignment="Center" Margin="8,0,0,0"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1" Orientation="Horizontal">
                        <Button x:Name="OpenFolderBtn" Content="📁" ToolTip="Open Install Folder" Style="{StaticResource TitleBtn}" Width="40"/>
                        <Button x:Name="ClearCacheBtn" Content="🗑️" ToolTip="Clear Downloaded Files" Style="{StaticResource TitleBtn}" Width="40"/>
                        <Button x:Name="OpenCmdBtn"    Content=">_" ToolTip="Open CMD" Style="{StaticResource TitleBtn}" Width="40"/>
                        <Button x:Name="MinBtn"   Style="{StaticResource TitleBtn}" Content="_"/>
                        <Button x:Name="CloseBtn" Style="{StaticResource TitleBtn}" Content="X"/>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- Body -->
            <Grid Grid.Row="1">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="210"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- Sidebar -->
                <Border Grid.Column="0"
                        Background="{StaticResource SidebarBg}"
                        BorderBrush="{StaticResource BorderCol}"
                        BorderThickness="0,0,2,0">
                    <StackPanel Margin="12,16,12,16">
                        <TextBlock Text="TOOL HUB"
                                   FontFamily="Consolas"
                                   FontSize="22"
                                   FontWeight="SemiBold"
                                   Foreground="{StaticResource Accent}"
                                   HorizontalAlignment="Center"
                                   Margin="0,0,0,6"/>
                        <TextBlock Text="by Zombiebreakerz"
                                   FontSize="10"
                                   Foreground="{StaticResource TextMuted}"
                                   HorizontalAlignment="Center"
                                   Margin="0,0,0,16"/>

                        <TextBlock Text="CATEGORIES"
                                   FontSize="9"
                                   FontWeight="Bold"
                                   Foreground="{StaticResource TextMuted}"
                                   Margin="8,0,0,6"/>

                        <StackPanel x:Name="CategoryPanel" />

                        <Separator Background="{StaticResource BorderCol}" Margin="0,10,0,10"/>

                        <TextBlock Text="INSTALL PATH"
                                   FontSize="9"
                                   FontWeight="Bold"
                                   Foreground="{StaticResource TextMuted}"
                                   Margin="8,0,0,4"/>
                        <TextBlock x:Name="InstPathBlock"
                                   Text=""
                                   FontSize="9"
                                   Foreground="#999999"
                                   TextWrapping="Wrap"
                                   Margin="8,0,0,12"/>
                    </StackPanel>
                </Border>

                <!-- Main Panel -->
                <Grid Grid.Column="1" Margin="16,16,16,16">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="10"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="10"/>
                        <RowDefinition Height="160"/>
                    </Grid.RowDefinitions>

                    <!-- Status card -->
                    <Border Grid.Row="0"
                            Background="{StaticResource CardBg}"
                            CornerRadius="6"
                            Padding="16,10"
                            BorderBrush="{StaticResource BorderCol}"
                            BorderThickness="2">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel>
                                <TextBlock x:Name="StatusTitle"
                                           Text="Ready"
                                           FontSize="20"
                                           FontWeight="SemiBold"
                                           Foreground="{StaticResource TextMain}"/>
                                <TextBlock x:Name="StatusSub"
                                           Text="Select a tool to launch or download it."
                                           FontSize="11"
                                           Foreground="{StaticResource TextMuted}"/>
                            </StackPanel>
                            <Border Grid.Column="1"
                                    Background="{StaticResource AccentDim}"
                                    CornerRadius="4"
                                    Padding="10,4"
                                    VerticalAlignment="Center">
                                <TextBlock x:Name="StatusBadge"
                                           Text="IDLE"
                                           FontSize="12"
                                           FontWeight="Bold"
                                           Foreground="#FFFFFF"/>
                            </Border>
                        </Grid>
                    </Border>

                    <!-- Tool display area -->
                    <Border Grid.Row="2"
                            Background="{StaticResource CardBg}"
                            CornerRadius="6"
                            BorderBrush="{StaticResource BorderCol}"
                            BorderThickness="2">
                        <ScrollViewer x:Name="CenterScroll"
                                      VerticalScrollBarVisibility="Auto"
                                      HorizontalScrollBarVisibility="Disabled">
                            <WrapPanel x:Name="ToolsWrap" Margin="8" />
                        </ScrollViewer>
                    </Border>

                    <!-- Console log -->
                    <Border Grid.Row="4"
                            Background="{StaticResource ConsoleBg}"
                            CornerRadius="6"
                            Padding="12,8"
                            BorderBrush="{StaticResource BorderCol}"
                            BorderThickness="2">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <TextBlock Text="ACTIVITY LOG"
                                       FontSize="9"
                                       FontWeight="Bold"
                                       Foreground="{StaticResource Accent}"
                                       FontFamily="Consolas"
                                       Margin="0,0,0,4"/>
                            <TextBox x:Name="LogBox"
                                     Grid.Row="1"
                                     Background="Transparent"
                                     Foreground="{StaticResource Accent}"
                                     BorderThickness="0"
                                     FontFamily="Consolas"
                                     FontSize="11"
                                     IsReadOnly="True"
                                     VerticalScrollBarVisibility="Auto"
                                     TextWrapping="Wrap"/>
                        </Grid>
                    </Border>
                </Grid>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

# ------------------------------------------------------------------------------
# Load XAML and wire controls
# ------------------------------------------------------------------------------
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$global:MinBtn        = $window.FindName("MinBtn")
$global:CloseBtn      = $window.FindName("CloseBtn")
$global:StatusTitle   = $window.FindName("StatusTitle")
$global:StatusSub     = $window.FindName("StatusSub")
$global:StatusBadge   = $window.FindName("StatusBadge")
$global:LogBox        = $window.FindName("LogBox")
$global:CenterScroll  = $window.FindName("CenterScroll")
$global:ToolsWrap     = $window.FindName("ToolsWrap")
$global:CategoryPanel = $window.FindName("CategoryPanel")
$global:OpenFolderBtn = $window.FindName("OpenFolderBtn")
$global:ClearCacheBtn = $window.FindName("ClearCacheBtn")
$global:OpenCmdBtn    = $window.FindName("OpenCmdBtn")
$global:InstPathBlock = $window.FindName("InstPathBlock")

$global:InstPathBlock.Text = "Install path:`n$script:installDir"

# ------------------------------------------------------------------------------
# Dynamic tool button – proper visual content
# ------------------------------------------------------------------------------
function New-ToolButton {
    param($Tool)

    $btn = New-Object System.Windows.Controls.Button
    $btn.Width  = 180
    $btn.Height = 80
    $btn.Margin = "6"
    $btn.Cursor = "Hand"
    $btn.Tag    = $Tool

    $contentXaml = @"
<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Margin="6">
    <Grid.RowDefinitions>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <TextBlock Text="$($Tool.Name)" FontWeight="SemiBold" VerticalAlignment="Center" TextWrapping="Wrap" Foreground="#E0E0E0"/>
    <Border Grid.Row="1" Background="#3B8526" CornerRadius="3" Padding="4,2" HorizontalAlignment="Right" Margin="0,4,0,0">
        <TextBlock Text="$($Tool.Type.ToUpper())" FontSize="9" FontWeight="Bold" Foreground="#FFFFFF"/>
    </Border>
</Grid>
"@
    $content = [Windows.Markup.XamlReader]::Parse($contentXaml)
    $btn.Content = $content

    $templateXaml = @"
<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" TargetType="Button">
    <Border Background="#3C3A36"
            CornerRadius="6"
            BorderBrush="#5A5A5A"
            BorderThickness="2"
            Padding="6">
        <ContentPresenter HorizontalAlignment="Stretch" VerticalAlignment="Stretch"/>
    </Border>
    <ControlTemplate.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
            <Setter Property="Background" Value="#5D9C3F"/>
            <Setter Property="BorderBrush" Value="#3B8526"/>
        </Trigger>
    </ControlTemplate.Triggers>
</ControlTemplate>
"@
    $btn.Template = [Windows.Markup.XamlReader]::Parse($templateXaml)

    # Click handler (unchanged)
    $btn.Add_Click({
        $clickedBtn = $_.Source
        $toolData = $clickedBtn.Tag
        if (-not $toolData) { return }

        $origBg = $clickedBtn.Background
        $clickedBtn.IsEnabled = $false
        Start-Sleep -Milliseconds 80

        $cleanName = $toolData.Name
        switch ($toolData.Type) {
            "Cmd" {
                Set-Status "Running" "Launching $cleanName..." "BUSY"
                Write-Log "Executing: $cleanName"
                try {
                    Start-CmdToolCommand -Command $toolData.Command
                    Write-Log "$cleanName started"
                    Set-Status "Ready" "$cleanName launched" "IDLE"
                } catch {
                    Write-Log "Error: $_"
                    Set-Status "Error" "Failed to launch $cleanName" "ERR"
                }
                $clickedBtn.Background = $origBg
                $clickedBtn.IsEnabled  = $true
            }
            "Link" {
                Set-Status "Browser" "Opening $cleanName" "IDLE"
                Write-Log "Opening browser: $cleanName"
                Start-Process $toolData.URL
                $clickedBtn.Background = $origBg
                $clickedBtn.IsEnabled  = $true
            }
            "GitHub" {
                Set-Status "Downloading" "Fetching $cleanName..." "BUSY"
                Write-Log "Background download: $cleanName"

                $rs = [runspacefactory]::CreateRunspace()
                $rs.ApartmentState = "STA"
                $rs.ThreadOptions  = "ReuseThread"
                $rs.Open()
                $ps = [powershell]::Create()
                $ps.Runspace = $rs

                $null = $rs.SessionStateProxy.SetVariable("toolData", $toolData)
                $null = $rs.SessionStateProxy.SetVariable("installDir", $script:installDir)
                $null = $rs.SessionStateProxy.SetVariable("dispatcher", $clickedBtn.Dispatcher)
                $null = $rs.SessionStateProxy.SetVariable("btn", $clickedBtn)
                $null = $rs.SessionStateProxy.SetVariable("origBg", $origBg)
                $null = $rs.SessionStateProxy.SetVariable("StatusTitle", $global:StatusTitle)
                $null = $rs.SessionStateProxy.SetVariable("StatusSub",   $global:StatusSub)
                $null = $rs.SessionStateProxy.SetVariable("StatusBadge", $global:StatusBadge)
                $null = $rs.SessionStateProxy.SetVariable("LogBox",      $global:LogBox)

                $null = $ps.AddScript({
                    function Write-LogBg { param($m) $dispatcher.Invoke([Action]{ $LogBox.AppendText("[$(Get-Date -f HH:mm:ss)] $m`n"); $LogBox.ScrollToEnd() }) }
                    function Set-StatusBg { param($t,$s,$b) $dispatcher.Invoke([Action]{ $StatusTitle.Text=$t; $StatusSub.Text=$s; $StatusBadge.Text=$b }) }
                    function Restore-Button { $dispatcher.Invoke([Action]{ $btn.Background=$origBg; $btn.IsEnabled=$true }) }

                    try {
                        $name = $toolData.Name; $cat = $toolData.Category
                        $destDir = "$installDir\$cat\$name"
                        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

                        $urlParts = $toolData.URL -replace "https://github.com/", "" -split "/"
                        $owner = $urlParts[0]; $repo = $urlParts[1]
                        $api = "https://api.github.com/repos/$owner/$repo/releases/latest"
                        $headers = @{ "User-Agent"="ZombieSS" }
                        $release = Invoke-RestMethod -Uri $api -Headers $headers -ErrorAction Stop
                        $asset = $release.assets | Where-Object { $_.name -match "\.(exe|zip)$" } | Select-Object -First 1
                        if (-not $asset) { throw "No exe/zip asset found" }
                        $fileName = $asset.name
                        $destFile = "$destDir\$fileName"

                        if (Test-Path $destFile) {
                            Write-LogBg "Cached: $fileName"
                        } else {
                            Write-LogBg "Downloading $fileName..."
                            $wc = New-Object System.Net.WebClient
                            $wc.DownloadFile($asset.browser_download_url, $destFile)
                            $wc.Dispose()
                            Write-LogBg "Download complete"
                        }

                        if ($fileName -match "\.zip$") {
                            Write-LogBg "Extracting..."
                            Expand-Archive -Path $destFile -DestinationPath $destDir -Force -ErrorAction Stop
                        }

                        Write-LogBg "Folder ready: $destDir"
                        Start-Process explorer.exe $destDir
                        Set-StatusBg "Ready" "$name downloaded" "IDLE"
                    } catch {
                        Write-LogBg "Error: $_"
                        Set-StatusBg "Error" "Something went wrong" "ERR"
                    } finally {
                        Restore-Button
                        $rs.Close()
                        $rs.Dispose()
                        $ps.Dispose()
                    }
                })
                $null = $ps.BeginInvoke()
            }
            "Web" {
                Set-Status "Downloading" "Fetching $cleanName..." "BUSY"
                Write-Log "Background download: $cleanName"

                $rs = [runspacefactory]::CreateRunspace()
                $rs.ApartmentState = "STA"; $rs.ThreadOptions = "ReuseThread"
                $rs.Open()
                $ps = [powershell]::Create()
                $ps.Runspace = $rs

                $null = $rs.SessionStateProxy.SetVariable("toolData", $toolData)
                $null = $rs.SessionStateProxy.SetVariable("installDir", $script:installDir)
                $null = $rs.SessionStateProxy.SetVariable("dispatcher", $clickedBtn.Dispatcher)
                $null = $rs.SessionStateProxy.SetVariable("btn", $clickedBtn)
                $null = $rs.SessionStateProxy.SetVariable("origBg", $origBg)
                $null = $rs.SessionStateProxy.SetVariable("StatusTitle", $global:StatusTitle)
                $null = $rs.SessionStateProxy.SetVariable("StatusSub",   $global:StatusSub)
                $null = $rs.SessionStateProxy.SetVariable("StatusBadge", $global:StatusBadge)
                $null = $rs.SessionStateProxy.SetVariable("LogBox",      $global:LogBox)

                $null = $ps.AddScript({
                    function Write-LogBg { param($m) $dispatcher.Invoke([Action]{ $LogBox.AppendText("[$(Get-Date -f HH:mm:ss)] $m`n"); $LogBox.ScrollToEnd() }) }
                    function Set-StatusBg { param($t,$s,$b) $dispatcher.Invoke([Action]{ $StatusTitle.Text=$t; $StatusSub.Text=$s; $StatusBadge.Text=$b }) }
                    function Restore-Button { $dispatcher.Invoke([Action]{ $btn.Background=$origBg; $btn.IsEnabled=$true }) }

                    try {
                        $name = $toolData.Name; $url = $toolData.URL; $cat = $toolData.Category
                        $destDir = "$installDir\$cat\$name"
                        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

                        $fileName = ($url -split "/")[-1]
                        $destFile = "$destDir\$fileName"
                        if (Test-Path $destFile) {
                            Write-LogBg "Cached: $fileName"
                        } else {
                            Write-LogBg "Downloading $fileName..."
                            $wc = New-Object System.Net.WebClient
                            $wc.DownloadFile($url, $destFile)
                            $wc.Dispose()
                            Write-LogBg "Download complete"
                        }

                        if ($fileName -match "\.zip$") {
                            Write-LogBg "Extracting..."
                            Expand-Archive -Path $destFile -DestinationPath $destDir -Force -ErrorAction Stop
                        }

                        Write-LogBg "Folder ready: $destDir"
                        Start-Process explorer.exe $destDir
                        Set-StatusBg "Ready" "$name downloaded" "IDLE"
                    } catch {
                        Write-LogBg "Error: $_"
                        Set-StatusBg "Error" "Something went wrong" "ERR"
                    } finally {
                        Restore-Button
                        $rs.Close()
                        $rs.Dispose()
                        $ps.Dispose()
                    }
                })
                $null = $ps.BeginInvoke()
            }
        }
    })

    return $btn
}

# ------------------------------------------------------------------------------
# Sidebar categories & switching
# ------------------------------------------------------------------------------
$categories = @("Orbdiff","Spokwn","Tonynoh","Praiselily","RedLotus","Zimmerman","Dependencies","Others")

function Set-ActiveCategory {
    param($activeBtn)
    foreach ($child in $global:CategoryPanel.Children) {
        if ($child -is [System.Windows.Controls.Button]) {
            $child.Background = "Transparent"
            $child.Foreground = "#E0E0E0"
        }
    }
    $activeBtn.Background = "#5D9C3F"
    $activeBtn.Foreground = "#FFFFFF"
}

function Show-CategoryTools {
    param($cat)
    $global:ToolsWrap.Children.Clear()
    if ($cat -eq "Credits") {
        # Build dynamic credits list – all tools grouped by category
        $sb = New-Object System.Text.StringBuilder
        [void]$sb.AppendLine("ZombieSS Tool Dashboard")
        [void]$sb.AppendLine("Created by Zombiebreakerz")
        [void]$sb.AppendLine("═══════════════════════════════════════")
        [void]$sb.AppendLine("Tools & Credits")
        [void]$sb.AppendLine("")

        foreach ($c in $categories) {
            $toolsInCat = $ToolData | Where-Object { $_.Category -eq $c }
            $count = @($toolsInCat).Count
            [void]$sb.AppendLine("» $c ($count tools)")
            foreach ($t in $toolsInCat) {
                [void]$sb.AppendLine("   • $($t.Name) ($($t.Type))")
            }
            [void]$sb.AppendLine("")
        }

        [void]$sb.AppendLine("═══════════════════════════════════════")
        [void]$sb.AppendLine("All tools are property of their respective authors.")
        [void]$sb.AppendLine("This dashboard merely provides quick access.")

        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Text = $sb.ToString()
        $tb.FontFamily = "Consolas"
        $tb.FontSize = 12
        $tb.Foreground = "#E0E0E0"
        $tb.Margin = "12"
        $tb.TextWrapping = "Wrap"
        $global:ToolsWrap.Children.Add($tb) | Out-Null
    } else {
        $catTools = $ToolData | Where-Object { $_.Category -eq $cat }
        if ($catTools) {
            foreach ($tool in $catTools) {
                $btn = New-ToolButton -Tool $tool
                $global:ToolsWrap.Children.Add($btn) | Out-Null
            }
        } else {
            $tb = New-Object System.Windows.Controls.TextBlock
            $tb.Text = "No tools available for this category."
            $tb.FontSize = 12
            $tb.Foreground = "#A0A0A0"
            $tb.Margin = "12"
            $global:ToolsWrap.Children.Add($tb) | Out-Null
        }
    }
}

# Build sidebar buttons
foreach ($cat in $categories) {
    $catBtn = New-Object System.Windows.Controls.Button
    $catBtn.Content = $cat
    $catBtn.Style = $window.Resources["SideBtn"]
    $catBtn.Tag = $cat
    $catBtn.Add_Click({
        Set-ActiveCategory -activeBtn $_.Source
        Show-CategoryTools -cat $_.Source.Tag.ToString()
    })
    $global:CategoryPanel.Children.Add($catBtn) | Out-Null
}

# Credits button
$creditsBtn = New-Object System.Windows.Controls.Button
$creditsBtn.Content = "Credits"
$creditsBtn.Style = $window.Resources["SideBtn"]
$creditsBtn.Tag = "Credits"
$creditsBtn.Add_Click({
    Set-ActiveCategory -activeBtn $_.Source
    Show-CategoryTools -cat "Credits"
})
$global:CategoryPanel.Children.Add($creditsBtn) | Out-Null

# Select first category
if ($categories.Count -gt 0) {
    $firstBtn = $global:CategoryPanel.Children | Where-Object { $_.Tag -eq $categories[0] } | Select-Object -First 1
    if ($firstBtn) {
        Set-ActiveCategory -activeBtn $firstBtn
        Show-CategoryTools -cat $categories[0]
    }
}

# ------------------------------------------------------------------------------
# Window control events
# ------------------------------------------------------------------------------
$window.Add_MouseLeftButtonDown({ try { $window.DragMove() } catch {} })
$global:CloseBtn.Add_Click({ $window.Close() })
$global:MinBtn.Add_Click({ $window.WindowState = "Minimized" })

$global:OpenFolderBtn.Add_Click({
    if (-not (Test-Path $script:installDir)) { New-Item -ItemType Directory -Path $script:installDir -Force | Out-Null }
    Start-Process explorer.exe $script:installDir
    Write-Log "Opened install folder"
})

$global:ClearCacheBtn.Add_Click({
    if (Test-Path $script:installDir) {
        $items = Get-ChildItem -Path $script:installDir -Force -ErrorAction SilentlyContinue
        $count = @($items).Count
        $items | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Cleared $count item(s)"
        Set-Status "Clean" "Removed downloaded files" "IDLE"
    } else {
        Write-Log "Nothing to clear"
    }
})

$global:OpenCmdBtn.Add_Click({
    Start-Process -FilePath "cmd.exe"
    Write-Log "Opened CMD"
})

# ------------------------------------------------------------------------------
# Launch
# ------------------------------------------------------------------------------
Write-Log "ZombieSS ready – files saved to $script:installDir"
Set-Status "Ready" "Select a tool – CMDs run instantly, others download." "IDLE"

$window.ShowDialog() | Out-Null
