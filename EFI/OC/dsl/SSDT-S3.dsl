/**
 * # Comprehensive Sleep-patches for modern thinkpads.
 *
 * ## Abstract
 *
 * This SSDT tries to be a comprehensive solution for sleep/wake-problems on most modern thinkpads.
 * It was developed on an X1C6 with a T480 in mind.
 *
 * For X1C6 its perfectly possible to set SleepType=Windows in BIOS. That's the recommended setting 
 * as it enables "modern standby" in Windows for dual-boot-systems
 *
 * ## Background:
 *
 * Sleep on hackintoshes is a complicated topic. More complicated as mostly percieved. The problem is
 * that many functions of power management, sleep & wake are handled by the Macbook's embedded controller (EC)
 * / SMC and therefor many functions and devices are simply missing on Hackintoshes (f.e. the topcase-device). 
 * What we do have are our own, vendor-specific ECs and a myriade of different names for different sleep-methods.
 *
 * On top of this, most parts of the config have to be configured properly to accomplish working, non (or at least less) 
 * power-loosing sleep-states. Many of the (partly) solutions out there don't try to replicate the sleep-behaviour 
 * of a genuine macbook, but try to hide shortcomings and bugs with "ons-size-fits-all"-patches.
 * 
 * With this reasoning in mind, this SSDT tries to match the sleep-behaviour of a macbookpro14,1 as closely as possible.
 *
 * # Notice:
 *
 * Please remove every GPRW-, Name6x-, PTSWAK-, FixShutdown-, WakeScren-Patches or similar prior using.
 * If you adapt this patches to other models, check the occurence of the used variables and methods on your own DSDT beforehand.
 *
 *
 * # The needed patches for this SSDt on a X1C6:
 *
			<dict>
				<key>Comment</key>
				<string>S3: SLTP TO XLTP</string>
				<key>Count</key>
				<integer>0</integer>
				<key>Enabled</key>
				<true/>
				<key>Find</key>
				<data>U0xUUA==</data>
				<key>Limit</key>
				<integer>0</integer>
				<key>Mask</key>
				<data></data>
				<key>OemTableId</key>
				<data></data>
				<key>Replace</key>
				<data>WExUUA==</data>
				<key>ReplaceMask</key>
				<data></data>
				<key>Skip</key>
				<integer>0</integer>
				<key>TableLength</key>
				<integer>0</integer>
				<key>TableSignature</key>
				<data>RFNEVA==</data>
			</dict>
			<dict>
				<key>Comment</key>
				<string>S3: GRPW(2,N) to ZRPW</string>
				<key>Count</key>
				<integer>0</integer>
				<key>Enabled</key>
				<true/>
				<key>Find</key>
				<data>BkdQUlcCcA==</data>
				<key>Limit</key>
				<integer>0</integer>
				<key>Mask</key>
				<data></data>
				<key>OemTableId</key>
				<data></data>
				<key>Replace</key>
				<data>BlpQUlcCcA==</data>
				<key>ReplaceMask</key>
				<data></data>
				<key>Skip</key>
				<integer>0</integer>
				<key>TableLength</key>
				<integer>0</integer>
				<key>TableSignature</key>
				<data>RFNEVA==</data>
			</dict>
			<dict>
				<key>Comment</key>
				<string>S3: _WAK(1,S) to ZWAK</string>
				<key>Count</key>
				<integer>0</integer>
				<key>Enabled</key>
				<true/>
				<key>Find</key>
				<data>X1dBSwk=</data>
				<key>Limit</key>
				<integer>0</integer>
				<key>Mask</key>
				<data></data>
				<key>OemTableId</key>
				<data></data>
				<key>Replace</key>
				<data>WldBSwk=</data>
				<key>ReplaceMask</key>
				<data></data>
				<key>Skip</key>
				<integer>0</integer>
				<key>TableLength</key>
				<integer>0</integer>
				<key>TableSignature</key>
				<data>RFNEVA==</data>
			</dict>
 *
 */
DefinitionBlock ("", "SSDT", 1, "X1C6", "_S3", 0x00002000)
{
    // Common utils from SSDT-UTILS.dsl
    External (DTGP, MethodObj) // 5 Arguments
    External (OSDW, MethodObj) // 0 Arguments


    // S0/S3-config from BIOS
    External (S0ID, FieldUnitObj) // S0 enabled
    External (STY0, FieldUnitObj) // S3 Enabled?   

    // Package to signal to OS S3-capability. We'll add it if missing.
    External (SS3, FieldUnitObj) // S3 Enabled?    

    If (OSDW ())
    {
        Debug = "Enabling comprehensive S3-patching..."

        // Enable S3
        //   0x00 enables S3
        //   0x02 disables S3
        STY0 = Zero

        // Disable S0 for now
        S0ID = Zero

        // This adds S3 for OSX, even when sleep=windows in bios.
        If (STY0 == Zero && !CondRefOf (\_S3))
        {
            Name (\_S3, Package (0x04)  // _S3_: S3 System State
            {
                0x05, 
                0x05, 
                0x00, 
                0x00
            })

            SS3 = One
        }
    }


    Scope (_GPE)
    {
        // This tells xnu to evaluate _GPE.Lxx methods on resume
        Method (LXEN, 0, NotSerialized)
        {
            Debug = "LXEN()"

            Return (One)
        }
    }


    External (_SB.LID, DeviceObj) // 0 Arguments

    External (ZPRW, MethodObj)
    External (ZWAK, MethodObj) // 1 Arguments
    External (_SB.PCI0.LPCB.EC.AC._PSR, MethodObj) // 0 Arguments
    External (_SB.PCI0.LPCB.EC._Q2A, MethodObj) // 0 Arguments
    External (_SB.LID._LID, MethodObj) // 0 Arguments
    External (_SB.PCI0.LPCB.EC.HPLD, FieldUnitObj)
    External (_SB.PCI0.GFX0.CLID, FieldUnitObj)
    External (LIDS, FieldUnitObj)
    External (PWRS, FieldUnitObj)

    Scope (\)
    {
        // SLTP already taken on X1C6, therefor renamed via patch.
        Name (SLTP, Zero)  

        // Save sleep-state in SLTP on transition. Like a genuine Mac.
        Method (_TTS, 1, NotSerialized)  // _TTS: Transition To State
        {
            Debug = "_TTS() called with Arg0:"
            Debug = Arg0

            SLTP = Arg0
        }

        // Patch _PRW-returns to match the original as closely as possible
        // and remove instant wakeups and similar sleep-probs
        Method (GPRW, 2, NotSerialized)
        {
            If (OSDW ())
            {
                Local0 = Package (0x02)
                {
                    Zero, 
                    Zero
                }

                Local0[Zero] = Arg0

                If (Arg1 > 0x04)
                {
                    Local0[One] = 0x03
                }

                Return (Local0)
            }
            Else 
            {
                Return (ZPRW (Arg0, Arg1))
            }
        }

        // Patch _WAK to fire missing LID-Open event and update AC-state
        Method (_WAK, 1, Serialized)
        {
            Debug = "_WAK start: Arg0"
            Debug = Arg0

            Local0 = ZWAK(Arg0)

            If (OSDW ())
            {
                // Save old lid-state
                Local1 = LIDS

                // Update lid-state
                LIDS = \_SB.PCI0.LPCB.EC.HPLD
                \_SB.PCI0.GFX0.CLID = LIDS

                // Fire missing lid-open event if lid was closed before. 
                // Also notifies LID-device and sets LEDs to the right state on wake.
                If (Local1 == Zero)
                {
                    // Lid-open Event
                    \_SB.PCI0.LPCB.EC._Q2A ()
                }

                // Update ac-state
                \PWRS = \_SB.PCI0.LPCB.EC.AC._PSR ()
            }

            Debug = "_WAK end"

            Return (Local0)
        }
    }

    Scope (_SB)
    {
        // Sync S0-state between BIOS and OS
        Method (LPS0, 0, NotSerialized)
        {
            Debug = "LPS0 - S0ID: "
            Debug = S0ID

            // If S0ID is enabled, enable deep-sleep in OSX. Can be set above.
            Return (S0ID)
        }

        // Adds ACPI power-button-device
        // https://github.com/daliansky/OC-little/blob/master/06-%E6%B7%BB%E5%8A%A0%E7%BC%BA%E5%A4%B1%E7%9A%84%E9%83%A8%E4%BB%B6/SSDT-PWRB.dsl
        Device (PWRB)
        {
            Name (_HID, EisaId ("PNP0C0C") /* Power Button Device */)  // _HID: Hardware ID

            Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
            {
                Return (Zero)
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (OSDW ())
                {
                    Return (0x0B)
                }

                Return (Zero)
            }
        }
    }


    External (_SB.PCI0.LPCB.EC.AC, DeviceObj)
    External (LWCP, FieldUnitObj)

    // Patching AC-Device so that AppleACPIACAdapter-driver loads.
    // Device named ADP1 on Mac
    // See https://github.com/khronokernel/DarwinDumped/blob/b6d91cf4a5bdf1d4860add87cf6464839b92d5bb/MacBookPro/MacBookPro14%2C1/ACPI%20Tables/DSL/DSDT.dsl#L7965
    Scope (\_SB.PCI0.LPCB.EC.AC)
    {
        Method (_PRW, 0, NotSerialized)  // _PRW: Power Resources for Wake
        {
            // Lid-wake control power?
            Debug = "LWCP = "
            Debug = LWCP

            If (\LWCP)
            {
                Return (Package (0x02)
                {
                    0x17, 
                    0x04
                })
            }
            Else
            {
                Return (Package (0x02)
                {
                    0x17, 
                    0x03
                })
            }
        }
    }
}