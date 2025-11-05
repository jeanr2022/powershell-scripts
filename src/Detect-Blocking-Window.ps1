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
    # Foreground window (top-level window)
    $fgHwnd = [User32]::GetForegroundWindow()
    if ($fgHwnd -eq [IntPtr]::Zero) { return $null }

    # Thread of foreground window
    $null = [User32]::GetWindowThreadProcessId($fgHwnd, [ref]$fgPid)

    # GUI info for the thread
    $guiInfo = New-Object User32+GUITHREADINFO
    $guiInfo.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($guiInfo)
    [User32]::GetGUIThreadInfo($fgPid, [ref]$guiInfo) | Out-Null

    $focusHwnd = $guiInfo.hwndFocus
    if ($focusHwnd -eq [IntPtr]::Zero) { $focusHwnd = $fgHwnd }

    # PID of window that currently has keyboard focus
    $null = [User32]::GetWindowThreadProcessId($focusHwnd, [ref]$focusPid)

    return $focusPid
}

$blockingPid = Get-BlockingWindowPID
if ($blockingPid) {
    $proc = Get-Process -Id $blockingPid -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "Process potentially blocking WebView2: $($proc.ProcessName) (PID: $blockingPid)"
    } else {
        Write-Host "PID owning focused window: $blockingPid (process not found)"
    }
} else {
    Write-Host "No window currently has keyboard focus."
}
