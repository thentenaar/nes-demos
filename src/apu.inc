;
; NES APU routines
;
; Copyright (c) 2016, Tim Hentenaar
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are
; met:
;
; 1. Redistributions of source code must retain the above copyright
;    notice, this list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright
;    notice, this list of conditions and the following disclaimer in the
;    documentation and/or other materials provided with the distribution.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
; PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
; OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;

; APU Registers: Pulse 1
.define APU_P1_VOL   $4000
.define APU_P1_SWEEP $4001
.define APU_P1_LO    $4002
.define APU_P1_HI    $4003

; APU Registers: Pulse 2
.define APU_P2_VOL   $4004
.define APU_P2_SWEEP $4005
.define APU_P2_LO    $4006
.define APU_P2_HI    $4007

; APU Registers: Triangle
.define APU_TR_CTR   $4008
.define APU_TR_LO    $400a
.define APU_TR_HI    $400b

; APU Registers: Noise
.define APU_N_VOL    $400c
.define APU_N_PERIOD $400e
.define APU_N_LENGTH $400f

; APU Registers: DMC
.define APU_DMC_CTRL $4010
.define APU_DMC_CTR  $4011
.define APU_DMC_ADDR $4012
.define APU_DMC_LEN  $4013

; APU Status / Frame Counter
.define APUSTAT $4015
.define APUFCTR $4017

; vi:set ft=ca65:
