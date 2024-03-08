<#
.SYNOPSIS 
List Windows Services
.DESCRIPTION
Just a Windows Service list with quick filter to find status of a service
#>



#References
#https://blogs.technet.microsoft.com/platformspfe/2014/01/20/integrating-xaml-into-powershell/
#https://smsagent.blog/2017/08/24/a-customisable-wpf-messagebox-for-powershell/
#https://stackoverflow.com/questions/38663029/altering-datagrid-with-textbox-powershell

# XAML Code - Imported from Visual Studio Community 2017 WPF Application
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = @'
<Window Name="Form"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        Title="Services" Height="488.773" Width="797.65" ShowInTaskbar="False">
    <Grid Margin="0,0,-8,-21">
        <DataGrid Name="DataGrid1" HorizontalAlignment="Left" Height="368" VerticalAlignment="Top" Width="772" Margin="10,41,0,0"/>
        <Label Content="Filter" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top"/>
        <TextBox Name="FilterTextBox" HorizontalAlignment="Left" Height="26" Margin="78,10,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="172"/>
        <Button Name="CloseButton" Content="Close" HorizontalAlignment="Left" Margin="703,414,0,0" VerticalAlignment="Top" Background="Transparent" BorderBrush="Transparent" FontWeight="Bold" FontFamily="Segoe UI Semibold" Width="75" Height="25" FontSize="16"/>
    </Grid>
</Window>
'@

#Read XAML
$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Some possible causes for this problem include: .NET Framework is missing PowerShell must be launched with PowerShell -sta, invalid XAML code was encountered."; exit}

# Store Form Objects In PowerShell
$xaml.SelectNodes("//*[@Name]") | ForEach-Object{
    Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)
    Write-host $_.Name
}

$Fields = @(
    'Status'
    'DisplayName'
    'ServiceName'
)

$Services = Get-Service | Select-object $Fields

# Add Services to a datatable
$Datatable = New-Object System.Data.DataTable
[void]$Datatable.Columns.AddRange($Fields)
foreach ($Service in $Services)
{
    $Array = @()
    Foreach ($Field in $Fields)
    {
        $array += $Service.$Field
    }
    [void]$Datatable.Rows.Add($array)
}
#$filter = "DisplayName LIKE 'B%'"
#$Datatable.DefaultView.RowFilter = $filter

# Create a datagrid object and populate with datatable
$DataGrid1.ItemsSource = $Datatable.DefaultView
$DataGrid1.CanUserAddRows = $False
$DataGrid1.IsReadOnly = $True
$DataGrid1.GridLinesVisibility = "None"

$CloseButton.Add_Click({$form.Close()})

$FilterTextBox.Add_TextChanged({
    $InputText = $FilterTextBox.Text
    $filter = "DisplayName LIKE '$InputText%'"
    $Datatable.DefaultView.RowFilter = $filter
    $DataGrid1.ItemsSource = $Datatable.DefaultView
})

# Shows the form
$Form.ShowDialog() | out-null