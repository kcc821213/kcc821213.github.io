param(
    [switch]$SmokeTest
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

[xml]$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Digital Clock"
    Width="315"
    Height="101"
    WindowStyle="None"
    ResizeMode="NoResize"
    AllowsTransparency="True"
    Background="Transparent"
    ShowInTaskbar="True"
    Topmost="True">
    <Border
        x:Name="ClockBorder"
        Margin="6"
        Padding="11,5,9,7"
        Background="#5510141B"
        BorderBrush="#4B6478"
        BorderThickness="1"
        CornerRadius="14">
        <Border.Effect>
            <DropShadowEffect BlurRadius="18" ShadowDepth="4" Opacity="0.5" />
        </Border.Effect>
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="18" />
                <RowDefinition Height="*" />
                <RowDefinition Height="18" />
            </Grid.RowDefinitions>

            <StackPanel Grid.Row="0" Orientation="Horizontal" HorizontalAlignment="Right">
                <Button
                    x:Name="PinButton"
                    Width="54"
                    Height="18"
                    Margin="0,0,7,0"
                    Padding="4,0"
                    Background="#55263747"
                    BorderThickness="0"
                    Foreground="#73D7FF"
                    FontSize="10"
                    Cursor="Hand"
                    Content="PINNED"
                    ToolTip="Toggle always on top" />
                <Button
                    x:Name="CloseButton"
                    Width="22"
                    Height="18"
                    Padding="0"
                    Background="#55263747"
                    BorderThickness="0"
                    Foreground="#DCEAF3"
                    FontSize="12"
                    Cursor="Hand"
                    Content="X"
                    ToolTip="Close" />
            </StackPanel>

            <TextBlock
                x:Name="TimeText"
                Grid.Row="1"
                HorizontalAlignment="Center"
                VerticalAlignment="Center"
                Foreground="#F4FAFF"
                FontFamily="Consolas"
                FontSize="32"
                FontWeight="SemiBold"
                Text="00:00:00.00" />

            <TextBlock
                x:Name="DateText"
                Grid.Row="2"
                HorizontalAlignment="Center"
                VerticalAlignment="Center"
                Foreground="#9BB4C6"
                FontFamily="Microsoft JhengHei UI"
                FontSize="10"
                Text="0000/00/00" />
        </Grid>
    </Border>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)
$timeText = $window.FindName('TimeText')
$dateText = $window.FindName('DateText')
$pinButton = $window.FindName('PinButton')
$closeButton = $window.FindName('CloseButton')
$clockBorder = $window.FindName('ClockBorder')

$culture = [Globalization.CultureInfo]::GetCultureInfo('en-US')
$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(16)

$updateClock = {
    $now = Get-Date
    $timeText.Text = $now.ToString('HH:mm:ss.ff', $culture)
    $dateText.Text = $now.ToString('yyyy/MM/dd dddd', $culture)
}

$timer.Add_Tick($updateClock)
$closeButton.Add_Click({ $window.Close() })
$pinButton.Add_Click({
    $window.Topmost = -not $window.Topmost
    if ($window.Topmost) {
        $pinButton.Content = 'PINNED'
        $pinButton.Foreground = '#73D7FF'
    }
    else {
        $pinButton.Content = 'NORMAL'
        $pinButton.Foreground = '#9BB4C6'
    }
})

$clockBorder.Add_MouseLeftButtonDown({
    param($sender, $eventArgs)
    if ($eventArgs.ClickCount -eq 2) {
        $pinButton.RaiseEvent(
            (New-Object Windows.RoutedEventArgs([Windows.Controls.Button]::ClickEvent))
        )
        return
    }
    $window.DragMove()
})

$window.Add_SourceInitialized({
    $workArea = [System.Windows.SystemParameters]::WorkArea
    $window.Left = $workArea.Right - $window.Width - 12
    $window.Top = $workArea.Top + 12
})

$window.Add_Loaded({
    & $updateClock
    $timer.Start()
})

$window.Add_Closed({ $timer.Stop() })

if ($SmokeTest) {
    & $updateClock
    if ($timeText.Text -notmatch '^\d{2}:\d{2}:\d{2}\.\d{2}$') {
        throw 'Clock display format validation failed.'
    }
    Write-Output 'Clock UI loaded and time format validated.'
    exit 0
}

[void]$window.ShowDialog()
