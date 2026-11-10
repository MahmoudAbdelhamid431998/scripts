param(
    [Parameter(Position=0)]
    [string]$Command
)
# ضع المسار المطلق لمجلد أدواتك المركزي هنا
$ToolDir = "D:\FlutterTools"
dart "$ToolDir\flutter.dart" $Command