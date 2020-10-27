/**
 * On many modern hackintoshed thinkpads there are ofthen accesses to the 16-bit EC-field `HWAC`, which are mostly 
 * not handled by battery-patches (f.e. those currated by @daliansky). Those accesses are (mostly) located in the _OWAK() 
 * and/or _L17-ACPI-methods of the original DSDT.
 *
 * The ACPI-method OWAK() gets called by _WAK() on wake and crashes there on access of the HWAC-field, leaving the 
 * machine in an undefined/unknown hw-state as the regular ACPI-wakeup-method, which re-setups the hardware after S3-sleep, 
 * can't run to its end.
 *
 * Especially this bug is often not clearly visible as the kernel-ringbuffer (msgbuf) is, by default, only 4kb in size and flooded on wake 
 * with many messages. This can be mitigated (up to 16kb) via `msgbuf`-boot-arg or patched by `DebugEnhancer.kext` by @acidanthera.
 * You can check the size of your msgbuf with `sysctl -a kern.msgbuf`.
 *
 * This SSDT is a simple solution for that problem and should be stable accross different Thinkpad models which suffer from this problem
 * as it fixes all accesses to the EC.HWAC-field at once.
 * 
 * It repleaces all reads to HWAC with a call to XWAC(), returning a newly stitched 16-bit-field out of the
 * two overlayed 8-bit-fields `WAC0` & `WAC1`.
 * 
 *
 * Background:
 * `Later releases of AppleACPIPlatform are unable to correctly access fields within the EC (embedded controller). 
 * [...] DSDT must be changed to comply with the limitations of Apple's AppleACPIPlatform.
 * 
 * In particular, any fields in the EC larger than 8-bit, must be changed to be accessed 8-bits at one time. 
 * This includes 16, 32, 64, and larger fields.`
 * - @Rehabman, https://www.tonymacx86.com/threads/guide-how-to-patch-dsdt-for-working-battery-status.116102/
 */

// Patch for OpenCore 0.62
// <dict>
// 	<key>Comment</key>
// 	<string>FIX: Change HWAC to XWAC EC reads</string>
// 	<key>Count</key>
// 	<integer>0</integer>
// 	<key>Enabled</key>
// 	<true/>
// 	<key>Find</key>
// 	<data>RUNfX0hXQUM=</data>
// 	<key>Limit</key>
// 	<integer>0</integer>
// 	<key>Mask</key>
// 	<data></data>
// 	<key>OemTableId</key>
// 	<data></data>
// 	<key>Replace</key>
// 	<data>RUNfX1hXQUM=</data>
// 	<key>ReplaceMask</key>
// 	<data></data>
// 	<key>Skip</key>
// 	<integer>0</integer>
// 	<key>TableLength</key>
// 	<integer>0</integer>
// 	<key>TableSignature</key>
// 	<data>RFNEVA==</data>
// </dict>

DefinitionBlock ("", "SSDT", 2, "X1C6", "_HWAC", 0x00001000)
{
    External (_SB.PCI0.LPCB.EC, DeviceObj)
    External (_SB.PCI0.LPCB.EC.HWAC, FieldUnitObj)

    // External method from SSDT-UTILS
    External (OSDW, MethodObj) // 0 Arguments

    // External method from SSDT-EC
    External (B1B2, MethodObj) // 2 Arguments

    
    Scope (\_SB.PCI0.LPCB.EC)
    {
        // /*
        //  * Read status from two EC fields
        //  * Comment in if you dont have the method externally defined
        //  */
        // Method (B1B2, 2, NotSerialized)
        // {
        //     Local0 = (Arg1 << 0x08)
        //     Local0 |= Arg0
        //     Return (Local0)
        // }

        //
        // EC region overlay.
        //
        OperationRegion (ERAM, EmbeddedControl, 0x00, 0x0100)
        Field (ERAM, ByteAcc, NoLock, Preserve)
        {
            Offset(0x36),
            WAC0, 8, WAC1, 8,
        }

        // Method used for replacing reads to HWAC in _L17() & OWAK().
        Method (XWAC, 0, NotSerialized)
        {
            If (OSDW ())
            {
                Return (B1B2 (WAC0, WAC1))
            }

            Return (HWAC)
        }
    }
}
// EOF
