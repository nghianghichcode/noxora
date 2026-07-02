$path = "c:\Users\Admin\Desktop\platinum\programma\XAML\layout.xaml"
$lines = Get-Content $path
$keep = $lines[0..2181]

$rest = @"

            <!-- OTHER VIEW (Driver Optimization / Game Profile) -->
            <Grid Grid.Column="1" x:Name="VIEW_OTHER" Visibility="Hidden" Opacity="0" Background="Transparent">
                <Grid.RenderTransform><TranslateTransform Y="0"/></Grid.RenderTransform>
                <Grid Margin="50">
                    <TextBlock x:Name="TXT_OTHER_TITLE" Text="Page" Foreground="#FFF" FontSize="32" FontWeight="Bold" Margin="0,0,0,6"/>
                    <TextBlock Text="This feature has been converted to a standalone module in the modular architecture. Please use the dedicated navigation modules for this function." Foreground="#949BAA" FontSize="15" TextWrapping="Wrap" Margin="0,0,0,30"/>
                </Grid>
            </Grid>

            <!-- TOAST OVERLAY (Sleek Toast Notification) -->
            <Grid x:Name="TOAST_OVERLAY" Grid.ColumnSpan="2" Visibility="Hidden" Panel.ZIndex="9998" VerticalAlignment="Top" HorizontalAlignment="Right" Margin="0,25,25,0" Width="360" UseLayoutRounding="True" SnapsToDevicePixels="True">
                <Grid.RenderTransform>
                    <TranslateTransform X="150" Y="0"/>
                </Grid.RenderTransform>
                
                <!-- Outer Glow/Shadow effect border -->
                <Border Margin="-2" Background="#141820" BorderBrush="#1A00B4DB" BorderThickness="1" CornerRadius="12">
                    <Border.Effect>
                        <DropShadowEffect Color="#00B4DB" BlurRadius="12" Opacity="0.08" ShadowDepth="0"/>
                    </Border.Effect>
                </Border>
                
                <!-- Main Card Border -->
                <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource BorderMain}" BorderThickness="1" CornerRadius="10" Padding="16,14">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        
                        <!-- Icon Box -->
                        <Border x:Name="TOAST_ICON_BOX" Grid.Column="0" Width="34" Height="34" Background="#202633" BorderBrush="#2D3443" BorderThickness="1" CornerRadius="8" Margin="0,0,14,0" VerticalAlignment="Center">
                            <TextBlock x:Name="TOAST_ICON" Text="&#xE73E;" FontFamily="Segoe MDL2 Assets" Foreground="{StaticResource AccentBlue}" FontSize="15" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        
                        <!-- Content -->
                        <StackPanel Grid.Column="1" VerticalAlignment="Center">
                            <TextBlock x:Name="TOAST_TITLE" Text="Notification" Foreground="#FFFFFF" FontSize="14" FontWeight="SemiBold" TextOptions.TextFormattingMode="Display" TextOptions.TextRenderingMode="ClearType"/>
                            <TextBlock x:Name="TOAST_MESSAGE" Text="Action completed successfully." Foreground="#949BAA" FontSize="11" TextWrapping="Wrap" Margin="0,3,0,0" LineHeight="16" TextOptions.TextFormattingMode="Display" TextOptions.TextRenderingMode="ClearType"/>
                        </StackPanel>
                    </Grid>
                </Border>
            </Grid>

            <!-- MODAL OVERLAY -->
            <Grid x:Name="MODAL_OVERLAY" Grid.ColumnSpan="2" Visibility="Hidden" Panel.ZIndex="9999" Background="#B006080D" Opacity="0" UseLayoutRounding="True" SnapsToDevicePixels="True">
                <Grid x:Name="MODAL_CARD" Width="500" VerticalAlignment="Center" HorizontalAlignment="Center" RenderTransformOrigin="0.5,0.5" UseLayoutRounding="True" SnapsToDevicePixels="True">
                    <Grid.RenderTransform>
                        <TranslateTransform Y="12"/>
                    </Grid.RenderTransform>
                    <Border Margin="-2" Background="#141820" BorderBrush="#223241" BorderThickness="1" CornerRadius="12"/>
                    <Border Margin="-1" Background="#1200B4DB" BorderBrush="#2A4452" BorderThickness="1" CornerRadius="11">
                        <Border.Effect>
                            <DropShadowEffect Color="#00B4DB" BlurRadius="18" Opacity="0.12" ShadowDepth="0"/>
                        </Border.Effect>
                    </Border>
                    <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource BorderMain}" BorderThickness="1" CornerRadius="10" SnapsToDevicePixels="True">
                        <Border.Effect>
                            <DropShadowEffect Color="#000000" BlurRadius="34" Opacity="0.48" ShadowDepth="12"/>
                        </Border.Effect>
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>
                            <Border Grid.Row="0" Background="#1A1D26" CornerRadius="10,10,0,0" BorderBrush="#252A36" BorderThickness="0,0,0,1" Padding="28,23,28,19">
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="Auto"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Border x:Name="MODAL_ICON_BOX" Grid.Column="0" Width="40" Height="40" Background="#202633" BorderBrush="#2D3443" BorderThickness="1" CornerRadius="8" Margin="0,0,15,0" SnapsToDevicePixels="True">
                                        <TextBlock x:Name="MODAL_ICON" Text="&#xE73E;" FontFamily="Segoe MDL2 Assets" Foreground="{StaticResource AccentBlue}" FontSize="17" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    </Border>
                                    <StackPanel Grid.Column="1" VerticalAlignment="Center">
                                        <TextBlock x:Name="MODAL_TITLE" Text="Notice" Foreground="#FFFFFF" FontSize="19" FontWeight="SemiBold" TextOptions.TextFormattingMode="Display" TextOptions.TextRenderingMode="ClearType"/>
                                        <TextBlock x:Name="MODAL_SUBTITLE" Text="Platinum+ Notification" Foreground="#8C96A5" FontSize="11" FontWeight="Medium" Margin="0,3,0,0" TextOptions.TextFormattingMode="Display" TextOptions.TextRenderingMode="ClearType"/>
                                    </StackPanel>
                                </Grid>
                            </Border>
                            <TextBlock x:Name="MODAL_MESSAGE" Grid.Row="1" Text="Message..." Foreground="#E1E6EF" FontSize="14" FontWeight="Medium" TextWrapping="Wrap" Margin="32,26,32,34" LineHeight="23" TextOptions.TextFormattingMode="Display" TextOptions.TextRenderingMode="ClearType"/>
                            <Border Grid.Row="2" Background="#151821" CornerRadius="0,0,10,10" BorderBrush="#252A36" BorderThickness="0,1,0,0" Padding="26,18">
                                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                                    <Button x:Name="BTN_MODAL_OK" Content="Okay" Height="38" Width="116" Foreground="#E8F8FC" FontWeight="SemiBold" FontSize="13" BorderThickness="0" SnapsToDevicePixels="True">
                                        <Button.Style>
                                            <Style TargetType="Button">
                                                <Setter Property="Background" Value="#232733"/>
                                                <Setter Property="Template">
                                                    <Setter.Value>
                                                        <ControlTemplate TargetType="Button">
                                                            <Border x:Name="bg" Background="{TemplateBinding Background}" BorderBrush="#2C3140" BorderThickness="1" CornerRadius="7" SnapsToDevicePixels="True">
                                                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                                            </Border>
                                                            <ControlTemplate.Triggers>
                                                                <Trigger Property="IsMouseOver" Value="True">
                                                                    <Setter TargetName="bg" Property="Background" Value="#2A2F3D"/>
                                                                    <Setter TargetName="bg" Property="BorderBrush" Value="#354153"/>
                                                                </Trigger>
                                                                <Trigger Property="IsPressed" Value="True">
                                                                    <Setter TargetName="bg" Property="Background" Value="#00B4DB"/>
                                                                    <Setter Property="Foreground" Value="#111216"/>
                                                                </Trigger>
                                                            </ControlTemplate.Triggers>
                                                        </ControlTemplate>
                                                    </Setter.Value>
                                                </Setter>
                                            </Style>
                                        </Button.Style>
                                    </Button>
                                </StackPanel>
                            </Border>
                        </Grid>
                    </Border>
                </Grid>
            </Grid>

        </Grid>
    </Grid>
</Border>
</Window>
"@

Set-Content -Path $path -Value $keep
Add-Content -Path $path -Value $rest
Write-Host "Success"
