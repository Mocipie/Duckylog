Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Inject C# to block mouse input
Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class MouseBlocker
{
    private const int WH_MOUSE_LL = 14;
    private static IntPtr hookID = IntPtr.Zero;
    private static LowLevelMouseProc proc = HookCallback;

    private delegate IntPtr LowLevelMouseProc(int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelMouseProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll")]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    public static void Start()
    {
        IntPtr hModule = GetModuleHandle(Process.GetCurrentProcess().MainModule.ModuleName);
        hookID = SetWindowsHookEx(WH_MOUSE_LL, proc, hModule, 0);
    }

    public static void Stop()
    {
        UnhookWindowsHookEx(hookID);
    }

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        return (IntPtr)1; // block all mouse input
    }
}
"@ -ReferencedAssemblies "System.Windows.Forms"

# Start mouse blocking
[MouseBlocker]::Start()

# Create an invisible form to trap the mouse
$form = New-Object Windows.Forms.Form
$form.WindowState = 'Normal'  # Not maximized
$form.FormBorderStyle = 'None'
$form.BackColor = 'Black'
$form.TopMost = $true
$form.KeyPreview = $true
$form.ShowInTaskbar = $false

# Hide the form (no visible UI)
$form.Visible = $false

# ESC to exit and clean up
$form.Add_KeyDown({
    if ($_.KeyCode -eq 'Escape') {
        [System.Windows.Forms.Cursor]::Show()
        [MouseBlocker]::Stop()
        $form.Close()
    }
})

# Trap and block mouse events within form too
$form.Add_MouseClick({})
$form.Add_MouseDown({})
$form.Add_MouseMove({})
$form.Add_MouseUp({})

# Start form to block mouse while keeping it invisible
[void]$form.ShowDialog()

