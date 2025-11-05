<#
.SYNOPSIS
    Dumps hostapp.exe, all WebView2 renderer processes, and the process currently blocking input.

.DESCRIPTION
    - Dumps the host WPF/WinForms process (-ma).
    - Dumps all WebView2 renderer processes (-ma).
    - Detects the window that currently has keyboard focus (potentially blocking WebView2) and dumps it.
    - Saves all dumps to C:\dumps.
#>

# -----------------------------
# Config
# -----------------------------
$DumpFolder = "C:\dumps"
$HostApp = "hostapp.exe"
$ProcDumpPath = "C:\Tools\procdump\procdump.exe"  # Update path if needed

if (!(Test-Path $DumpFolder)) { New-Item -ItemType Directory -Path $DumpFolder }

# -----------------------------
# Function to get blocking window PID
# -----------------------------
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class User32 {
    [StructLayout(LayoutKind.Sequential)]
    public struct GUITHREADINFO {
        public int cbSize;
        public int flags;
        public IntPtr hwndActive;
        public IntPtr hwndFocus;
        public IntPtr hwndCapture;
        public IntPtr hwndMenuOwner;
        public IntPtr hwndMoveSize;
        public IntPtr hwndCaret;
        public RECT rcCaret;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int left;
        public int top;
        public int right;
        public int bottom;
    }

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("user32.dll")]
    public static extern bool GetGUIThreadInfo(uint idThread, ref GUITHREADINFO lpgui);
}
"@

function Get-BlockingWindowPID {
    $fgHwnd = [User32]::GetForegroundWindow()
    if ($fgHwnd -eq [IntPtr]::Zero) { return $null }

    $null = [User32]::GetWindowThreadProcessId($fgHwnd, [ref]$fgPid)

    $guiInfo = New-Object User32+GUITHREADINFO
    $guiInfo.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($guiInfo)
    [User32]::GetGUIThreadInfo($fgPid, [ref]$guiInfo) | Out-Null

    $focusHwnd = $guiInfo.hwndFocus
    if ($focusHwnd -eq [IntPtr]::Zero) { $focusHwnd = $fgHwnd }

    $null = [User32]::GetWindowThreadProcessId($focusHwnd, [ref]$focusPid)
    return $focusPid
}

# -----------------------------
# 1. Dump host process
# -----------------------------
$hostProc = Get-Process -Name ($HostApp -replace '.exe$','') -ErrorAction SilentlyContinue

if ($hostProc) {
    Write-Host "Dumping host process: $($hostProc.Id)"
    & $ProcDumpPath -ma $hostProc.Id "$DumpFolder\host_process.dmp"
} else {
    Write-Warning "Host process $HostApp not running."
}

# -----------------------------
# 2. Dump all WebView2 renderer processes
# -----------------------------
$wv2Procs = Get-Process -Name "msedgewebview2" -ErrorAction SilentlyContinue

if ($wv2Procs.Count -eq 0) {
    Write-Warning "No WebView2 renderer processes found."
} else {
    foreach ($proc in $wv2Procs) {
        Write-Host "Dumping WebView2 renderer process: $($proc.Id)"
        & $ProcDumpPath -ma $proc.Id "$DumpFolder\wv2_renderer_$($proc.Id).dmp"
    }
}

# -----------------------------
# 3. Dump process currently blocking input
# -----------------------------
$blockingPid = Get-BlockingWindowPID
if ($blockingPid -and ($blockingPid -ne $hostProc.Id)) {
    $blockingProc = Get-Process -Id $blockingPid -ErrorAction SilentlyContinue
    if ($blockingProc) {
        Write-Host "Dumping process potentially blocking WebView2: $($blockingProc.ProcessName) (PID: $blockingPid)"
        & $ProcDumpPath -ma $blockingProc.Id "$DumpFol
