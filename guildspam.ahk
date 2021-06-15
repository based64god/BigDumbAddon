#MaxThreadsPerHotkey 2
; #IfWinActive World of Warcraft	;; enabled only in WoW
Toggle := 0
RecruitmentMessage := "/say testing123"
RecruitmentDelay := 15000 ;; in ms. 15000 = 15 seconds
SpamChannels := ["/1", "/4"]

#1::
Toggle := !Toggle
While Toggle {
    if A_TimeIdlePhysical > 15000 ;; 15 seconds
        Send, {Blind}%RecruitmentMessage%{Enter}
        Sleep RecruitmentDelay
}
return


; #IfWinActive	;; disable WoW context sensitivity
^PgDn::Suspend	;; Ctrl + PageDown to suspend script (if you want to chat)
^PgUp::Reload	;; Ctrl + PageUP to reload script
^\::ExitApp	;; Ctrl + \ to terminate script