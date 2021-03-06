function Get-KeyState([uint16]$keyCode)
{
  $signature = '[DllImport("user32.dll")]public static extern short GetKeyState(int nVirtKey);'
  $type = Add-Type -MemberDefinition $signature -Name User32 -Namespace GetKeyState -PassThru
  return [bool]($type::GetKeyState($keyCode) -band 0x80)
}

Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;
    public class Win32 {
        [DllImport("user32.dll")]
        public static extern void SendMessage(IntPtr hWnd, IntPtr msg, IntPtr wPar, IntPtr lPar);
    
        [DllImport("user32.dll", EntryPoint = "SendMessageW", CharSet = CharSet.Unicode, SetLastError = false)]
        public static extern int SendMessageByString(IntPtr hWnd, uint Msg, int wParam, StringBuilder lParam);
        
        [DllImport("user32.dll")]
		public static extern IntPtr GetForegroundWindow();

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr FindWindowEx(IntPtr hWndParent, IntPtr hWndChild, string lpClassName, string lpWindowName);
        
        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    }
"@

$WM_SETTEXT = 0x000c
$WM_KEYDOWN = 0x0100
$VK_END = 0x23
$skype = new-object -ComObject Skype4COM.Skype
$skype_user_name = $skype.CurrentUser.FullName
$must_continue = $true
while($must_continue){`
    $is_ctrl = Get-KeyState(0x11)
    
    $is_tilda = Get-KeyState(0xC0)
    if($is_ctrl -and $is_tilda){
        echo "start update top"
        $curr_chat = $skype.ActiveChats | select-object -first 1
        $my_msgs = $curr_chat.Messages| where {$_.FromDisplayName -eq $skype_user_name}
        $top = $my_msgs | group body | select name, count | where {!$_.name.StartsWith("sent file")} | sort -desc count | select-object -first 10

        $window_text = if($curr_chat.FriendlyName -ne ""){
            $curr_chat.FriendlyName
        }else{
            $curr_chat.Topic
        }
        echo "chat: $window_text"
        echo "finish update top"
    }
    
    for($i=0; $i -lt 10; $i++){
        $is_number = Get-KeyState(0x31+$i)
        if($is_ctrl -and $is_number){
            $hwnd_top_level = [Win32]::GetForegroundWindow()
            $hwnd_skype = $hwnd_top_level
            $hwnd_conv = [Win32]::FindWindowEx($hwnd_skype, 0, "TConversationForm", $window_text);
            $hwnd = [Win32]::FindWindowEx($hwnd_conv, 0, "TChatEntryControl", "");
            $hwnd = [Win32]::FindWindowEx($hwnd, 0, "TChatRichEdit", "");
            
            [void] [Win32]::SendMessageByString($hwnd, $WM_SETTEXT, 0, $top[$i].name)
            [void] [Win32]::SendMessage($hwnd, $WM_KEYDOWN, $VK_END,0)
        }
    }
    
    Start-Sleep -m 250
}

#$chat.SendMessage('пак')